# Dotfiles

> Carbon copy of my dev environment: **i3 + tmux + Neovim + Oh My Zsh**
>
> "No tabs, no animations, no bloat. Works with tmux + i3."

A lean, keyboard-driven development environment built around **tmux**, **Neovim**, **i3wm**, and **Oh My Zsh**, all wearing the same **Gruvbox dark** coat.

---

## Quick Start

```bash
# Clone to a new machine
git clone https://github.com/assemblu/dotfiles.git ~/dotfiles

# Bootstrap: verify prerequisites, install OMZ if missing, symlink everything
cd ~/dotfiles && ./bootstrap.sh

# Or preview what would change:
./bootstrap.sh --diff

# Or copy files instead of symlinking:
./bootstrap.sh --copy
```

The bootstrap script handles:
1. **Prerequisite check**: verifies zsh, curl, git are installed (aborts with install instructions if any are missing)
2. **Oh My Zsh**: auto-installs via the official installer (`--unattended --keep-zshrc`) if not present
3. All shell/config files mirrored under `home/` → symlinked to `~/`
4. tmux-gruvbox plugin → auto-cloned if missing

**Requirements:** a machine with zsh, git, curl, tmux, and nvim installed. New panes/windows in tmux inherit the current pane's directory; nvim plugins are installed at their latest versions by lazy.nvim on first launch.

- **tmux handles windows**: Neovim never shows tabs (`showtabline = 0`)
- **i3 handles workspaces**: tmux sessions live inside i3 workspaces
- **Gruvbox everywhere**: consistent colors across i3 bar, tmux status line, Neovim theme, and X background
- **Keyboard-first**: Vim-style directional keys throughout all three layers
- **Minimal overhead**: no Neovim distros (LazyVim/NvChad), no LSP, no completion, no diagnostics. Just Telescope for finding things and mini.files for browsing
- **Config only**: machine-specific files (SSH config, plugin lockfiles, OEM-generated state) stay out of the repo

---

## Repo Structure

```
dotfiles/
├── README.md              this file
├── bootstrap.sh           one-command setup (symlink or copy)
├── .gitignore
└── home/                  mirrors $HOME - files at their target paths
    ├── .bashrc
    ├── .bash_logout
    ├── .zshrc
    ├── .zshenv
    ├── .zsh_profile
    ├── .profile
    ├── .tmux.conf
    ├── .fzf.zsh
    ├── .fzf.bash
    ├── .tmux-cht-languages
    ├── .tmux-cht-command
    ├── .config/
    │   ├── i3/config
    │   ├── i3blocks/config
    │   ├── nvim/
    │   │   └── init.lua
    │   └── gtk-3.0/
    │       └── settings.ini
    └── .local/bin/
        ├── tmux-sessionizer
        ├── tmux-cht.sh
        └── scrot-clip
```

---

## i3 Window Manager

**Config:** `home/.config/i3/config` → `~/.config/i3/config`

### Keybindings

| Key | Action |
|---|---|
| `$mod+Return` | Open terminal |
| `$mod+d` | `dmenu_run` (app launcher) |
| `$mod+Shift+s` | Screenshot area → clipboard (`scrot-clip`) |
| `$mod+{j,k,l,;}` | Focus left / down / up / right |
| `$mod+Shift+{j,k,l,;}` | Move window left / down / up / right |
| `$mod+h` / `$mod+v` | Split horizontal / vertical |
| `$mod+f` | Toggle fullscreen |
| `$mod+s` / `$mod+w` / `$mod+e` | Layout: stacking / tabbed / toggle split |
| `$mod+1-0` | Switch to workspace 1-10 |
| `$mod+Shift+1-0` | Move window to workspace |
| `$mod+o` | Lock screen (i3lock) |
| `$mod+r` → `{j,k,l,;}` | Resize mode (Vim keys) |

> `$mod` = Super (Windows) key.

### i3blocks Status Bar

Runs `i3blocks` at the bottom. Six blocks showing system status:

| Block | Data | Interval |
|---|---|---|
| `time` | Date & time | 1s |
| `disk` | Disk usage `/` | 60s |
| `mem` | Memory usage | 10s |
| `load` | Load average | 5s |
| `CPU` | CPU temp (k10temp) | 5s |

### Appearance

Full **Gruvbox dark** palette:

```
bg=#282828    red=#cc241d    green=#98971a    yellow=#d79921
blue=#458588  purple=#b16286 aqua=#689d68     gray=#a89984
```

### Auto-started

- `dex --autostart` (XDG autostart)
- `xss-lock` → `i3lock` (screen locker)
- `nm-applet` (network manager)
- `xsetroot -solid "#282828"` (solid background)
- `xrandr`: DP-2 rotated right, DP-4 rotated left

---

## Tmux

**Config:** `home/.tmux.conf` → `~/.tmux.conf`

Minimal config, appearance delegated to **tmux-gruvbox** plugin. Key deviations from stock:

