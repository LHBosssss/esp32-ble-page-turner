// Kindle Click clone - vo in 3D 120 x 40 x 12 mm, than dang vien thuoc
// ESP32-C3 SuperMini + TP4056 USB-C + LiPo 602040, 2 nua vo ghep bang khop cai (khong vit)
// Cong tac: tact 6x6x8 (than 3.6 + chot 4.4) cam vao tui khoet san trong khung + dan keo;
// 4 nut in dan keo len chot cong tac.
// part: base | lid | cap_top1 | cap_top2 | cap_side | plate | assembly | section | sectionx
part = "assembly";

$fn = 64;

// ---------- vo ----------
L = 120;  W = 40;  H = 12;
R = W / 2;
re = 3;
wall = 1.6;  plate = 2.0;  floor_t = 2.0;        // wall = thanh base (mong)
lid_wall = 2.4;                                  // thanh nap day hon cho khoi gay
zs = H - re;
lip_h = 4.5;  lip_t = 1.0;  gap = 0.15;
yw = W/2 - wall;                                 // = 18

// ---------- linh kien ----------
batt = [41, 21, 6.5];                            // LiPo 602040 (+ du dung sai)
tp_len = 18.2; tp_w = 12.3; tp_h = 3.4;          // TP4057 USB-C, cong USB nam o x nho
tp_x = 3.0;  tp_z = 4.3;                         // mach sac nang len 4.3 -> tam cong USB o z=6 (giua vo)
sm_dx = 18;  sm_dy = 22.5;                       // SuperMini xoay 90 do
batt_x = 23;  sm_x = 76;  sm_y0 = -7.4;        // SuperMini sat vach +y (nut hong da sang -y), cong USB-C nhin ra ngoai
batt_z = floor_t + 0.3;  brd_z = floor_t + 0.3;  brd_h = 4.8;
usb_zc = tp_z + 1.7;

// ---------- cong tac tact 6x6x8 ----------
tb = [6.2, 6.2, 3.6];  stem_d = 3.5;  stem_h = 4.4;
pocket = 6.5;                                    // tui 6.5 x 6.5 cho than 6.2
hw = 1.3;  leg_slot = 1.8;  leg_y = 2.4;  leg_side = 1;   // canh co ranh: +1 = +y (canh trai khi dau USB o duoi), -1 = -y. 2 chan canh con lai cat ngan
stem_xs = [100, 70];                            // cong tac nam DUNG DUOI TAM nut tron
sw_z0 = 1.6;                                     // day than cong tac tren (chim 0.4 vao san)
tip_top = sw_z0 + tb[2] + stem_h;                // = 9.6

// ---------- nut tron tren mat ----------
disc_d = 22.6;  hole_d = 23.2;  flange_d = 24.8;   // khe 0.6 moi ben -> nut truot em, khong ket
rec = 0;                                         // nut phang mat tren
dth = H - (H - plate);                           // be day than nut = be day mat tren (2.0)
top_c = [100, 70];                               // tam 2 nut tron (tam nut tren trung tam dau bo tron)
fl_t = 0.9;                                      // be day gờ giu nut tron
rec_d = 3.7;  rec_t = 0.5;                       // o chot: chot 3.5 cam vao on, khong can keo
rect_d = 4.2;  rect_t = 1.1;                      // o chot rieng cho nut tron (rong 4.2, sau 1.0)
cone_h = 1.1;  cone_g = 0.1;  boss_d = 6.2;  boss_h = 4.3;  hole3 = 3.6;  skirt_h = 0;  skirt_w = 0.8;  collar_h = 0;   /* vanh nap: de 0 = tat. Vanh nap CHAN nut (non loe 24.8 khong chui qua lo vanh 23.2) */  collar_od = 26.0;  // bau phang, lung cham dung dau chot cong tac (z=9.6), khong con lo        // loe vat con cao 1.0 (45 do) nam trong be day mat tren, khe 0.1
edge_ch = 0.5;                                   // vat mep nut (chong elephant foot, tay bam em)
// ---------- nut hong (+y) ----------
side_xc = [74.0, 88.0];                          // doi xuong phia dau USB, cach nhau 14 (gờ cach 3.2)
side_zc = 5.5;  cap_l = 9.2;  cap_h = 4.4;  slot_l = 9.8;  slot_h = 5.0;
fl_l = 10.8;  fl_h = 6.0;  fs_t = 1.0;           // gờ nut hong, day 1.0
side_up = 1.0;                                   // phan loi nut hong cao them
cap_pill = wall + side_up;                       // gờ giu van nam o vi tri cu (y 17.4 -> 18.4)
recs_d = 4.2;  recs_t = 0.8;                     // o chot nut hong: rong 4.2, sau 0.8                                 // phan nut nam trong tuong
y_out = W/2 + side_up;                           // mat ngoai nut nho khoi vach 1 mm
y_fl0 = yw - fs_t;                               // mat trong gờ = 17.0
side_shift = 0.5;                                // dich khung nut hong vao tam (bot de chat)
side_tip = y_fl0 + rec_t - side_shift;                        // dau chot = 17.5
side_y_front = side_tip - stem_h;                // mat truoc than = 13.1
side_y_back = side_y_front - tb[2];              // mat sau than = 9.5
cr_w = pocket + 2*hw;                            // be ngang khoi do = 9.1

