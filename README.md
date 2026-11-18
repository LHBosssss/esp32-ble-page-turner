# ESP32 Kindle Click

> ## ⚠️ Tuyên bố miễn trừ / Disclaimer
> Dự án này **chỉ phục vụ mục đích nghiên cứu, học tập và sử dụng cá nhân phi thương mại** (khả năng tương tác giữa thiết bị BLE HID tự chế và Kindle).
> - Không liên kết, không được tài trợ hay chứng thực bởi Amazon. "Amazon", "Kindle", "Kindle Click" là nhãn hiệu của chủ sở hữu tương ứng; tên và mã VID/PID chỉ dùng để mô tả mức tương thích.
> - Repo **không chứa** firmware, binary hay mã nguồn của Amazon. Các ghi chú trong `HANDOFF.md` là quan sát kỹ thuật từ chính thiết bị của tác giả.
> - Không dùng để sản xuất, bán hay phân phối thương mại. Bạn chịu trách nhiệm tuân thủ pháp luật, điều khoản dịch vụ của Amazon và bản quyền tại nơi bạn sống. Jailbreak/chỉnh sửa Kindle có thể mất bảo hành hoặc vi phạm điều khoản.
> - Phần cứng liên quan đến pin Li-Po và sạc: tự chịu rủi ro khi lắp ráp. Phần mềm và tài liệu được cung cấp "nguyên trạng", không bảo hành.

Remote lật trang giả lập Kindle Click bằng ESP32-C3 (BLE HID over GATT): 4 nút (chìm trong vỏ), báo pin, deep sleep, mạch sạc USB-C, vỏ viên thuốc in 3D.
Nguồn kỹ thuật: https://kindlemodding.org/kindle-hacking/pageturner.html · Hành vi theo trang hướng dẫn của Amazon.

