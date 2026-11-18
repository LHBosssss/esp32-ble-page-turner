// ESP32-C3 "Kindle Click" clone: BLE HID (HOGP) page-turner remote, low power.
// Spec: https://kindlemodding.org/kindle-hacking/pageturner.html
// Behaviour follows Amazon's Kindle Click help page:
//   - 2 large front buttons = page forward / back
//   - 2 side buttons = brightness up / down;  hold BOTH ~1 s = Sleep (KEY_POWER)
//   - hold front-top button 2 s              = pairing mode (2 minutes)
//   - hold front-bottom + brightness-down 10 s = forget host, then pairing mode
//   - Battery level via BLE Battery Service (0x180F)
// Kindle matches the device by HID VID 0x0171 / PID 0x0443.
#include <Arduino.h>
#include <NimBLEDevice.h>
#include <NimBLEHIDDevice.h>
#include <esp_sleep.h>
#include <driver/gpio.h>

// ---- Pins (ESP32-C3 SuperMini). Buttons MUST be GPIO0..3 (RTC) for deep-sleep wake ----
static const uint8_t PIN_FWD = 0, PIN_BACK = 1, PIN_BRUP = 2, PIN_BRDN = 3;
static const uint8_t PIN_VBAT = 4;                           // ADC1, 1M/1M divider (x2)

#ifndef BLE_APPEARANCE
#define BLE_APPEARANCE 0x03C0   // 0x03C0 generic HID, 0x03C1 keyboard, 0x0180 generic remote control
#endif
static const uint16_t VID = 0x0171, PID = 0x0443;
static const char *DEVICE_NAME = "Kindle Click";

static const uint32_t IDLE_SLEEP_MS    = 30UL * 1000;
static const uint32_t PAIRING_MS       = 2UL * 60 * 1000;
static const uint32_t PAIR_HOLD_MS     = 2000;    // front-top held
static const uint32_t FORGET_HOLD_MS   = 10000;   // front-bottom + bright-down held
static const uint32_t SLEEP_CHORD_MS   = 1000;    // both brightness held
static const uint32_t CHORD_WINDOW_MS  = 120;     // wait to see if 2nd brightness button joins
static const uint32_t BATT_PERIOD_MS   = 5UL * 60 * 1000;

#define RID_KEYBOARD 1
#define RID_CONSUMER 2
#define CONS_POWER  0x0030   // -> KEY_POWER
#define CONS_BR_UP  0x006F   // -> KEY_BRIGHTNESSUP
#define CONS_BR_DN  0x0070   // -> KEY_BRIGHTNESSDOWN
#define KB_PAGEUP   0x4B
#define KB_PAGEDOWN 0x4E

static const uint8_t reportMap[] = {
  0x05, 0x01, 0x09, 0x06, 0xA1, 0x01, 0x85, RID_KEYBOARD,
  0x05, 0x07, 0x19, 0xE0, 0x29, 0xE7, 0x15, 0x00, 0x25, 0x01,
  0x75, 0x01, 0x95, 0x08, 0x81, 0x02,
  0x95, 0x01, 0x75, 0x08, 0x81, 0x01,
  0x95, 0x06, 0x75, 0x08, 0x15, 0x00, 0x25, 0x65,
  0x05, 0x07, 0x19, 0x00, 0x29, 0x65, 0x81, 0x00,
  0xC0,
  0x05, 0x0C, 0x09, 0x01, 0xA1, 0x01, 0x85, RID_CONSUMER,
  0x15, 0x00, 0x26, 0xFF, 0x03, 0x19, 0x00, 0x2A, 0xFF, 0x03,
  0x75, 0x10, 0x95, 0x01, 0x81, 0x00,
  0xC0
};

static NimBLEServer *server;
static NimBLEHIDDevice *hid;
static NimBLECharacteristic *inKeyboard, *inConsumer;
static volatile bool connected = false, linkReady = false, justPaired = false;
static volatile uint32_t connectedAt = 0;
static uint32_t lastActivity = 0, lastBatt = 0;
static bool pairingMode = false;
static uint32_t pairingUntil = 0;


