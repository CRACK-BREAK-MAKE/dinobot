#!/bin/bash
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${CYAN} ___  ___ _  _  ___    ___  _   _ _  _ _ ${NC}"
echo -e "${CYAN}|   \\|_ _| \\| |/ _ \\  | _ \\| | | | \\| | |${NC}"
echo -e "${CYAN}| |) || || .\` | (_) | |   /| |_| | .\` |_|${NC}"
echo -e "${CYAN}|___/|___|_|\\_|\\___/  |_|_\\ \\___/|_|\\_(_)${NC}"
echo ""
echo -e "${GREEN}Modern Terminal Edition - Installer${NC}"
echo ""

if ! command -v python3 &>/dev/null; then
    echo -e "${RED}[ERR] python3 not found. Install Python 3 first.${NC}"; exit 1
fi
echo -e "${GREEN}[ok]${NC} Python 3 found"

if ! command -v tmux &>/dev/null; then
    if command -v brew &>/dev/null; then
        echo -e "${YELLOW}[..]${NC} Installing tmux via brew..."
        brew install tmux; echo -e "${GREEN}[ok]${NC} tmux installed"
    else
        echo -e "${RED}[ERR] tmux not found. Install: brew install tmux${NC}"; exit 1
    fi
else
    echo -e "${GREEN}[ok]${NC} tmux found"
fi

GAMES_DIR="$HOME/.claude/games"
mkdir -p "$GAMES_DIR"

cat > "$GAMES_DIR/dino.py" << 'GAME_EOF'
#!/usr/bin/env python3
"""Dino Run - Modern Terminal Edition. Play while Claude works!"""

import curses
import random
import time
import os
import math

# --- Config ---
SIGNAL_FILE = os.path.expanduser("~/.claude/games/.claude_done")
HIGHSCORE_FILE = os.path.expanduser("~/.claude/games/.highscore")
TICK_MS = 30
GRAVITY = 0.35
JUMP_VEL = -3.2
DINO_X = 10
GROUND_PAD = 3
DAY_LENGTH = 700

# --- Half-block characters ---
FULL = "\u2588"
UPPER = "\u2580"
LOWER = "\u2584"
SHADE_L = "\u2591"
SHADE_M = "\u2592"
SHADE_H = "\u2593"

# --- Pixel sprites (2 pixel rows = 1 char row via half-blocks) ---
PX_STAND = [
    [0,0,0,0,0,1,1,1,0,0],[0,0,0,0,1,1,1,1,1,0],
    [0,0,0,0,1,0,1,1,1,0],[0,0,0,0,1,1,1,1,1,1],
    [1,0,0,1,1,1,1,1,0,0],[1,1,1,1,1,1,1,1,0,0],
    [1,1,1,1,1,1,1,1,0,0],[0,1,1,1,1,1,1,1,0,0],
    [0,0,1,1,1,1,1,0,0,0],[0,0,0,1,1,1,1,0,0,0],
    [0,0,0,1,1,0,1,1,0,0],[0,0,0,1,0,0,0,1,0,0],
]
PX_RUN1 = [
    [0,0,0,0,0,1,1,1,0,0],[0,0,0,0,1,1,1,1,1,0],
    [0,0,0,0,1,0,1,1,1,0],[0,0,0,0,1,1,1,1,1,1],
    [1,0,0,1,1,1,1,1,0,0],[1,1,1,1,1,1,1,1,0,0],
    [1,1,1,1,1,1,1,1,0,0],[0,1,1,1,1,1,1,1,0,0],
    [0,0,1,1,1,1,1,0,0,0],[0,0,0,1,1,1,1,0,0,0],
    [0,0,0,0,1,0,1,1,0,0],[0,0,0,1,0,0,0,1,0,0],
]
PX_RUN2 = [
    [0,0,0,0,0,1,1,1,0,0],[0,0,0,0,1,1,1,1,1,0],
    [0,0,0,0,1,0,1,1,1,0],[0,0,0,0,1,1,1,1,1,1],
    [1,0,0,1,1,1,1,1,0,0],[1,1,1,1,1,1,1,1,0,0],
    [1,1,1,1,1,1,1,1,0,0],[0,1,1,1,1,1,1,1,0,0],
    [0,0,1,1,1,1,1,0,0,0],[0,0,0,1,1,1,1,0,0,0],
    [0,0,0,1,1,0,0,1,0,0],[0,0,0,0,1,0,1,0,0,0],
]
PX_DUCK = [
    [0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,1,1,1,0,0,0,0],[0,0,0,0,0,1,0,1,1,1,1,0,0],
    [1,0,0,0,0,1,1,1,1,1,1,1,0],[1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,0],[0,1,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,0,0,1,1,0,0,0,0],[0,0,0,1,0,0,0,0,1,0,0,0,0],
]
PX_CACTUS_SM = [[0,1,0],[0,1,0],[1,1,0],[1,1,1],[0,1,1],[0,1,0],[0,1,0],[0,1,0]]
PX_CACTUS_LG = [
    [0,0,1,0,0],[1,0,1,0,1],[1,0,1,0,1],[1,1,1,0,1],
    [0,1,1,1,1],[0,0,1,1,0],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0],[0,0,1,0,0],
]
PX_CACTUS_PAIR = [
    [0,1,0,0,0,1,0],[0,1,0,0,0,1,0],[0,1,0,0,1,1,0],[1,1,0,0,1,1,1],
    [1,1,0,0,0,1,1],[0,1,0,0,0,1,0],[0,1,0,0,0,1,0],[0,1,0,0,0,1,0],
]
PX_BIRD1 = [[0,1,0,0,0,0],[1,1,1,0,0,0],[0,1,1,1,1,1],[0,0,1,1,1,0]]
PX_BIRD2 = [[0,0,1,1,1,0],[0,1,1,1,1,1],[1,1,1,0,0,0],[0,1,0,0,0,0]]
PX_CLOUD_SM = [[0,0,1,1,0,0],[0,1,1,1,1,0],[1,1,1,1,1,1],[0,1,1,1,1,0]]
PX_CLOUD_LG = [
    [0,0,0,1,1,1,0,0,0],[0,0,1,1,1,1,1,0,0],
    [0,1,1,1,1,1,1,1,0],[1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1],[0,1,1,1,1,1,1,1,0],
]