## Yêu cầu về Kindle
Kindle Click chính hãng của Amazon yêu cầu ([trang sản phẩm](https://www.amazon.com/Amazon-Kindle-Click/dp/B0GZ5D64F8), [trang hướng dẫn ghép](https://www.amazon.com/gp/help/customer/display.html?nodeId=TABSEKWWQT3Li6v7WZ)):
- Phiên bản phần mềm Kindle **5.20.1.0.2 trở lên** (Settings ▸ Device Options ▸ Software Updates).
- Đời máy **2024 trở lên** (không phải 2022). Amazon ghi không tương thích với Kindle ra mắt trước 2024.

Remote này bắt chước Kindle Click nên **khả năng tương thích phụ thuộc vào cùng hỗ trợ trong phần mềm Kindle**: máy đời cũ/firmware cũ có thể không nhận hoặc không hiện trong menu quét. Đã thử thực tế trên **Kindle Paperwhite 12** (jailbreak). Các đời máy khác chưa kiểm chứng.

## Hành vi (giống Kindle Click thật)
| Thao tác | Kết quả |
|---|---|
| 2 nút tròn mặt trước | Lật trang tới / lui (PageDown / PageUp) |
| 2 nút cạnh phải | Tăng / giảm độ sáng (giữ để lặp: trễ 500 ms, chu kỳ 333 ms) |
| Giữ **cả 2 nút độ sáng** ~1 s | Sleep (KEY_POWER) |
| Giữ nút trước phía trên 2 s | Chế độ ghép đôi (kéo dài 2 phút) |
| Giữ nút trước phía dưới + giảm sáng 10 s | Xoá host đã ghép, vào chế độ ghép đôi |
| Không bấm 30 s | Deep sleep (~µA); bấm nút nào cũng thức dậy, nối lại và gửi bù phím vừa bấm |

Không có đèn LED báo trạng thái: theo dõi ghép đôi và pin trên Kindle (Settings ▸ Wi-Fi & Bluetooth ▸ Bluetooth Devices ▸ Kindle Click). Pin báo qua Battery Service (0x180F).
Lần đầu chưa ghép, firmware tự vào chế độ ghép đôi. Kindle nhận remote theo VID `0x0171` / PID `0x0443`.

### Gói quảng bá BLE (để hiện trong menu quét của Kindle)
Kindle chỉ liệt kê thiết bị BLE nếu `libbluetooth` suy ra được VID/PID từ gói quảng bá. Gói của firmware này:
`flags` + tên đầy đủ `Kindle Click` + UUID 0x1812 + manufacturer data `71 01 04 43` (company ID `0x0171` little-endian, PID `0x0443` **big-endian**).
Đừng thêm UUID `0xFE03` (chuyển sang nhánh "Gadget" mà `acsbtfd` bỏ qua). Phát hiện này đến từ dịch ngược, chi tiết trong `HANDOFF.md`.
Nếu menu quét không hiện, vẫn ghép được bằng lệnh trên Kindle (đã jailbreak): `lipc-set-prop com.lab126.btfd Bond <địa chỉ BLE>`.

> Firmware chưa giới hạn "chỉ 1 Kindle": host nào đã ghép cũng nối được. Nút trước phía trên cũng gửi PageDown khi bắt đầu giữ (ghép đôi).
> Nút trên là Forward, nút dưới là Back; muốn đảo thì đổi `PIN_FWD`/`PIN_BACK`.

## Linh kiện
| Linh kiện | Ghi chú |
|---|---|
| ESP32-C3 SuperMini | Cần GPIO0-3 (đánh thức) và GPIO4 (ADC) |
| LiPo **602040** (3.7 V, ~500 mAh, 6×20×40 mm) có mạch bảo vệ | Vỏ chừa 41 × 21 × 6.5 mm |
| Module sạc **TP4057 USB-C có bảo vệ** (pad B+/B-/OUT+/OUT-) | ~18.2 × 12.3 mm, cao ~3.4 mm |
| 4 nút tactile **6×6×8 mm** (thân 3.6 + núm 4.4) | |
| 2× 1 MΩ + 1× 100 nF | Cầu chia đo pin |
| 6 vít **M3×10** đầu chìm (hoặc ốc đồng M3 nếu `use_insert = true`) | Bắt từ đáy lên; ít xốp mỏng/Kapton, keo CA |

## Chọn pin
- **LiPo 1 cell (1S) 3.7 V, mã 602040**: dày 6 × rộng 20 × dài 40 mm, ~500 mAh. Khung giữ pin trong vỏ chừa 41 × 21 × 6.5 mm.
- Phải có mạch bảo vệ (PCM). Không dùng pin 2S (7.4 V).
- Pin rẻ thường lớn hơn mã 0.5–1 mm: đo bằng thước cặp khi nhận; nếu lớn hơn khung thì chỉnh `batt` trong `case/kindle_click_case.scad`.
- Kiểm tra cực tính dây/jack bằng đồng hồ trước khi nối (jack JST bán sẵn có thể bị đảo cực).
- Thời lượng chỉ là ước tính, cần tự đo dòng ngủ: LED nguồn của SuperMini nên gỡ.

## Đấu nối
```
Nút (mỗi nút 1 chân GPIO, 1 chân GND, KHÔNG cần điện trở: dùng pull-up nội)
  GPIO0 ─ Forward (nút trước trên)      GPIO2 ─ Bright+ (cạnh)
  GPIO1 ─ Back    (nút trước dưới)      GPIO3 ─ Bright− (cạnh)


Nguồn + đo pin:
  TP4057 B+ ── LiPo (+)      TP4057 B- ── LiPo (−)
  TP4057 OUT+ ──┬── ESP32-C3 chân 5V
                └── 1MΩ ──┬── 1MΩ ── GND         GPIO4 nối điểm giữa, 100 nF từ điểm giữa xuống GND
  TP4057 OUT− ── GND chung
```
- Dùng TP4057 **có bảo vệ**. Sạc bằng củ **5 V – 1 A hoặc 2 A** qua USB-C, **không cần thêm điện trở**: module tự giới hạn dòng sạc. Nếu thấy pin nóng khi sạc thì mới cân nhắc đổi điện trở PROG của module.
- Không nối 4.2 V vào chân 3V3; 5V của SuperMini đi qua diode/LDO onboard.
- Không có công tắc nguồn (như Kindle Click thật): máy tự ngủ. Muốn ngủ sâu nhất, gỡ LED nguồn của SuperMini (xem mục "Tắt LED nguồn").
- TP4057 tự sạc độc lập, không cần dây báo trạng thái về ESP32.

## Tắt LED nguồn để tiết kiệm pin
ESP32-C3 SuperMini có LED nguồn (đỏ) nối thẳng vào 3V3 qua điện trở, **luôn sáng, kể cả lúc deep sleep**, và phần mềm không tắt được. Firmware này không điều khiển LED nào (LED xanh, nếu board có, nằm trên GPIO8 và không được firmware bật).
Nên **gỡ LED đỏ hoặc điện trở nối tiếp với nó** trước khi lắp vào vỏ:
1. Tìm LED đỏ SMD nhỏ trên board (thường gần cổng USB-C). Vị trí khác nhau giữa các phiên bản board: xác định bằng mắt/đồng hồ đo thông mạch (LED nối nối tiếp với một điện trở).
2. Dùng mỏ hàn (hoặc khò nhiệt) gỡ LED, **gỡ luôn điện trở nối tiếp** nếu có thể (chỉ cần gỡ một trong hai là đứt mạch LED; gỡ cả hai cho chắc). Cẩn thận không làm bong pad.
3. Đo dòng ở chế độ deep sleep (nối ampe kế/đồng hồ vạn năng chuỗi với pin) để xác nhận đã giảm.

Ví dụ tham khảo trên board khác: LED đỏ 2 kΩ ăn ~725 µA, bỏ đi dòng ngủ còn ~106 µA ([LilyGo T-OI Plus](https://community.lilygo.cc/post/150)). Số liệu của riêng SuperMini chưa kiểm chứng, bạn nên tự đo. Cũng xem [diễn đàn Espressif](https://esp32.com/viewtopic.php?p=144468) về dòng deep sleep của SuperMini.
Không có ảnh vị trí chính xác cho mọi phiên bản board: hãy chụp board của bạn để đối chiếu trước khi gỡ.

## Vỏ in 3D (`case/`)
Vỏ **120 × 40 × 12 mm** dạng viên thuốc, 2 nửa (đế + nắp) **ghép bằng vít M3×10 đầu chìm bắt từ đáy lên** (trụ vít ở đế có lỗ xuyên Ø3.3 và loe chìm; trụ ở nắp có lỗ Ø2.6 cho vít tự taro, hoặc lỗ Ø4.2 cho ốc đồng M3 khi đặt `use_insert = true`). Chỉnh kích thước ở các biến đầu `case/kindle_click_case.scad`.
- **Đế (`base`)**: sàn, gờ ghép, khung giữ pin 602040, đế nâng mạch sạc TP4057 (tâm cổng USB-C ở giữa độ dày vỏ), chỗ đặt ESP32-C3 xoay 90°, cổng USB-C ló ra đầu vỏ.
- **Nắp (`lid`)**: mặt trên có 2 lỗ nút tròn (Ø23.4) và khung 2 nút cạnh; công tắc tact 6×6×8 cắm vào túi khoét sẵn trong khung rồi dán keo.
- **Nút**: nút tròn (`cap_top1`, `cap_top2`) và nút cạnh (`cap_side`) in rời, dán lên chốt công tắc; `plate` là tấm kèm theo.
- Nút tròn nằm phẳng mặt trên; nút cạnh nhô ~1 mm ở cạnh +y.

### Bố trí
ESP32 và pin nằm cạnh nhau trên sàn, mạch sạc TP4057 ở đầu có cổng USB-C. ESP32 (SuperMini) sát vách +y, cổng USB-C của nó hướng ra ngoài. Các nút nằm về phía đầu còn lại.
Nạp firmware qua cổng USB-C của SuperMini; nếu cổng này không lộ ra ngoài vỏ thì nạp trước khi lắp hoặc mở vỏ khi cần nạp lại.

### Xuất & in
STL có sẵn trong `case/stl/`: `base_v2` (đế), `lid_v2` (nắp), `plate_v2`, `cap_top1_v2`, `cap_top2_v2`, `cap_side_v2`. Tạo lại từ `.scad` (đổi `part`):
```
openscad -D 'part="base"' -o base.stl case/kindle_click_case.scad     # lid / cap_top1 / cap_top2 / cap_side / plate tương tự
```
Đặt `part = "assembly"` để xem lắp ráp. PETG hoặc PLA, layer 0.2, 3 vách, infill 20–30 %. Không cần support (kiểm tra theo slicer của bạn).

### Lắp ráp
1. Cắm 4 công tắc tact 6×6×8 vào túi trong khung nắp, nhỏ keo; cắt ngắn chân và hàn dây theo sơ đồ.
2. Dán các nút in lên chốt công tắc.
3. Đặt pin vào khung, TP4057 lên đế nâng, ESP32 vào chỗ (lót xốp). Hàn theo sơ đồ.
4. Đóng nắp, bắt vít M3×10 từ đáy lên (số vít theo `scr_pts` trong `.scad`).

### Đã kiểm chứng
- Trên Kindle Paperwhite 12: thiết bị hiện trong menu Bluetooth, ghép được, 4 nút hoạt động (lật trang, độ sáng).
- Sleep (giữ 2 nút độ sáng), deep sleep 30 s và nối lại, ghép lại sau khi Forget đều hoạt động tốt.

### Lưu ý khi lắp vỏ
- Cần đo lại PCB/pin/tactile bằng thước cặp và chỉnh biến đầu `.scad` nếu in không vừa.
- Kiểm tra mạch TP4057 và ESP32 không chạm nhau.

## Nạp firmware

### 1. Chuẩn bị
- Cần board **ESP32-C3 SuperMini** (USB-C) và cáp USB có truyền dữ liệu.
- Cài [PlatformIO](https://platformio.org/install) (extension VS Code hoặc CLI: `pip install platformio`).
- Thư viện (NimBLE-Arduino) và platform tự tải khi build lần đầu.

### 2. Nạp
```
git clone https://github.com/LHBosssss/esp32-ble-page-turner.git && cd esp32-ble-page-turner
pio run -e esp32c3 -t upload
```
- Chọn đúng env: `esp32c3` là bản thật (có deep sleep). Bản thử trên bàn khi chưa hàn nút: `pio run -e bench -t upload` (không ngủ, luôn ghép đôi); `bench_auto` tự gửi PageDown/PageUp/Bright+/Bright- mỗi 5 s.
- macOS: cổng thường là `/dev/cu.usbmodem*`. Đóng Serial Monitor trước khi nạp (nó giữ cổng).
- Nếu không thấy cổng hoặc nạp lỗi: giữ nút **BOOT**, cắm USB (hoặc bấm RESET) rồi thả BOOT để vào chế độ nạp, sau đó chạy lại lệnh. Nạp xong bấm RESET.
- Nên nạp **trước khi lắp vào vỏ**; nếu cổng USB-C của ESP32 không lộ ra ngoài vỏ thì phải mở vỏ để nạp lại.
- Xem log: `pio device monitor` (115200).

### 3. Ghép với Kindle
1. Lần đầu, firmware tự vào chế độ ghép đôi (hoặc giữ nút trước phía trên 2 s).
2. Trên Kindle: **Settings ▸ Wi-Fi & Bluetooth ▸ Bluetooth Devices**, bấm quét, chọn **Kindle Click**. Kindle hiện popup "Kindle Click connected".
3. Nếu menu quét không hiện (hoặc Kindle đã jailbreak): ghép bằng lệnh trên Kindle:
   `lipc-set-prop com.lab126.btfd Bond <địa chỉ BLE của ESP32>`
   (địa chỉ BLE in ra Serial lúc khởi động).
4. Ghép lại từ đầu: Forget trên Kindle, giữ nút Back + Bright− 10 s để xoá bond trên ESP32, rồi ghép lại.

Chi tiết kỹ thuật, nguyên nhân Kindle lọc thiết bị khi quét và cách khắc phục: xem `HANDOFF.md`.

## Cấu trúc repo
```
src/main.cpp              firmware
platformio.ini            các env build
case/kindle_click_case.scad  vỏ OpenSCAD;  case/stl/  file STL
docs/wiring.png           sơ đồ đấu nối (tools/wiring.py)
tools/                    script vẽ sơ đồ, xuất STL
HANDOFF.md                ghi chú kỹ thuật, dịch ngược
```