class ServerCb : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer *s) override { connected = true; linkReady = false; connectedAt = millis(); }
  void onAuthenticationComplete(ble_gap_conn_desc *) override { linkReady = true; if (pairingMode) justPaired = true; }
  void onDisconnect(NimBLEServer *s) override { connected = linkReady = false; NimBLEDevice::startAdvertising(); }
};

// ---------- Battery ----------
static uint8_t batteryPercent() {
  uint32_t mv = 0;
  for (int i = 0; i < 16; i++) mv += analogReadMilliVolts(PIN_VBAT);
  mv = (mv / 16) * 2;
  static const uint16_t v[] = {3300, 3500, 3600, 3700, 3750, 3800, 3900, 4000, 4100, 4200};
  static const uint8_t  p[] = {   0,    5,   10,   20,   35,   50,   65,   80,   92,  100};
  if (mv <= v[0]) return 0;
  for (int i = 1; i < 10; i++)
    if (mv <= v[i]) return p[i-1] + (p[i]-p[i-1]) * (int)(mv - v[i-1]) / (v[i]-v[i-1]);
  return 100;
}
static uint8_t updateBattery() {
  uint8_t pct = batteryPercent();
  hid->setBatteryLevel(pct);
  lastBatt = millis();
  return pct;
}

// ---------- Key sending ----------
static bool canSend() { return connected && (linkReady || millis() - connectedAt > 1500); }
static void sendKey(uint8_t usage) {
  uint8_t r[8] = {0, 0, usage, 0, 0, 0, 0, 0};
  inKeyboard->setValue(r, 8); inKeyboard->notify(); delay(15);
  memset(r, 0, 8); inKeyboard->setValue(r, 8); inKeyboard->notify();
}
static void sendConsumer(uint16_t usage) {
  uint8_t r[2] = {(uint8_t)(usage & 0xFF), (uint8_t)(usage >> 8)};
  inConsumer->setValue(r, 2); inConsumer->notify(); delay(15);
  r[0] = r[1] = 0; inConsumer->setValue(r, 2); inConsumer->notify();
}
struct Pending { bool valid; bool consumer; uint16_t usage; };
static Pending pend = {false, false, 0};
static void fire(bool consumer, uint16_t usage) {
  lastActivity = millis();
  if (!canSend()) { pend = {true, consumer, usage}; return; }   // keep wake-up press until linked
  consumer ? sendConsumer(usage) : sendKey((uint8_t)usage);
  pend.valid = false;
}

// ---------- Buttons ----------
enum { B_FWD, B_BACK, B_BRUP, B_BRDN, NB };
static const uint8_t btnPin[NB] = {PIN_FWD, PIN_BACK, PIN_BRUP, PIN_BRDN};
static bool down[NB], rawLast[NB];
static uint32_t rawAt[NB], downAt[NB], nextRep[NB];
static bool sentOnce[NB];
static bool chordActive = false, chordSent = false, forgetDone = false, pairHoldDone = false;
static uint32_t chordStart = 0;

static void startPairing() {
  pairingMode = true; pairingUntil = millis() + PAIRING_MS;
  lastActivity = millis();
  NimBLEDevice::startAdvertising();
}
static void forgetHost() {
  NimBLEDevice::deleteAllBonds();
  for (auto h : server->getPeerDevices()) server->disconnect(h);
  startPairing();
}