// ---------- ham hinh hoc ----------
module corner(r, h, f) {
  rotate_extrude() hull() {
    square([0.01, h]);
    translate([r - f, f]) circle(f);
    translate([r - f, h - f]) circle(f);
  }
}
module rbox(x0, x1, y0, y1, z0, z1, r, f) {
  hull() for (x = [x0 + r, x1 - r], y = [y0 + r, y1 - r])
    translate([x, y, z0]) corner(r, z1 - z0, f);
}
module outer() { rbox(0, L, -W/2, W/2, 0, H, R, re); }
module cav(s = 0, z0 = floor_t, z1 = H - plate)
  rbox(wall + s, L - wall - s, -W/2 + wall + s, W/2 - wall - s, z0, z1,
       R - wall - s, max(0.4, re - wall - s));
module rrect2d(x0, x1, y0, y1, r)
  hull() for (x = [x0 + r, x1 - r], y = [y0 + r, y1 - r]) translate([x, y]) circle(r);
module cav2d(s) rrect2d(wall + s, L - wall - s, -W/2 + wall + s, W/2 - wall - s, R - wall - s);
module pill2d(l, h) hull() for (dx = [-1, 1]) translate([dx * (l - h) / 2, 0]) circle(h / 2);
module usbc(x0, x1, zc)
  translate([x0, 0, zc]) rotate([0, 90, 0]) linear_extrude(x1 - x0)
    hull() { translate([0, -3.2]) circle(1.9); translate([0, 3.2]) circle(1.9); }

// ---------- vit M3 + ren vit (thay khop cai) ----------
// Vit M3x10 dau chim, bat TU DAY len. Tru base (z 2 -> 4.4) co lo xuyen 3.4 + loe chim;
// tru nap (z 4.6 -> 10) co lo mo 2.6 de vit tu taro (hoac use_insert = true: lo 4.2 cho oc dong M3).
use_insert = false;
scr_pts = [[22, -15.1, 6.4], [22, 15.1, 6.4], [62, -15.1, 6.4], [62, 15.1, 6.4],
           [100, -15.5, 5.6], [100, 15.5, 5.6]];   // [x, y, duong kinh tru]: them 2 vit o dau nap (x=100)
boss_top = 4.4;  boss_gap = 0.2;
thru_d = 3.3;                                    // lo xuyen base (vit M3 lot, it rơ)
pil_d = use_insert ? 4.2 : 2.5;                  // lo tu taro tren nap, chat hon
rib_l = 5.5;  rib_t = 1.5;                       // gân noi tru voi vach, 2 phia
module post_rib(p, z0, z1) {          // chi nam tren doan vach thang (x 20 -> 100), khong lan vao dau bo tron
  xa = max(p[0] > 90 ? 96.0 : 20, p[0] - rib_l);  xb = min(100, p[0] + rib_l);
  translate([xa, p[1] > 0 ? yw - 0.1 - rib_t : -(yw - 0.1), z0]) cube([xb - xa, rib_t, z1 - z0]);
}
module screw_posts_base() for (p = scr_pts) {
  translate([p[0], p[1], floor_t - 0.2]) cylinder(d = p[2], h = boss_top - floor_t + 0.2);
  post_rib(p, floor_t - 0.2, boss_top);
}
module screw_holes_base() for (p = scr_pts) {
  translate([p[0], p[1], -1]) cylinder(d = thru_d, h = boss_top + 2);
  translate([p[0], p[1], -0.01]) cylinder(d1 = 6.4, d2 = thru_d, h = 1.5);
}
module screw_posts_lid() for (p = scr_pts) {
  translate([p[0], p[1], boss_top + boss_gap]) cylinder(d = p[2], h = H - plate - boss_top - boss_gap + 0.1);
  post_rib(p, boss_top + boss_gap, H - plate + 0.1);
}
module screw_holes_lid() for (p = scr_pts) translate([p[0], p[1], boss_top + boss_gap - 0.1]) cylinder(d = pil_d, h = H - plate - boss_top + 0.5);

