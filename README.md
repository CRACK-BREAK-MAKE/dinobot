# dinobot

A terminal T-Rex runner that lives inside Claude Code - play while your AI thinks.

Why stare at a spinner when you could be jumping over cacti?

<p align="center">
<pre>
     ▄███▄
    ██ ████        ____
    █████████     |    |
█  ████           | |||
█████████    >>>  | |||    >>>     ~~
 █████████        |    |          ~~~~
  ████████        |____|         ~~~~~~
   ██  ██
</pre>
</p>

## Features

- **Half-block pixel rendering** - 2x vertical resolution for smooth sprites
- **Parallax mountain backgrounds** - two layers scrolling at different speeds
- **Day/night cycle** - color theme shifts as you play
- **Twinkling stars** during night
- **Dust particles** - kick up when running, burst on landing, explode on death
- **Score milestones** - flash every 100 points
- **Claude Code integration** - game flashes "CLAUDE IS DONE!" when your task finishes
- **tmux popup overlay** - game runs on top of Claude, dismiss/resume instantly

## Prerequisites

| Requirement | Install |
|---|---|
| macOS | (Terminal.app or iTerm2) |
| Python 3 | `brew install python` |
| tmux | `brew install tmux` |

## Getting Started

### 1. Clone

```bash
git clone https://github.tools.sap/I504180/dinobot.git
cd dinobot
```

### 2. Install

```bash
bash install-dino.sh
```

This single command does everything:

- Installs the game to `~/.claude/games/dino.py`
- Installs a tmux launcher to `~/.claude/games/play.sh`
- Adds a tmux keybinding (`Ctrl+B` then `D`) to `~/.tmux.conf`
- Adds a Claude Code notification hook to `~/.claude/settings.json`

Safe to run multiple times - it won't duplicate entries or overwrite existing config.

### 3. Play

Start Claude Code inside tmux:

```bash
tmux new -s claude
claude
```

Give Claude a long task. While it works, press:

```
Ctrl+B  then  D
```

The game pops up as an overlay. Claude keeps working underneath.

### 4. Controls

| Key | Action |
|---|---|
| `SPACE` / `UP` | Jump |
| `DOWN` | Duck |
| `P` | Pause |
| `Q` | Quit (back to Claude) |

### 5. When Claude finishes

The game flashes:

```
CLAUDE IS DONE! Press Q to exit
```

Press `Q` to dismiss the game and review Claude's output.
Press `Ctrl+B` then `D` again anytime to relaunch.

## Quick test (no tmux needed)

```bash
python3 ~/.claude/games/dino.py
```

## How it works

```
+-----------------+     +-------------------+     +------------------+
|  Claude Code    | --> |  Notification     | --> |  Signal file     |
|  finishes task  |     |  hook fires       |     |  .claude_done    |
+-----------------+     +-------------------+     +------------------+
                                                         |
                                                         v
+-----------------+     +-------------------+     +------------------+
|  Press Ctrl+B D | --> |  tmux popup       | --> |  Game reads      |
|  to play        |     |  opens game       |     |  signal, alerts  |
+-----------------+     +-------------------+     +------------------+
```

## Uninstall

```bash
rm -rf ~/.claude/games
```

Remove the tmux keybinding from `~/.tmux.conf` (the line containing `claude/games/dino.py`).

Remove the Notification hook from `~/.claude/settings.json` if desired.

## License

MIT
