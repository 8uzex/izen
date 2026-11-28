"""
ToolAuto 6.0 - mini game từ UZEX Hub, chạy ngoài game bằng nhận diện màn hình.
Cài đặt:  pip install pynput mss numpy
Chạy:     python toolauto.py

Rùa (Black Tortoise, Hard): 3 làn A/S/D, nốt rơi xuống vạch -> bấm phím,
                            bỏ qua nốt ĐỎ (bẫy).
Enzo + Long Điếu Hải (phase 2): vạch xanh dương chạy ngang, vào vùng XANH LÁ
                            thì click chuột trái, tránh vùng ĐỎ.
F8 = Chạy, F9 = Dừng.  Lần đầu bấm "Chọn vùng" để khoanh vùng trên màn hình.
"""
import ctypes
import json
import os
import threading
import time
import tkinter as tk
from tkinter import messagebox

import numpy as np
import mss
from pynput import keyboard, mouse

try:
    ctypes.windll.shcore.SetProcessDpiAwareness(2)  # toạ độ khớp mss
except Exception:
    pass

kb = keyboard.Controller()
ms = mouse.Controller()
CFG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "toolauto_config.json")

MODES = {
    "turtle": ("Rùa", "Phím A / S / D"),
    "boss": ("Enzo + Long Điếu Hải", "Chuột trái"),
}


def pick_region(root, prompt):
    """Kéo chuột khoanh vùng trên màn hình. Trả về dict mss hoặc None."""
    res = {}
    top = tk.Toplevel(root)
    top.attributes("-fullscreen", True)
    top.attributes("-alpha", 0.3)
    top.attributes("-topmost", True)
    top.configure(bg="black")
    cv = tk.Canvas(top, bg="black", highlightthickness=0, cursor="crosshair")
    cv.pack(fill="both", expand=True)
    cv.create_text(top.winfo_screenwidth() // 2, 60, text=prompt + "  (Esc = hủy)",
                   fill="white", font=("Segoe UI", 18, "bold"))
    st = {}

    def down(e):
        st["x0"], st["y0"] = e.x_root, e.y_root
        st["rect"] = cv.create_rectangle(e.x, e.y, e.x, e.y, outline="red", width=2)

    def move(e):
        if "rect" in st:
            cv.coords(st["rect"], st["x0"], st["y0"], e.x_root, e.y_root)

    def up(e):
        x0, x1 = sorted((st["x0"], e.x_root))
        y0, y1 = sorted((st["y0"], e.y_root))
        if x1 - x0 > 3 and y1 - y0 > 3:
            res.update(left=x0, top=y0, width=x1 - x0, height=y1 - y0)
        top.destroy()

    cv.bind("<ButtonPress-1>", down)
    cv.bind("<B1-Motion>", move)
    cv.bind("<ButtonRelease-1>", up)
    top.bind("<Escape>", lambda e: top.destroy())
    top.focus_force()
    root.wait_window(top)
    return res or None


def grab(sct, region):
    return np.asarray(sct.grab(region))[:, :, :3].astype(np.int16)  # BGR


