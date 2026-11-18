import utils.session
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle, FancyBboxPatch

RED, BLK, GRN, ORG, BLU = "#d62828", "#222222", "#2a9d3f", "#e07a00", "#1d5fd1"
fig, ax = plt.subplots(figsize=(16, 11), dpi=130)
ax.set_xlim(0, 16); ax.set_ylim(-2.0, 10.4); ax.axis("off")

def wire(pts, c, lw=3):
    xs, ys = zip(*pts); ax.plot(xs, ys, color=c, lw=lw, solid_capstyle="round", solid_joinstyle="round", zorder=2)
def dot(x, y, c=BLK): ax.add_patch(Circle((x, y), 0.09, color=c, zorder=5))
def box(x, y, w, h, fc, title=None, ec="#333"):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.12", fc=fc, ec=ec, lw=2, zorder=1))
    if title: ax.text(x + w/2, y + h + 0.12, title, ha="center", va="bottom", fontsize=12, weight="bold")
def pin(x, y, label, side, c="#fff"):
    ax.add_patch(Circle((x, y), 0.11, fc="#f2c94c", ec="#333", lw=1.5, zorder=6))
    dx = 0.2 if side == "r" else -0.2
    ax.text(x + dx, y, label, ha="left" if side == "r" else "right", va="center", fontsize=11, weight="bold", zorder=7)
def res(x, y1, y2, label):
    m = (y1 + y2) / 2
    wire([(x, y1), (x, m + 0.35)], ORG); wire([(x, m - 0.35), (x, y2)], ORG)
    ax.add_patch(Rectangle((x - 0.18, m - 0.35), 0.36, 0.7, fc="#f4d9a8", ec="#333", lw=2, zorder=4))
    ax.text(x - 0.3, m, label, fontsize=11, va="center", ha="right", weight="bold")

ax.text(8, 10.1, "Sơ đồ đấu dây ESP32-C3 Kindle Click", ha="center", fontsize=18, weight="bold")

# LiPo
box(0.4, 8.3, 3.0, 1.2, "#cfe8ff", "LiPo 602040 3.7V")
ax.text(1.9, 8.9, "Pin  (+) đỏ   (−) đen", ha="center", va="center", fontsize=10)
# TP4057
box(0.4, 3.1, 3.0, 3.9, "#d9f2d9")
ax.text(1.9, 5.5, "TP4057 USB-C\n(có bảo vệ)", ha="center", fontsize=12, weight="bold")
ax.text(1.9, 3.7, "Cổng USB-C\n(xuống đáy vỏ)", ha="center", fontsize=10)
pin(1.0, 7.0, "B+", "r"); pin(2.4, 7.0, "B−", "r")
wire([(1.0, 8.3), (1.0, 7.0)], RED); wire([(2.4, 8.3), (2.4, 7.0)], BLK)
ax.text(0.9, 7.55, "", fontsize=9)
pin(3.4, 6.2, "OUT+", "l"); pin(3.4, 4.2, "OUT−", "l")

# remove duplicate left labels by overlay
# ESP32
box(7.0, 2.4, 3.0, 5.6, "#e7e1f7", "ESP32-C3 SuperMini")
ax.text(8.5, 1.6 + 0.9, "(cổng USB-C của ESP32\nhướng ra ngoài vỏ)", ha="center", fontsize=9, color="#555")
pin(7.0, 7.0, "5V", "r"); pin(7.0, 5.0, "GPIO4", "r"); pin(7.0, 3.0, "GND", "r")
for y, n in zip([7, 6, 5, 4], [0, 1, 2, 3]): pin(10.0, y, f"GPIO{n}", "l")