| Setting | Value |
|---|---|
| Prefix | `C-a` (instead of `C-b`) |
| Terminal | `screen-256color` with true-color override |
| Escape time | `0` (no delay) |
| Base index | `1` |
| Mode keys | `vi` |
| Clipboard (copy mode) | `xclip` → system clipboard |
| New panes/windows | Start in current pane's directory (`#{pane_current_path}`) |

### Custom Keybindings

| Key | Action |
|---|---|
| `C-a` (prefix) | Send prefix |
| `C-a r` | Reload config |
| `C-a k/j/h/l` (after prefix) | Select pane up/down/left/right |
| `C-a f` | **tmux-sessionizer**: fuzzy-find project and create/switch session |
| `C-a i` | **cht.sh**: interactive cheatsheet lookup |
| `C-a D` | Open/create `TODO.md` in project root or `~/todo.md` |

### Scripts

| Script | Purpose |
|---|---|
| `tmux-sessionizer` | Fuzzy-find projects. Scans `~/dev`, `~/work`, etc. |
| `tmux-cht.sh` | Interactive cheatsheet via cht.sh with language/command filtering |

### Plugin: tmux-gruvbox

Cloned at bootstrap to `~/.tmux/plugins/tmux-gruvbox/` from [egel/tmux-gruvbox](https://github.com/egel/tmux-gruvbox).

---

## Neovim

**Config:** `home/.config/nvim/init.lua` → `~/.config/nvim/init.lua`

Single-file Lua config, bootstraps `lazy.nvim` automatically on first launch.

### Keymaps

| Key | Action |
|---|---|
| `<leader>ff` | **Telescope** find files |
| `<leader>fg` | **Telescope** live grep |
| `<leader>fb` | Switch buffers |
| `<leader>fr` | Recent files |
| `<leader>f.` | Find hidden/dotfiles |
| `<leader>e` | **mini.files** toggle explorer |
| `[b` / `]b` | Previous / Next buffer |
| `<leader>bd` | Close buffer |
| `jk` (insert) | Escape |
| `<C-h/j/k/l>` | Navigate windows |
| `<leader>h` | Clear search highlights |
| `<C-f>` | Launch **tmux-sessionizer** from within nvim |

### Plugins (via lazy.nvim)

| Plugin | Purpose |
|---|---|
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy file finder & live grep |
| [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) | Colorscheme (hard contrast) |
| [mini.files](https://github.com/echasnovski/mini.files) | File explorer (Miller columns) |

No LSP, no completion, no diagnostics, just finding and editing files quickly.

Plugins are installed at their latest versions on first launch; the resulting `lazy-lock.json` is auto-generated and kept out of the repo.

---

## Shell Environment

### Startup chain

```
~/.profile           (login shell, sources .bashrc if bash)
  └─ ~/.bashrc       (non-login shell, sets PATH, launches zsh via exec)
       └─ ~/.zshrc   (oh-my-zsh, sources .zsh_profile)
            └─ ~/.zsh_profile  (PATH, aliases, functions, fzf, VIMRUNTIME)
```

**bash** is the default login shell. `~/.bashrc` `exec`s into zsh when available.
No `chsh` needed, works even when zsh is locally installed (not in `/etc/shells`).

`VIMRUNTIME` is auto-detected from the nvim binary location at shell startup: derived from `dirname(dirname($(command -v nvim)))/share/nvim/runtime`, resolved through symlinks, and only exported when that directory actually exists. Handles the official tarball (Linux/macOS), Homebrew, apt, AppImage, and Snap installs.

### PATH additions

```bash
~/.local/bin                  # personal scripts (tmux-sessionizer, etc.)
~/.local/scripts              # local scripts
/opt/nvim-linux-x86_64/bin    # Neovim
~/.cargo/env                  # Rust/Cargo
```

### Aliases & Functions

| Command | Definition |
|---|---|
| `ll`, `la`, `l` | `ls -alF`, `ls -A`, `ls -CF` |
| `catr <from> <to> [file]` | Print lines `<from>`-`<to>` of a file |
| `cat1Line <file>` | Print file with all newlines removed |

### GTK

Gruvbox-Dark theme, Hack Nerd Font Mono 11pt, Adwaita icons.

---

## Bootstrap on a Fresh Machine

```bash
# 1. Install prerequisites
sudo apt install git tmux neovim i3 i3blocks rofi scrot \
  xclip xss-lock nm-applet fzf zsh curl

# 2. Clone
git clone https://github.com/assemblu/dotfiles.git ~/dotfiles

# 3. Bootstrap (checks zsh/curl/git, installs Oh My Zsh if missing, symlinks configs)
cd ~/dotfiles && ./bootstrap.sh

# 4. Install Neovim plugins
nvim --headless "+Lazy! sync" +qa
```

---

## Stack Versions (reference)

| Tool | Version |
|---|---|
| **tmux** | 3.4 |
| **Neovim** | 0.12.3 |
| **i3** | 4.x |
| **Zsh** | 5.9 |
| **Bash** | Ubuntu default |

---