// cua USB-C: mach sac (dau x=0) va SuperMini (vach -y)
module usb_opening() {
  usbc(-1, 5, usb_zc);
  translate([-1, 0, usb_zc + 0.2]) rotate([0, 90, 0]) linear_extrude(3.2)
    hull() { translate([0, -3.5]) circle(3); translate([0, 3.5]) circle(3); }
}
sm_usb_z = brd_z + 2.6;
module sm_usb_opening() translate([sm_x + sm_dx/2, 0, sm_usb_z]) {
  translate([0, W/2 + 1, 0]) rotate([90, 0, 0]) linear_extrude(wall + 2) pill2d(10.6, 4.6);    // xuyen vach
  translate([0, W/2 + 1, 0]) rotate([90, 0, 0]) linear_extrude(1.0 + 1) pill2d(13.6, 7.6);    // loe ngoai cho vo phich cam
}

// ---------- nut roi (z=0 la mat ngoai nut, huong vao trong) ----------
// nut tron: dia + gờ giu. IN LAT NGUOC: gờ xuong ban in, mat ngoai huong len (min, khong support)
// nut tron: dia + gờ giu; dx = do lech cua o loe so voi tam nut (cho chot cong tac)
module plunger(dx) difference() {
  union() {
    cylinder(d1 = disc_d - 2*edge_ch, d2 = disc_d, h = edge_ch);       // vat mep mat ngoai
    translate([0, 0, edge_ch - 0.01]) cylinder(d = disc_d, h = dth - cone_h - edge_ch + 0.02);
    translate([0, 0, dth - cone_h]) cylinder(d1 = disc_d, d2 = disc_d + 2*cone_h, h = cone_h);   // loe hinh con nam TRONG be day mat tren
    if (skirt_h > 0) translate([0, 0, dth - 0.01]) difference() { cylinder(d = disc_d, h = skirt_h + 0.01); translate([0, 0, -0.1]) cylinder(d = disc_d - 2*skirt_w, h = skirt_h + 0.3); }   // vanh dan huong sau nut
    translate([0, 0, dth - 0.01]) cylinder(d = boss_d, h = boss_h + 0.01);   // bau nho de cham cong tac
  }
  translate([dx, 0, dth]) cylinder(d = hole3, h = boss_h + 0.5);   // lo dan huong chot 3.4, day lo = 1.8 tu mat ngoai
}
// nut hong dang vien thuoc: than nut + gờ giu (day 1.0) + o loe cho chot
module cap_side() difference() {
  union() {
    linear_extrude(cap_pill) pill2d(cap_l, cap_h);
    translate([0, 0, cap_pill]) linear_extrude(fs_t) pill2d(fl_l, fl_h);
  }
  translate([0, 0, cap_pill + fs_t - recs_t]) cylinder(d = recs_d, h = recs_t + 0.1);
}
function dxs(i) = stem_xs[i] - top_c[i];
module place_plunger(i) translate([top_c[i], 0, H - rec]) rotate([180, 0, 0]) plunger(dxs(i));
module place_cap(xc) mirror([0, 1, 0]) translate([xc, y_out, side_zc]) rotate([90, 0, 0]) cap_side();