# power: OUT+ -> 5V
wire([(3.4, 6.2), (5.0, 6.2), (5.0, 7.0), (7.0, 7.0)], RED); dot(5.0, 6.2, RED)
# divider
wire([(5.0, 6.2), (5.0, 6.0)], ORG)
res(5.0, 6.2, 5.0, "1 MΩ")
dot(5.0, 5.0, ORG); wire([(5.0, 5.0), (7.0, 5.0)], ORG)
res(5.0, 5.0, 3.0, "1 MΩ")
# cap
wire([(6.0, 5.0), (6.0, 4.3)], ORG); dot(6.0, 5.0, ORG)
ax.plot([5.75, 6.25], [4.3, 4.3], color="#333", lw=3, zorder=4); ax.plot([5.75, 6.25], [4.1, 4.1], color="#333", lw=3, zorder=4)
wire([(6.0, 4.1), (6.0, 3.0)], ORG); ax.text(6.3, 3.5, "100 nF", fontsize=11, weight="bold", va="center")
# GND rail
wire([(3.4, 4.2), (4.0, 4.2), (4.0, 3.0), (7.0, 3.0)], BLK); dot(5.0, 3.0); dot(6.0, 3.0)
wire([(4.0, 3.0), (4.0, 0.9), (14.4, 0.9), (14.4, 7.0)], BLK); dot(4.0, 3.0)
ax.text(8.5, 0.55, "Dây GND chung cho cả 4 nút", ha="center", fontsize=11, weight="bold")

# buttons
names = ["Forward  (nút trước TRÊN)", "Back  (nút trước DƯỚI)", "Bright+  (nút cạnh)", "Bright−  (nút cạnh)"]
for y, n in zip([7, 6, 5, 4], names):
    wire([(10.0, y), (11.6, y)], GRN)
    ax.add_patch(Circle((11.6, y), 0.1, fc="#f2c94c", ec="#333", zorder=6)); ax.add_patch(Circle((12.8, y), 0.1, fc="#f2c94c", ec="#333", zorder=6))
    ax.plot([11.7, 12.0], [y, y + 0.28], color="#333", lw=3, zorder=4); ax.plot([12.0, 12.7], [y + 0.28, y + 0.28], color="#333", lw=3, zorder=4) if False else None
    ax.add_patch(Rectangle((11.5, y - 0.3), 1.4, 0.6, fc="none", ec="#333", lw=1.2, ls="--", zorder=3))
    wire([(12.8, y), (14.4, y)], BLK); dot(14.4, y)
    ax.text(11.5, y + 0.4, n, fontsize=10, weight="bold")
ax.text(12.2, 7.85, "4 nút tactile 6×6×8", ha="center", fontsize=12, weight="bold")
ax.text(12.2, 3.35, "mỗi nút: 1 chân → GPIO, 1 chân → GND", ha="center", fontsize=9.5)

# legend/notes
ax.add_patch(FancyBboxPatch((0.4, -1.9), 15.2, 1.9, boxstyle="round,pad=0.02,rounding_size=0.12", fc="#fff8dc", ec="#b8860b", lw=2))
notes = [
 "KHÔNG cần điện trở cho các nút: firmware bật pull-up nội (~45 kΩ) trên GPIO0-3. Nút nhả = HIGH, bấm = nối GND = LOW (cũng là mức đánh thức deep sleep).",
 "Chỉ có 2 điện trở 1 MΩ + tụ 100 nF ở mạch đo pin: chia đôi điện áp pin (4.2 V → 2.1 V) đưa vào GPIO4 (ADC). Tụ lọc nhiễu, 1 MΩ để dòng rò chỉ ~2 µA.",
 "Hàn: LiPo+ → B+, LiPo− → B−. OUT+ → chân 5V của ESP32 (không nối vào 3V3). OUT− → GND. Pin có mạch bảo vệ + TP4057 loại có bảo vệ (4 pad B+/B−/OUT+/OUT−).",
 "Sạc bằng củ 5V-1A hoặc 2A qua USB-C, không cần thêm điện trở.",
 "Màu dây:  đỏ = nguồn dương   đen = GND   xanh lá = tín hiệu nút   cam = mạch đo pin.   Không có công tắc nguồn, không có LED.",
]
for i, t in enumerate(notes): ax.text(0.6, -0.15 - i*0.33, "• " + t, fontsize=9.3, va="top")

plt.savefig(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "wiring.png"), bbox_inches="tight", facecolor="white")