static void handleButtons(uint32_t now) {
  for (int i = 0; i < NB; i++) {
    bool lvl = (digitalRead(btnPin[i]) == LOW);
    if (lvl != rawLast[i]) { rawLast[i] = lvl; rawAt[i] = now; }
    if (now - rawAt[i] > 30 && lvl != down[i]) {          // 30 ms debounce
      down[i] = lvl;
      if (lvl) { downAt[i] = now; sentOnce[i] = false; lastActivity = now;
                 if (i == B_FWD) fire(false, KB_PAGEDOWN);
                 if (i == B_BACK) fire(false, KB_PAGEUP); }
      else {  // release: a quick tap of a brightness button that never reached the send window
        if ((i == B_BRUP || i == B_BRDN) && !sentOnce[i] && !chordActive && !down[B_FWD] && !down[B_BACK])
          fire(true, i == B_BRUP ? CONS_BR_UP : CONS_BR_DN);
        if (i == B_FWD) pairHoldDone = false;
      }
    }
    if (down[i]) lastActivity = now;
  }

  bool bothBright = down[B_BRUP] && down[B_BRDN];
  if (bothBright && !chordActive) { chordActive = true; chordSent = false; chordStart = now; }
  if (!bothBright && !down[B_BRUP] && !down[B_BRDN]) chordActive = false;
  if (chordActive && !chordSent && now - chordStart >= SLEEP_CHORD_MS) {   // hold both = Sleep
    fire(true, CONS_POWER); chordSent = true; sentOnce[B_BRUP] = sentOnce[B_BRDN] = true;
  }

  // Brightness: send after short window (to see if it becomes a chord), then repeat 500 ms / 333 ms
  for (int i = B_BRUP; i <= B_BRDN; i++) {
    if (!down[i] || chordActive || down[B_FWD] || down[B_BACK]) continue;
    uint16_t u = (i == B_BRUP) ? CONS_BR_UP : CONS_BR_DN;
    if (!sentOnce[i] && now - downAt[i] >= CHORD_WINDOW_MS) { fire(true, u); sentOnce[i] = true; nextRep[i] = now + 500; }
    else if (sentOnce[i] && now >= nextRep[i]) { fire(true, u); nextRep[i] = now + 333; }
  }

  // Hold front-top 2 s alone => pairing mode
  if (down[B_FWD] && !down[B_BACK] && !pairHoldDone && now - downAt[B_FWD] >= PAIR_HOLD_MS) {
    pairHoldDone = true; startPairing();
  }
  // Hold front-bottom + brightness-down 10 s => forget host
  if (down[B_BACK] && down[B_BRDN]) {
    uint32_t t = max(downAt[B_BACK], downAt[B_BRDN]);
    if (!forgetDone && now - t >= FORGET_HOLD_MS) { forgetDone = true; forgetHost(); }
  } else forgetDone = false;
}

// ---------- Pairing state ----------
static void updatePairing(uint32_t now) {
  if (justPaired) { justPaired = false; pairingMode = false; }
  if (pairingMode && now > pairingUntil) pairingMode = false;
}

// ---------- Deep sleep ----------
static void goToSleep() {
  gpio_deep_sleep_hold_en();
  uint64_t mask = 0;
  for (uint8_t p : btnPin) {
    gpio_pullup_en((gpio_num_t)p); gpio_pulldown_dis((gpio_num_t)p); gpio_hold_en((gpio_num_t)p);  // keep pull-up in deep sleep
    mask |= 1ULL << p;
  }
  while (true) {                                           // don't sleep with a button held
    bool any = false;
    for (uint8_t p : btnPin) any |= (digitalRead(p) == LOW);
    if (!any) break;
    delay(20);
  }
  esp_deep_sleep_enable_gpio_wakeup(mask, ESP_GPIO_WAKEUP_GPIO_LOW);
  esp_deep_sleep_start();
}