// ---------- khung cong tac (in lien voi than) ----------
// nut tren: tui 6.5x6.5 mo phia tren (luon cong tac tu tren xuong), thanh day 1.3,
// khe luon day phia -y sat san
top_hold_z = 8.2;                                // khung cong tac tren cao 8.2: bau nut chui vao lam dan huong
module top_hold(x) translate([x - cr_w/2, -cr_w/2, floor_t - 0.2]) cube([cr_w, cr_w, top_hold_z - floor_t + 0.2]);
module top_hold_cut(x) {
  translate([x - pocket/2, -pocket/2, sw_z0]) cube([pocket, pocket, 8]);
  // 2 ranh THANG o 1 canh (leg_side: +1 = canh trai khi nhin vo dung doc, dau USB o duoi = phia +y)
  // cho chan dep SMD nho ngang ra tho ra han day; mo tu long tui ra mat ngoai va mo len tren
  for (sx = [-1, 1]) translate([x + sx * leg_y - leg_slot/2, leg_side > 0 ? pocket/2 - 0.3 : -(cr_w/2 + 0.2), sw_z0])
    cube([leg_slot, cr_w/2 - pocket/2 + 0.5, 4.8]);
}
// nut hong: khoi dac tu san len z=8.5, tui mo phia tren va phia truoc (cho chot),
// thanh sau day 1.2 chiu luc bam, khe luon day phia sau
module side_hold(xc) translate([xc - cr_w/2, side_y_back - hw + 0.1, floor_t - 0.2])
  cube([cr_w, (side_y_front + 0.6) - (side_y_back - hw + 0.1), 8.5 - floor_t + 0.2]);
module side_hold_cut(xc) {
  translate([xc - pocket/2, side_y_back, side_zc - tb[1]/2 - 0.05]) cube([pocket, 6, 8]);
}
// ---------- khung giu mach sac / pin / SuperMini ----------
bi = batt[1]/2 + 0.2;  bt = 1.0;  bz = 7.2;           // pin: nua rong trong, day thanh, cao khung
bf0 = 22.6;  bf1 = 64.4;                              // pin: mep trong khung theo x (pin x 23 -> 64)
wire_gap = 3.5;                                       // khe luon day o 2 dau khung pin (|y| < 3.5)
module cradles() {
  // TP4057: gờ do mep bo (z 2 -> tp_z) + thanh chan 2 ben; chan sau chinh la khung pin
  for (s = [-1, 1]) {
    translate([5, s > 0 ? 4.8 : -7.4, floor_t - 0.2]) cube([16.2, 2.6, tp_z - floor_t + 0.2]);
    translate([5, s > 0 ? tp_w/2 + 0.2 : -(tp_w/2 + 1.4), floor_t - 0.2]) cube([16.2, 1.2, 7.0 - floor_t + 0.2]);
  }
  // khung bao pin: 2 thanh dai lien + 2 dau co khe luon day
  for (s = [-1, 1]) {
    translate([bf0 - bt, s > 0 ? bi : -(bi + bt), floor_t - 0.2]) cube([bf1 - bf0 + 2*bt, bt, bz - floor_t + 0.2]);
    for (x = [bf0 - bt, bf1])
      translate([x, s > 0 ? wire_gap : -(bi + bt), floor_t - 0.2]) cube([bt, (bi + bt) - wire_gap, bz - floor_t + 0.2]);
  }
  // SuperMini: khung bao kin quanh bo (khe 0.4) + 2 vach om 2 ben dau Type-C (+y)
  sx0 = sm_x - 0.4;  sx1 = sm_x + sm_dx + 0.4;  sy0 = sm_y0 - 0.4;  sy1 = 17.1;  fw = 1.0;  fz = 6.0;
  translate([sx0 - fw, sy0, floor_t - 0.2]) cube([fw, sy1 - sy0, fz - floor_t + 0.2]);          // vach trai (x nho)
  translate([sx1, sy0, floor_t - 0.2]) cube([fw, sy1 - sy0, fz - floor_t + 0.2]);               // vach phai
  for (sg = [-1, 1]) translate([sg > 0 ? sm_x + sm_dx/2 + 3.3 : sm_x + sm_dx/2 - 3.3 - 3.0 - 0 , sy0 - 0.5, floor_t - 0.2])
    cube([3.0, 0.5, fz - floor_t + 0.2]);                                                         // dau -y: 2 chan, chua khe luon day o giua
  // om Type-C: vach 2 ben cao len 7.4 o doan cuoi, + dem chan sat dau cong (nam tren san, sau bo)
  translate([sx0 - fw, 11.2, floor_t - 0.2]) cube([fw, sy1 - 11.2, 7.4 - floor_t + 0.2]);
  translate([sx1, 11.2, floor_t - 0.2]) cube([fw, sy1 - 11.2, 7.4 - floor_t + 0.2]);
  translate([sm_x + sm_dx/2 - 6, 17.2, floor_t - 0.2]) cube([12, yw - 17.2, 7.4 - floor_t + 0.2]);   // dem chan: chua 2 mm sau dau bo cho Type-C
}

