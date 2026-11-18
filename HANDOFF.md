# HANDOFF: ESP32 Kindle Click clone (cập nhật 2026-11-18)

> Chỉ phục vụ nghiên cứu, học tập, dùng cá nhân phi thương mại. Không liên kết với Amazon, không chứa binary/mã của Amazon. Xem Disclaimer trong `README.md`.

## Mục tiêu & YÊU CẦU CỨNG
Clone Kindle Click bằng ESP32-C3 SuperMini (BLE HID), dùng **Kindle gốc (acsbtfd)**, không dùng kindle-hid-passthrough.
**Yêu cầu bắt buộc: thiết bị phải HIỆN trong Settings ▸ Wi-Fi & Bluetooth ▸ Bluetooth Devices với tên "Kindle Click" + biểu tượng viên thuốc, ghép từ menu, giống hệt Kindle Click gốc.** Đã đạt: thiết bị hiện trong menu và ghép được (xem mục ĐÃ GIẢI QUYẾT).

## Trạng thái
- Firmware (`src/main.cpp`, PlatformIO, NimBLE-Arduino) hoạt động: HID keyboard (ID1) + consumer (ID2), battery 0x180F, deep sleep, chord nút. VID 0x0171 / PID 0x0443, PnP source 0x01.
- Envs (`platformio.ini`): `esp32c3` (bản thật), `bench` (không ngủ, luôn pairing, dùng khi chưa hàn nút), `bench_auto` (tự gửi PageDown/PageUp/Bright+/Bright- mỗi 5 s), `bench_remote`/`bench_kbd` (đổi appearance 0x0180/0x03C1). Nạp: `pio run -e <env> -t upload` (đóng Serial Monitor VS Code trước, nó giữ cổng /dev/cu.usbmodem11401).
- **KẾT QUẢ THỬ TRÊN KINDLE (Paperwhite 12, jailbreak)**: sau khi ghép bằng `lipc-set-prop com.lab126.btfd Bond <địa chỉ BLE ESP32>`, Kindle nhận `category='page_turner'` và ghi nhận đủ metrics `nav.page_forward/back`, `display.brightness_up/down`. Tức HID + VID/PID đúng.
- Phần cứng: đã hàn nút, firmware `esp32c3` đã nạp. Case OpenSCAD (`case/`) + STL (`case/stl/*_v2.stl`) xong, chưa in thử. Sơ đồ `docs/wiring.png` (script `tools/wiring.py`). README.md mô tả BOM/đấu nối/vỏ.

## ĐÃ GIẢI QUYẾT (2026-11-17): lọc quét của Kindle
Nguyên nhân (dịch ngược + KIỂM CHỨNG qua log btmanagerd khi bật `TRC_BTIF=5`, đã trả lại `TRC_BTIF=2`):
- `libbluetooth` `btif_dm_search_devices_evt` (~0xac404): đọc manufacturer data (AD 0xFF) ở nhánh thường: vid = byte[0..1] LE, pid = **byte[2..3] đảo byte (big-endian)**. Nếu `btif_in_is_amazon_ble_remote(vid,pid)` (vid==0x171 và pid thuộc 0x411..0x424/0x443) thì tạo property type **0xFE** {vid,pid} -> `acsbtfd` khớp bảng VID/PID -> `Classify:VP ID match`.
- Lỗi cũ: gửi PID little-endian (`43 04` -> đọc ra 0x4304) nên không khớp. Gói đúng: `71 01 04 43`.
- UUID16 0xFE03 trong adv đặt bit31 của "EIR BTA services" (`BTA_GetEirService`) và chuyển sang nhánh Gadget (property 0x103, cần byte[4..5]=0x0171 + uuid32). Đã kiểm chứng nhánh này chạy (log `services = 80000000`, `gadget_vid=369`), nhưng `ExtractDevice` của `acsbtfd` chỉ đọc type 0xFE nên vẫn `rejected`. Không dùng.
- Cờ discoverable (flags) bắt buộc: bỏ flags thì Bluedroid loại gói (suy đoán, thấy thiết bị biến mất khỏi quét).
- KẾT QUẢ trên Kindle: log `BtDiscoveryFilter:Classify:VP ID match: name=A**e type=1` rồi sự kiện `Discover_Result`; không còn `rejected`. Tên trong log là "A**e" (có vẻ "Amazon Kindle Remote" từ `devices.json`).
- NGƯỜI DÙNG XÁC NHẬN: thiết bị hiện trong menu Bluetooth, kết nối ra popup "Kindle Click connected"; 4 phím + nút hàn thật chạy tốt (log `page_turner_input`: nav.page_forward/back, display.brightness_up/down). Firmware `esp32c3` đã nạp, nút đã hàn. Sleep, deep sleep + nối lại, ghép lại sau Forget: người dùng xác nhận hoạt động tốt.
- Gỡ lỗi sau Forget: ESP phải thức (bấm nút) và ở chế độ ghép đôi; nếu Kindle xoá bond mà ESP còn khoá cũ thì xoá bond ESP trước.
- Kiểm tra quét: `lipc-set-prop -i com.lab126.btfd triggerBTscan 1` rồi đọc `/var/log/messages` (grep `Classify|rejected`).
- Công cụ phân tích: capstone trong venv (không lưu trong repo); `acsbtfd`/`libace_bt_manager_core` là Thumb-2, `libbluetooth` là ARM.