class App:
    def __init__(self, root):
        self.root = root
        root.title("ToolAuto")
        root.geometry("560x500")
        root.configure(bg="#f4f4f8")
        root.attributes("-topmost", True)
        self.mode = tk.StringVar(value="turtle")
        self.running = False
        self.cfg = {}
        if os.path.exists(CFG_FILE):
            try:
                self.cfg = json.load(open(CFG_FILE))
            except Exception:
                pass

        head = tk.Frame(root, bg="#f4f4f8")
        head.pack(fill="x", padx=20, pady=(14, 0))
        tk.Label(head, text="ToolAuto", font=("Segoe UI", 22, "bold"), bg="#f4f4f8").pack(side="left")
        tk.Label(head, text="6.0", bg="#f4f4f8", fg="#666").pack(side="right")
        tk.Label(root, text="Chọn mini game. Công cụ dùng game đang mở.",
                 bg="#f4f4f8", fg="#666").pack(anchor="w", padx=20)

        cards = tk.Frame(root, bg="#f4f4f8")
        cards.pack(fill="x", padx=16, pady=12)
        self.cards = {}
        for i, (key, (name, sub)) in enumerate(MODES.items()):
            c = tk.Frame(cards, bg="white", highlightthickness=2,
                         highlightbackground="#ddd", cursor="hand2")
            c.grid(row=0, column=i, padx=6, sticky="nsew")
            cards.columnconfigure(i, weight=1)
            tk.Label(c, text=name, font=("Segoe UI", 13, "bold"), bg="white").pack(pady=(24, 2))
            tk.Label(c, text=sub, bg="white", fg="#777").pack(pady=(0, 20))
            for w in [c] + list(c.winfo_children()):
                w.bind("<Button-1>", lambda e, k=key: self.select(k))
            self.cards[key] = c
        self.select("turtle")

        self.lbl_status = tk.Label(root, text="Đã dừng", fg="#b32d3f",
                                   font=("Segoe UI", 14, "bold"), bg="#f4f4f8")
        self.lbl_status.pack(pady=4)
        self.lbl_hint = tk.Label(root, bg="#f4f4f8", fg="#777", wraplength=520)
        self.lbl_hint.pack()

        opt = tk.Frame(root, bg="#f4f4f8")
        opt.pack(pady=8)
        tk.Button(opt, text="Chọn vùng", command=self.calibrate).pack(side="left", padx=6)

        btns = tk.Frame(root, bg="#f4f4f8")
        btns.pack(fill="x", padx=16, pady=8)
        tk.Button(btns, text="Chạy (F8)", font=("Segoe UI", 12, "bold"),
                  command=self.start, height=2).pack(side="left", expand=True, fill="x", padx=6)
        tk.Button(btns, text="Dừng ngay (F9)", font=("Segoe UI", 12, "bold"), bg="#b32d3f",
                  fg="white", command=self.stop, height=2).pack(side="left", expand=True, fill="x", padx=6)

        keyboard.GlobalHotKeys({"<f8>": lambda: root.after(0, self.start),
                                "<f9>": lambda: root.after(0, self.stop)}).start()

    # ---------- UI ----------
    def select(self, key):
        self.mode.set(key)
        for k, c in self.cards.items():
            c.configure(highlightbackground="#1a73e8" if k == key else "#ddd")
        if hasattr(self, "lbl_hint"):
            self.lbl_hint.config(text=(
                "Rùa dùng ASD. Tắt bộ gõ tiếng Việt trước khi chơi. Chọn vùng: khoanh 3 dải mỏng "
                "ngay trên vạch đánh của làn A, S, D." if key == "turtle" else
                "Chọn vùng: khoanh cả thanh ngang (có vạch xanh dương, vùng xanh lá, vùng đỏ)."))

    def save(self):
        json.dump(self.cfg, open(CFG_FILE, "w"))

    def calibrate(self):
        if self.running:
            return
        self.root.withdraw()
        self.root.update()
        time.sleep(0.3)
        try:
            if self.mode.get() == "turtle":
                lanes = {}
                for ln in "ASD":
                    r = pick_region(self.root, f"Khoanh dải vạch đánh của làn {ln}")
                    if not r:
                        return
                    lanes[ln] = r
                self.cfg["turtle"] = lanes
            else:
                r = pick_region(self.root, "Khoanh thanh ngang của boss (vạch + vùng xanh/đỏ)")
                if not r:
                    return
                self.cfg["boss"] = r
            self.save()
        finally:
            self.root.deiconify()

    def start(self):
        if self.running:
            return
        key = self.mode.get()
        if key not in self.cfg:
            messagebox.showinfo("ToolAuto", "Bấm 'Chọn vùng' trước.")
            return
        self.running = True
        self.lbl_status.config(text="Đang chạy", fg="#1a8a4a")
        target = self.turtle_loop if key == "turtle" else self.boss_loop
        threading.Thread(target=target, daemon=True).start()

    def stop(self):
        self.running = False
        self.lbl_status.config(text="Đã dừng", fg="#b32d3f")

    # ---------- Rùa: nhịp A/S/D ----------
    def turtle_loop(self):
        lanes = self.cfg["turtle"]
        base = {}
        active = {ln: False for ln in lanes}
        last = {ln: 0.0 for ln in lanes}
        with mss.mss() as sct:
            while self.running:
                now = time.perf_counter()
                for ln, reg in lanes.items():
                    img = grab(sct, reg)
                    if ln not in base:
                        base[ln] = img.copy()
                        continue
                    diff = np.abs(img - base[ln]).sum(axis=2) > 90
                    n = diff.sum()
                    has_note = n > diff.size * 0.10
                    if has_note:
                        px = img[diff]  # BGR
                        b, g, r = px[:, 0].mean(), px[:, 1].mean(), px[:, 2].mean()
                        bad = r > 165 and r > g * 1.5 and r > b * 1.5  # nốt đỏ = bẫy
                        if not active[ln] and not bad and now - last[ln] >= 0.12:
                            k = ln.lower()
                            kb.press(k)
                            time.sleep(0.025)
                            kb.release(k)
                            last[ln] = now
                        active[ln] = True
                    else:
                        active[ln] = False
                        base[ln] = (base[ln] * 0.9 + img * 0.1).astype(np.int16)
                time.sleep(0.005)

    # ---------- Enzo / Long Điếu Hải: click khi vạch vào vùng xanh ----------
    def boss_loop(self):
        reg = self.cfg["boss"]
        locked, lock_t, last_hit = False, 0.0, 0.0
        prev_x, prev_t = None, 0.0
        with mss.mss() as sct:
            while self.running:
                img = grab(sct, reg)
                b, g, r = img[..., 0], img[..., 1], img[..., 2]
                h = img.shape[0]
                blue = (b > 150) & (b > r + 80) & (b > g + 20)
                green = (g > 90) & (g > r + 40) & (g > b + 30)
                red = (r > 140) & (r > g + 60) & (r > b + 50)

                def cols(mask, frac):
                    idx = np.where(mask.sum(axis=0) > h * frac)[0]
                    return (idx.min(), idx.max()) if idx.size else None

                bl, gr, rd = cols(blue, 0.5), cols(green, 0.2), cols(red, 0.2)
                now = time.perf_counter()
                if bl and gr:
                    x = (bl[0] + bl[1]) / 2
                    if prev_x is not None and now > prev_t:
                        x += (x - prev_x) / (now - prev_t) * 0.04  # bù độ trễ ~40ms
                    prev_x, prev_t = (bl[0] + bl[1]) / 2, now
                    pad = (gr[1] - gr[0]) * 0.2
                    in_zone = gr[0] - pad <= x <= gr[1] + pad
                    in_bad = bool(rd) and rd[0] - 3 <= x <= rd[1] + 3
                    if locked and (not in_zone or now - lock_t > 0.6):
                        locked = False
                    if in_zone and not in_bad and not locked and now - last_hit >= 0.035:
                        ms.click(mouse.Button.left)
                        locked, lock_t, last_hit = True, now, now
                time.sleep(0.004)


if __name__ == "__main__":
    r = tk.Tk()
    App(r)
    r.mainloop()