// ---------- khe dat day tren dinh vach khung ----------
wn_w = 2.6;  wn_d = 1.9;                         // be rong khe, do sau khe
module wnx(x, y0, y1, ztop) translate([x - wn_w/2, y0, ztop - wn_d]) cube([wn_w, y1 - y0, wn_d + 0.5]);   // khe cat qua vach chay doc theo x
module wny(y, x0, x1, ztop) translate([x0, y - wn_w/2, ztop - wn_d]) cube([x1 - x0, wn_w, wn_d + 0.5]);   // khe cat qua vach chay doc theo y
module wire_notches() {
  // khung pin: thanh dai (cao bz) va 2 dau
  for (x = [30, 44, 57]) { wnx(x, bi - 0.1, bi + bt + 0.1, bz); wnx(x, -(bi + bt + 0.1), -(bi - 0.1), bz); }
  for (s = [-1, 1]) for (xx = [bf0 - bt, bf1]) wny(s * 7.5, xx - 0.1, xx + bt + 0.1, bz);
  // mach sac: thanh chan 2 ben (cao 7.0)
  for (x = [9, 15]) { wnx(x, tp_w/2 + 0.1, tp_w/2 + 1.5, 7.0); wnx(x, -(tp_w/2 + 1.5), -(tp_w/2 + 0.1), 7.0); }
  // SuperMini: 2 vach ben, 2 chan dau -y va dem Type-C
  for (y = [sm_y0 + 5, sm_y0 + 12]) { wny(y, sm_x - 1.5, sm_x - 0.3, 6.0); wny(y, sm_x + sm_dx + 0.3, sm_x + sm_dx + 1.5, 6.0); }
  wny(sm_y0 + sm_dy - 1, sm_x - 1.5, sm_x - 0.3, 7.4);  wny(sm_y0 + sm_dy - 1, sm_x + sm_dx + 0.3, sm_x + sm_dx + 1.5, 7.4);
}