void setup() {
  Serial.begin(115200);
  gpio_deep_sleep_hold_dis();
  for (uint8_t p : btnPin) { gpio_hold_dis((gpio_num_t)p); pinMode(p, INPUT_PULLUP); }
  analogSetPinAttenuation(PIN_VBAT, ADC_11db);

  if (esp_sleep_get_wakeup_cause() == ESP_SLEEP_WAKEUP_GPIO) {   // remember which button woke us
    uint64_t st = esp_sleep_get_gpio_wakeup_status();
    if (st & (1ULL << PIN_FWD))  pend = {true, false, KB_PAGEDOWN};
    if (st & (1ULL << PIN_BACK)) pend = {true, false, KB_PAGEUP};
    if (st & (1ULL << PIN_BRUP)) pend = {true, true, CONS_BR_UP};
    if (st & (1ULL << PIN_BRDN)) pend = {true, true, CONS_BR_DN};
  }

  NimBLEDevice::init(DEVICE_NAME);
  NimBLEDevice::setPower(ESP_PWR_LVL_P3);
  NimBLEDevice::setSecurityAuth(true, false, true);
  NimBLEDevice::setSecurityIOCap(BLE_HS_IO_NO_INPUT_OUTPUT);
  server = NimBLEDevice::createServer();
  server->setCallbacks(new ServerCb());
  hid = new NimBLEHIDDevice(server);
  inKeyboard = hid->inputReport(RID_KEYBOARD);
  inConsumer = hid->inputReport(RID_CONSUMER);
  hid->manufacturer()->setValue("Amazon");
  hid->pnp(0x01, VID, PID, 0x0100);   // source 0x01 = Bluetooth SIG company ID (0x0171 is Amazon's SIG ID, not a USB-IF VID)
  hid->hidInfo(0x00, 0x01);
  hid->reportMap((uint8_t *)reportMap, sizeof(reportMap));
  hid->startServices();
  updateBattery();

  NimBLEAdvertising *adv = NimBLEDevice::getAdvertising();
  // Name + HID UUID go in the MAIN advertising packet (a passive scanner such as the Kindle's never sees scan-response data).
  NimBLEAdvertisementData advData, scanData;
  // Kindle libbluetooth (btif_dm_search_devices_evt) builds the VID/PID property (type 0xFE) that acsbtfd needs from
  // the manufacturer data (AD 0xFF): [0..1] company/VID 0x0171 little-endian, [2..3] PID 0x0443 BIG-endian.
  // (btif_in_is_amazon_ble_remote accepts VID 0x0171 + PID 0x0411..0x0443.)  Do NOT add UUID 0xFE03: it switches
  // libbluetooth to the "Gadget" branch, whose property type 0x103 acsbtfd ignores.
  advData.setFlags(BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP);
  advData.setName(DEVICE_NAME);
  advData.setManufacturerData(std::string("\x71\x01\x04\x43", 4));
  advData.setCompleteServices(NimBLEUUID((uint16_t)0x1812));
  scanData.setAppearance(BLE_APPEARANCE);
  adv->setAdvertisementData(advData);
  adv->setScanResponseData(scanData);
  adv->start();

  lastActivity = millis();
  if (NimBLEDevice::getNumBonds() == 0) startPairing();          // first boot: pair right away
  Serial.printf("BLE address: %s\n", NimBLEDevice::getAddress().toString().c_str());
}

void loop() {
  uint32_t now = millis();
  handleButtons(now);
  if (pend.valid && canSend()) fire(pend.consumer, pend.usage);   // deliver press captured at wake-up
  updatePairing(now);
  if (connected && now - lastBatt > BATT_PERIOD_MS) updateBattery();
#ifdef BENCH_AUTO    // self-test: every 5 s send PageDown, PageUp, Bright+, Bright- in turn (no buttons needed)
  static uint32_t lastAuto = 0; static uint8_t step = 0;
  if (connected && canSend() && now - lastAuto > 5000) {
    lastAuto = now;
    static const char *names[] = {"PageDown", "PageUp", "Bright+", "Bright-"};
    Serial.printf("auto: %s\n", names[step]);
    switch (step) {
      case 0: fire(false, KB_PAGEDOWN); break;
      case 1: fire(false, KB_PAGEUP);   break;
      case 2: fire(true,  CONS_BR_UP);  break;
      case 3: fire(true,  CONS_BR_DN);  break;
    }
    step = (step + 1) & 3;
  }
#endif
#ifndef BENCH_TEST   // bench build: never sleep, stay discoverable (no buttons wired yet)
  if (!pairingMode && now - lastActivity > IDLE_SLEEP_MS) goToSleep();
#else
  if (!pairingMode) startPairing();
#endif
  delay(5);
}