# --- Half-block renderer ---
def halfblock(pixels):
    h = len(pixels); w = len(pixels[0]) if pixels else 0
    if h % 2: pixels = pixels + [[0] * w]; h += 1
    rows = []
    for y in range(0, h, 2):
        chars = []
        for x in range(w):
            t, b = pixels[y][x], pixels[y + 1][x]
            if t and b: chars.append(FULL)
            elif t: chars.append(UPPER)
            elif b: chars.append(LOWER)
            else: chars.append(" ")
        rows.append("".join(chars))
    return rows

def spr_h(px): return (len(px) + 1) // 2
def spr_w(px): return len(px[0]) if px else 0

SPR = {}
def _init_sprites():
    for name, px in [
        ("stand", PX_STAND), ("run1", PX_RUN1), ("run2", PX_RUN2), ("duck", PX_DUCK),
        ("cact_s", PX_CACTUS_SM), ("cact_l", PX_CACTUS_LG), ("cact_p", PX_CACTUS_PAIR),
        ("bird1", PX_BIRD1), ("bird2", PX_BIRD2),
        ("cloud_s", PX_CLOUD_SM), ("cloud_l", PX_CLOUD_LG),
    ]:
        SPR[name] = halfblock(px)
_init_sprites()

class Particle:
    __slots__ = ("x", "y", "vx", "vy", "life", "char")
    CHARS = [FULL, SHADE_H, SHADE_M, SHADE_L, ".", " "]
    def __init__(self, x, y, vx, vy, life=8):
        self.x, self.y = float(x), float(y)
        self.vx, self.vy = vx, vy
        self.life = life; self.char = self.CHARS[0]
    def tick(self):
        self.x += self.vx; self.y += self.vy; self.vy += 0.08; self.life -= 1
        idx = min(len(self.CHARS) - 1, (len(self.CHARS) * (8 - self.life)) // 8)
        self.char = self.CHARS[idx]; return self.life > 0

def gen_mountains(length, min_h, max_h, smooth=4):
    h = random.randint(min_h, max_h); heights = []
    for _ in range(length):
        h += random.choice([-1, -1, 0, 0, 0, 0, 1, 1])
        h = max(min_h, min(max_h, h)); heights.append(h)
    for _ in range(smooth):
        heights = [sum(heights[max(0,i-1):min(len(heights),i+2)]) // min(3, len(heights)) for i in range(len(heights))]
    return heights

COLOR_DEFS = {
    "day": {
        "dino":(curses.COLOR_WHITE,-1),"ground":(curses.COLOR_GREEN,-1),
        "obstacle":(curses.COLOR_RED,-1),"cloud":(curses.COLOR_WHITE,-1),
        "score":(curses.COLOR_YELLOW,-1),"claude":(curses.COLOR_MAGENTA,-1),
        "mtn_far":(curses.COLOR_BLUE,-1),"mtn_near":(curses.COLOR_CYAN,-1),
        "sky":(curses.COLOR_CYAN,-1),"particle":(curses.COLOR_YELLOW,-1),
        "ui_box":(curses.COLOR_WHITE,-1),"star":(curses.COLOR_YELLOW,-1),
    },
    "night": {
        "dino":(curses.COLOR_CYAN,-1),"ground":(curses.COLOR_GREEN,-1),
        "obstacle":(curses.COLOR_RED,-1),"cloud":(curses.COLOR_BLUE,-1),
        "score":(curses.COLOR_YELLOW,-1),"claude":(curses.COLOR_MAGENTA,-1),
        "mtn_far":(curses.COLOR_BLUE,-1),"mtn_near":(curses.COLOR_BLUE,-1),
        "sky":(curses.COLOR_BLUE,-1),"particle":(curses.COLOR_CYAN,-1),
        "ui_box":(curses.COLOR_CYAN,-1),"star":(curses.COLOR_WHITE,-1),
    },
}
COLOR_SLOTS = ["dino","ground","obstacle","cloud","score","claude",
               "mtn_far","mtn_near","sky","particle","ui_box","star"]

class Game:
    def __init__(self, stdscr):
        self.scr = stdscr; self.h = self.w = self.ground_y = 0
        self.dino_y = self.dino_vy = 0.0; self.ducking = False; self.duck_timer = 0
        self.state = "MENU"; self.score = 0; self.high_score = self._load_hs()
        self.speed = 1.0; self.frame = 0; self.ground_scroll = 0.0
        self.is_night = False; self.milestone_flash = 0
        self.obstacles = []; self.clouds = []; self.particles = []; self.stars = []
        self.mtn_far = gen_mountains(300, 2, 6)
        self.mtn_near = gen_mountains(300, 1, 4)
        self.mtn_offset_far = 0.0; self.mtn_offset_near = 0.0
        self.claude_done = False; self.claude_flash = 0
        curses.curs_set(0); self.scr.nodelay(True); self.scr.timeout(TICK_MS)
        self._setup_colors()

    def _setup_colors(self):
        if not curses.has_colors(): self.colors = False; return
        self.colors = True; curses.start_color(); curses.use_default_colors()
        self._apply_theme("day")
    def _apply_theme(self, theme):
        defs = COLOR_DEFS[theme]
        for i, slot in enumerate(COLOR_SLOTS, 1):
            fg, bg = defs[slot]; curses.init_pair(i, fg, bg)
        self.is_night = theme == "night"
    def _cp(self, slot, extra=0):
        if not self.colors: return extra
        return curses.color_pair(COLOR_SLOTS.index(slot) + 1) | extra
    def _load_hs(self):
        try:
            with open(HIGHSCORE_FILE) as f: return int(f.read().strip())
        except Exception: return 0
    def _save_hs(self):
        try:
            with open(HIGHSCORE_FILE, "w") as f: f.write(str(self.high_score))
        except Exception: pass
    def _addstr(self, y, x, s, attr=0):
        if y < 0 or y >= self.h or x >= self.w: return
        if x < 0: s = s[-x:]; x = 0
        try: self.scr.addnstr(y, x, s, max(0, self.w - x - 1), attr)
        except curses.error: pass
    def _draw_spr(self, lines, y, x, attr=0):
        for i, line in enumerate(lines): self._addstr(y + i, x, line, attr)
    def _centered(self, text, y, attr=0):
        self._addstr(y, (self.w - len(text)) // 2, text, attr)

    def run(self):
        while True:
            self.h, self.w = self.scr.getmaxyx()
            if self.h < 15 or self.w < 40:
                self.scr.erase(); self._centered("Terminal too small! (40x15 min)", self.h // 2)
                self.scr.refresh()
                if self.scr.getch() in (ord("q"), ord("Q")): return
                continue
            self.ground_y = self.h - GROUND_PAD
            self._input()
            if not self.claude_done and os.path.exists(SIGNAL_FILE):
                self.claude_done = True; self.claude_flash = 90
                try: os.remove(SIGNAL_FILE)
                except Exception: pass
            if self.claude_flash > 0: self.claude_flash -= 1
            if self.state == "PLAYING": self._update()
            self._render(); self.frame += 1

    def _input(self):
        duck_pressed = False; key = self.scr.getch()
        while key != -1:
            if key in (ord("q"), ord("Q")): raise SystemExit(0)
            if self.state in ("MENU", "GAMEOVER"):
                if key in (ord(" "), curses.KEY_UP): self._start()
            elif self.state == "PLAYING":
                if key in (ord("p"), ord("P")): self.state = "PAUSED"
                elif key in (ord(" "), curses.KEY_UP):
                    if self.dino_y >= 0:
                        self.dino_vy = JUMP_VEL; self.ducking = False; self.duck_timer = 0
                elif key == curses.KEY_DOWN: duck_pressed = True
            elif self.state == "PAUSED":
                if key in (ord("p"), ord("P"), ord(" ")): self.state = "PLAYING"
            key = self.scr.getch()
        if self.state == "PLAYING":
            if duck_pressed and self.dino_y >= 0: self.ducking = True; self.duck_timer = 10
            elif self.duck_timer > 0: self.duck_timer -= 1; self.ducking = self.duck_timer > 0
            else: self.ducking = False

    def _start(self):
        self.state = "PLAYING"; self.score = 0; self.speed = 1.0
        self.dino_y = self.dino_vy = 0.0; self.ducking = False; self.duck_timer = 0
        self.obstacles = []; self.clouds = []; self.particles = []
        self.ground_scroll = 0.0; self.milestone_flash = 0
        self.stars = [(random.randint(0, max(1, self.w - 1)), random.randint(1, max(2, self.ground_y - 10))) for _ in range(30)]
        self._apply_theme("day")

    def _spawn_dust(self, x, y, count=3):
        for _ in range(count):
            self.particles.append(Particle(x + random.uniform(-1, 1), y,
                random.uniform(-0.3, 0.3), random.uniform(-0.4, -0.1), life=random.randint(5, 10)))

    def _spawn_obstacle(self):
        r = random.random(); bird_ok = self.score > 250
        if bird_ok and r > 0.65: px = PX_BIRD1; y_off = random.choice([0, 3, 5]); bird = True
        elif r < 0.25: px = PX_CACTUS_SM; y_off = 0; bird = False
        elif r < 0.50: px = PX_CACTUS_LG; y_off = 0; bird = False
        else: px = PX_CACTUS_PAIR; y_off = 0; bird = False
        self.obstacles.append({"x": float(self.w), "px": px, "y_off": y_off, "bird": bird})

    def _update(self):
        was_airborne = self.dino_y < 0
        self.dino_vy += GRAVITY; self.dino_y += self.dino_vy
        if self.dino_y >= 0:
            self.dino_y = 0; self.dino_vy = 0
            if was_airborne: self._spawn_dust(DINO_X + 4, self.ground_y, 5)
        if self.dino_y >= 0 and not self.ducking and self.frame % 4 == 0:
            self._spawn_dust(DINO_X + 2, self.ground_y, 1)
        for obs in self.obstacles: obs["x"] -= self.speed
        self.obstacles = [o for o in self.obstacles if o["x"] > -15]
        for c in self.clouds: c["x"] -= self.speed * 0.2
        self.clouds = [c for c in self.clouds if c["x"] > -12]
        min_gap = max(20, 40 - int(self.speed * 5))
        rightmost = max((o["x"] for o in self.obstacles), default=-999)
        if rightmost < self.w - random.randint(min_gap, min_gap + 20): self._spawn_obstacle()
        cr = max((c["x"] for c in self.clouds), default=-999)
        if cr < self.w - random.randint(25, 55):
            kind = "cloud_l" if random.random() > 0.5 else "cloud_s"
            self.clouds.append({"x": float(self.w), "y": random.randint(2, max(3, self.ground_y - 12)), "kind": kind})
        self.ground_scroll = (self.ground_scroll + self.speed) % 8
        self.mtn_offset_far += self.speed * 0.08; self.mtn_offset_near += self.speed * 0.18
        self.particles = [p for p in self.particles if p.tick()]
        dpx = PX_DUCK if self.ducking else PX_STAND
        d_top = self.ground_y - spr_h(dpx) + int(self.dino_y)
        d_bot = self.ground_y - 1 + int(self.dino_y)
        d_left = DINO_X + 2; d_right = DINO_X + spr_w(dpx) - 2
        for obs in self.obstacles:
            ox = int(obs["x"]); px = obs["px"]
            o_top = self.ground_y - spr_h(px) - obs.get("y_off", 0)
            o_bot = o_top + spr_h(px) - 1; o_left = ox + 1; o_right = ox + spr_w(px) - 1
            if d_right > o_left and d_left < o_right and d_bot > o_top and d_top < o_bot:
                self.state = "GAMEOVER"
                for _ in range(15):
                    self.particles.append(Particle(DINO_X + 5, self.ground_y - 3 + int(self.dino_y),
                        random.uniform(-1.5, 1.5), random.uniform(-2, 0), life=12))
                if self.score > self.high_score: self.high_score = self.score; self._save_hs()
                return
        self.score += 1; self.speed = min(3.5, 1.0 + self.score / 350.0)
        cycle_pos = self.score % (DAY_LENGTH * 2)
        new_night = cycle_pos >= DAY_LENGTH
        if new_night != self.is_night: self._apply_theme("night" if new_night else "day")
        if self.score > 0 and self.score % 100 == 0: self.milestone_flash = 20
        if self.milestone_flash > 0: self.milestone_flash -= 1

    def _render(self):
        self.scr.erase()
        self._draw_mountains()
        if self.is_night:
            for i, (sx, sy) in enumerate(self.stars):
                if sy < self.ground_y - 8:
                    ch = "." if (self.frame + i * 7) % 30 < 20 else "*"
                    self._addstr(sy, sx % self.w, ch, self._cp("star"))
        for c in self.clouds:
            self._draw_spr(SPR[c["kind"]], c["y"], int(c["x"]), self._cp("cloud"))
        self._draw_ground()
        for obs in self.obstacles:
            if obs.get("bird"): key = "bird1" if self.frame % 16 < 8 else "bird2"
            else:
                px = obs["px"]
                if px is PX_CACTUS_SM: key = "cact_s"
                elif px is PX_CACTUS_LG: key = "cact_l"
                elif px is PX_CACTUS_PAIR: key = "cact_p"
                else: key = "cact_s"
            oy = self.ground_y - len(SPR[key]) - obs.get("y_off", 0)
            self._draw_spr(SPR[key], oy, int(obs["x"]), self._cp("obstacle"))
        show = not (self.state == "GAMEOVER" and self.frame % 8 < 4)
        if show:
            if self.ducking: key = "duck"
            elif self.dino_y < -0.5: key = "stand"
            elif self.frame % 8 < 4: key = "run1"
            else: key = "run2"
            dy = self.ground_y - len(SPR[key]) + int(self.dino_y)
            self._draw_spr(SPR[key], dy, DINO_X, self._cp("dino", curses.A_BOLD))
        for p in self.particles:
            self._addstr(int(p.y), int(p.x), p.char, self._cp("particle"))
        self._draw_ui()
        if self.state == "MENU": self._draw_menu()
        elif self.state == "GAMEOVER": self._draw_gameover()
        elif self.state == "PAUSED": self._draw_paused()
        if self.claude_done:
            msg = f" {FULL} CLAUDE IS DONE! Press Q to exit {FULL} "
            flash_on = self.claude_flash == 0 or self.claude_flash % 6 < 4
            if flash_on:
                self._addstr(0, 2, msg, self._cp("claude", curses.A_BOLD | curses.A_BLINK))
        self.scr.refresh()

    def _draw_mountains(self):
        gy = self.ground_y; attr_f = self._cp("mtn_far"); off = int(self.mtn_offset_far)
        for x in range(self.w - 1):
            mi = (x + off) % len(self.mtn_far); h = self.mtn_far[mi]
            for row in range(h):
                y = gy - 1 - row
                if 0 <= y < self.h:
                    self._addstr(y, x, UPPER if row == h - 1 else SHADE_L, attr_f)
        attr_n = self._cp("mtn_near"); off2 = int(self.mtn_offset_near)
        for x in range(self.w - 1):
            mi = (x + off2) % len(self.mtn_near); h = self.mtn_near[mi]
            for row in range(h):
                y = gy - 1 - row
                if 0 <= y < self.h:
                    self._addstr(y, x, UPPER if row == h - 1 else SHADE_M, attr_n)

    def _draw_ground(self):
        gy = self.ground_y; attr = self._cp("ground", curses.A_BOLD)
        self._addstr(gy, 0, (FULL * self.w)[:self.w - 1], attr)
        pat2 = SHADE_H + SHADE_M + SHADE_L + " "
        row2 = (pat2 * ((self.w // 4) + 2)); off = int(self.ground_scroll) % len(pat2)
        self._addstr(gy + 1, 0, row2[off:off + self.w - 1], self._cp("ground"))
        pat3 = "  .     '   .  .    `  "
        off3 = int(self.ground_scroll * 0.6) % len(pat3)
        self._addstr(gy + 2, 0, (pat3 * 5)[off3:off3 + self.w - 1], self._cp("ground"))

    def _draw_ui(self):
        c_score = self._cp("score", curses.A_BOLD); c_box = self._cp("ui_box")
        stxt = f" SCORE {self.score:05d} "; htxt = f" HI {self.high_score:05d} "
        if self.milestone_flash > 0 and self.milestone_flash % 4 < 2:
            c_score = self._cp("claude", curses.A_BOLD)
        sx = self.w - len(stxt) - 2; hx = sx - len(htxt) - 1
        self._addstr(0, hx, LOWER * (len(htxt) + len(stxt) + 3), c_box)
        self._addstr(1, hx, htxt, c_box); self._addstr(1, sx, stxt, c_score)
        bar_max = 12; bar_fill = int((self.speed / 3.5) * bar_max)
        bar = FULL * bar_fill + SHADE_L * (bar_max - bar_fill)
        self._addstr(2, sx, f" SPD [{bar}]", self._cp("ground"))
        icon = " *" if self.is_night else " o"
        self._addstr(2, hx, icon, self._cp("star", curses.A_BOLD))

    def _draw_menu(self):
        cy = self.h // 2 - 6; c_title = self._cp("score", curses.A_BOLD)
        c_sub = self._cp("dino", curses.A_BOLD); c_dim = self._cp("cloud")
        title = [
            " ___  ___ _  _  ___    ___  _   _ _  _ _ ",
            "|   \\|_ _| \\| |/ _ \\  | _ \\| | | | \\| | |",
            "| |) || || .` | (_) | |   /| |_| | .` |_|",
            "|___/|___|_|\\_|\\___/  |_|_\\ \\___/|_|\\_(_)",
        ]
        for i, line in enumerate(title): self._centered(line, cy + i, c_title)
        key = "run1" if self.frame % 16 < 8 else "run2"
        self._draw_spr(SPR[key], cy + 6, (self.w - 10) // 2, c_sub)
        self._centered("Press SPACE to start", cy + 13, c_sub)
        self._centered(SHADE_M + " SPACE/UP: Jump  " + SHADE_M + " DOWN: Duck  " + SHADE_M + " P: Pause  " + SHADE_M + " Q: Quit " + SHADE_M, cy + 15, c_dim)
        if self.high_score > 0: self._centered(f"High Score: {self.high_score}", cy + 17, self._cp("score"))

    def _draw_gameover(self):
        cy = self.h // 2 - 3; box_w = 32; bx = (self.w - box_w) // 2
        self._addstr(cy - 1, bx, LOWER * box_w, self._cp("ui_box"))
        for row in range(7):
            self._addstr(cy + row, bx, FULL, self._cp("ui_box"))
            self._addstr(cy + row, bx + box_w - 1, FULL, self._cp("ui_box"))
        self._addstr(cy + 7, bx, UPPER * box_w, self._cp("ui_box"))
        self._centered("G A M E   O V E R", cy + 1, self._cp("obstacle", curses.A_BOLD))
        self._centered(f"Score: {self.score:05d}", cy + 3, self._cp("score", curses.A_BOLD))
        if self.score >= self.high_score and self.score > 0:
            self._centered("NEW HIGH SCORE!", cy + 4, self._cp("claude", curses.A_BOLD))
        self._centered("SPACE: Restart  Q: Quit", cy + 6, self._cp("cloud"))

    def _draw_paused(self):
        cy = self.h // 2 - 2; box_w = 28; bx = (self.w - box_w) // 2
        self._addstr(cy - 1, bx, LOWER * box_w, self._cp("ui_box"))
        for row in range(5):
            self._addstr(cy + row, bx, FULL, self._cp("ui_box"))
            self._addstr(cy + row, bx + box_w - 1, FULL, self._cp("ui_box"))
        self._addstr(cy + 5, bx, UPPER * box_w, self._cp("ui_box"))
        self._centered("P A U S E D", cy + 1, self._cp("score", curses.A_BOLD))
        self._centered("P: Resume   Q: Quit", cy + 3, self._cp("cloud"))

def main(stdscr):
    game = Game(stdscr)
    try: game.run()
    except (SystemExit, KeyboardInterrupt): pass

if __name__ == "__main__":
    curses.wrapper(main)
GAME_EOF
chmod +x "$GAMES_DIR/dino.py"
echo -e "${GREEN}[ok]${NC} Installed dino.py"

cat > "$GAMES_DIR/play.sh" << 'LAUNCHER_EOF'
#!/bin/bash
if [ -z "$TMUX" ]; then
    echo "Not inside tmux. Starting directly..."
    python3 ~/.claude/games/dino.py; exit $?
fi
tmux display-popup -E -w 80% -h 80% -T " DINO RUN! " "python3 $HOME/.claude/games/dino.py"
LAUNCHER_EOF
chmod +x "$GAMES_DIR/play.sh"
echo -e "${GREEN}[ok]${NC} Installed play.sh"

TMUX_CONF="$HOME/.tmux.conf"
DINO_BIND='bind g display-popup -E -w 80% -h 80% -T " DINO RUN! " "python3 $HOME/.claude/games/dino.py"'
if [ -f "$TMUX_CONF" ]; then
    if grep -qF "claude/games/dino.py" "$TMUX_CONF"; then
        echo -e "${GREEN}[ok]${NC} tmux keybinding already exists"
    else
        echo "" >> "$TMUX_CONF"
        echo "# Dino Run - Ctrl+B then G" >> "$TMUX_CONF"
        echo "$DINO_BIND" >> "$TMUX_CONF"
        echo -e "${GREEN}[ok]${NC} tmux keybinding added"
    fi
else
    echo "# Dino Run - Ctrl+B then G" > "$TMUX_CONF"
    echo "$DINO_BIND" >> "$TMUX_CONF"
    echo -e "${GREEN}[ok]${NC} tmux keybinding created"
fi
[ -n "$TMUX" ] && tmux source-file "$TMUX_CONF" 2>/dev/null && echo -e "${GREEN}[ok]${NC} tmux config reloaded"
[ -z "$TMUX" ] && echo -e "${YELLOW}[!!]${NC} Not inside tmux. After starting tmux, run: tmux source-file ~/.tmux.conf"

python3 << 'HOOK_EOF'
import json, os
path = os.path.expanduser("~/.claude/settings.json")
if os.path.exists(path):
    with open(path) as f: settings = json.load(f)
else:
    os.makedirs(os.path.dirname(path), exist_ok=True); settings = {}
hook = {"matcher": "", "hooks": [{"type": "command", "command": "touch ~/.claude/games/.claude_done"}]}
settings.setdefault("hooks", {}).setdefault("Notification", [])
exists = any(any(h.get("command") == "touch ~/.claude/games/.claude_done" for h in e.get("hooks", [])) for e in settings["hooks"]["Notification"])
if not exists:
    settings["hooks"]["Notification"].append(hook)
    with open(path, "w") as f: json.dump(settings, f, indent=2)
HOOK_EOF
echo -e "${GREEN}[ok]${NC} Claude Code notification hook configured"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Dino Run installed!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "  ${BOLD}How to play:${NC}"
echo ""
echo -e "  1. Run Claude Code inside tmux:"
echo -e "     ${YELLOW}tmux new -s claude${NC}"
echo -e "     ${YELLOW}claude${NC}"
echo ""
echo -e "  2. While Claude is working, press:"
echo -e "     ${CYAN}Ctrl+B${NC} then ${CYAN}G${NC}"
echo ""
echo -e "  3. Controls:"
echo -e "     ${BOLD}SPACE/UP${NC} Jump   ${BOLD}DOWN${NC} Duck"
echo -e "     ${BOLD}P${NC} Pause   ${BOLD}Q${NC} Quit"
echo ""
echo -e "  When Claude finishes, game shows:"
echo -e "     ${YELLOW}CLAUDE IS DONE! Press Q to exit${NC}"
echo ""
echo -e "  ${BOLD}Quick test:${NC}  ${YELLOW}python3 ~/.claude/games/dino.py${NC}"
echo ""