// ---------- than va nap ----------
module base() {
  difference() {
    union() {
      difference() {
        intersection() { outer(); translate([-1, -W, 0]) cube([L + 2, 2*W, zs]); }
        cav();
        usb_opening();
        mirror([0, 1, 0]) for (xc = side_xc) translate([0, W/2 + 1, 0]) rotate([90, 0, 0]) linear_extrude(wall + 1.2)
          translate([xc, side_zc]) pill2d(slot_l, slot_h);
      }
      for (x = stem_xs) top_hold(x);
      mirror([0, 1, 0]) for (xc = side_xc) side_hold(xc);
      cradles();
      screw_posts_base();
    }
    for (x = stem_xs) top_hold_cut(x);
    mirror([0, 1, 0]) for (xc = side_xc) side_hold_cut(xc);
    screw_holes_base();
    wire_notches();
  }
}
module lip_notches() {
  translate([sm_x + sm_dx/2 - 6.5, 16.9, zs - lip_h - 0.1]) cube([13, 3.5, lip_h + 0.2]);   // cho dem chan Type-C di xuyen
  translate([-1, -7.5, zs - lip_h - 0.1]) cube([9, 15, lip_h + 0.2]);   // cho cam USB-C mach sac
  translate([min(side_xc) - 7, -(yw - 1.6) - 3.5, zs - lip_h - 0.1]) cube([max(side_xc) - min(side_xc) + 14, 3.5, lip_h + 0.2]);
}
module top_hole(c) {
  za = dth - cone_h + (hole_d - disc_d)/2 - cone_g;       // chieu sau (tu mat ngoai) noi tru va con
  zb = dth + 0.1;
  translate([c, 0, H - za]) cylinder(d = hole_d, h = za + 0.1);
  translate([c, 0, H - zb]) cylinder(d1 = hole_d + 2*(zb - za), d2 = hole_d, h = zb - za + 0.001);
}
module top_collar(c) difference() {
  translate([c, 0, H - plate - collar_h]) cylinder(d = collar_od, h = collar_h + 0.02);
  translate([c, 0, H - plate - collar_h - 0.1]) cylinder(d = hole_d, h = collar_h + 0.3);
  for (p = scr_pts) translate([p[0], p[1], H - plate - collar_h - 0.1]) cylinder(d = p[2] + 0.8, h = collar_h + 0.5);
  translate([0, -20, H - plate - collar_h - 0.1]) cube([batt_x + batt[0] + 0.6, 40, collar_h + 0.5]);   // tranh cuc pin
}
module usb_clamp() translate([sm_x + sm_dx/2 - 5.8, 11.2, 7.7]) cube([11.6, 17.1 - 11.2, H - plate - 7.7 + 0.1]);   // ép nhẹ tu tren xuong len cong Type-C
module lid() {
  difference() {
    union() {
      difference() {
        intersection() { outer(); translate([-1, -W, zs]) cube([L + 2, 2*W, H]); }
        cav(lid_wall - wall, zs - 3, H - plate);
        for (c = top_c) top_hole(c);
      }
      difference() {
        translate([0, 0, zs - lip_h]) linear_extrude(lip_h + 0.5) difference() { cav2d(gap); cav2d(gap + lip_t); }
        lip_notches();
      }
      translate([0, 0, zs]) linear_extrude(0.5) difference() { cav2d(-0.2); cav2d(gap + lip_t); }
      screw_posts_lid();
      if (collar_h > 0) for (c = top_c) top_collar(c);
      usb_clamp();
    }
    screw_holes_lid();
  }
}

// ---------- linh kien minh hoa ----------
module comps() {
  color("goldenrod") translate([batt_x, -batt[1]/2, batt_z]) cube(batt);
  color("purple") translate([tp_x, -tp_w/2, tp_z]) cube([tp_len, tp_w, tp_h]);
  color("teal") translate([sm_x, sm_y0, brd_z]) cube([sm_dx, sm_dy, brd_h]);
  color("red") for (x = stem_xs) {
    translate([x - tb[0]/2, -tb[1]/2, sw_z0]) cube(tb);
    translate([x, 0, sw_z0 + tb[2]]) cylinder(d = stem_d, h = stem_h);
  }
  color("red") mirror([0, 1, 0]) for (xc = side_xc) {
    translate([xc - tb[0]/2, side_y_back, side_zc - tb[1]/2]) cube([tb[0], tb[2], tb[1]]);
    translate([xc, side_y_front, side_zc]) rotate([-90, 0, 0]) cylinder(d = stem_d, h = stem_h);
  }
}
module caps() {
  color("white") for (i = [0:1]) place_plunger(i);
  color("white") for (xc = side_xc) place_cap(xc);
}

if (part == "chk1") intersection() { base(); lid(); }
else if (part == "chk2") intersection() { comps(); union() { base(); lid(); } }
else if (part == "chk3") intersection() { caps(); union() { base(); lid(); comps(); } }
else if (part == "base") base();
else if (part == "lid") lid();
else if (part == "cap_top1") plunger(dxs(0));
else if (part == "cap_top2") plunger(dxs(1));
else if (part == "cap_side") cap_side();
else if (part == "plate") {
  translate([14, 14, 0]) plunger(dxs(0));
  translate([42, 14, 0]) plunger(dxs(1));
  translate([68, 14, 0]) cap_side();
  translate([68, 26, 0]) cap_side();
}
else if (part == "assembly") { color("lightgray") base(); color("silver") lid(); comps(); caps(); }
else if (part == "sectionx") difference() {
  union() { color("lightgray") base(); color("silver") lid(); comps(); caps(); }
  translate([79.4, -50, -1]) cube([100, 100, 60]);
}
else if (part == "section") difference() {
  union() { color("lightgray") base(); color("silver") lid(); comps(); caps(); }
  translate([-1, -50, -1]) cube([L + 2, 50, 60]);
}
