#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

MODE="${1:---link}"

announce() { echo "  → $1"; }
warn()   { echo "  ⚠  $1"; }
success() { echo "  ✓ $1"; }

system_to_repo() {
    local syspath="$1"
    local rel="${syspath#$HOME_DIR/}"

    if [[ "$rel" == .ssh/* ]]; then
        echo "ssh/${rel#.ssh/}"
        return
    fi

    echo "home/$rel"
}

repo_to_system() {
    local repopath="$1"

    if [[ "$repopath" == ssh/* ]]; then
        echo "$HOME_DIR/.ssh/${repopath#ssh/}"
        return
    fi

    echo "$HOME_DIR/${repopath#home/}"
}

link_file() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        return 0
    fi

    if [ -e "$dst" ]; then
        if [ -L "$dst" ]; then
            warn "Symlink $dst points elsewhere, overwriting"
        else
            warn "$dst exists, backing up to ${dst}.bak"
            mv "$dst" "${dst}.bak"
        fi
    fi

    ln -sf "$src" "$dst"
    success "Linked $dst → $src"
}

copy_file() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
        warn "$dst differs, backing up to ${dst}.bak"
        cp "$dst" "${dst}.bak"
    fi
    cp "$src" "$dst"
    success "Copied $src → $dst"
}

diff_file() {
    local src="$1" dst="$2"
    if [ ! -e "$dst" ]; then
        echo "  MISSING: $dst"
    elif [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        :
    elif ! cmp -s "$src" "$dst" 2>/dev/null; then
        echo "  DIFFERS: $dst"
        diff --color=always -u "$dst" "$src" 2>/dev/null | tail -n +3 || true
    fi
}

collect_file() {
    local dst="$1"
    local src="$2"
    local full_src="$DOTFILES_DIR/$src"

    if [ ! -e "$dst" ]; then
        return
    fi

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$full_src" ]; then
        return 0
    fi

    if [ ! -f "$full_src" ]; then
        echo "  NEW: $dst"
        echo "       → $src"
        mkdir -p "$(dirname "$full_src")"
        cp "$dst" "$full_src"
        success "Collected $src"
    elif ! cmp -s "$dst" "$full_src"; then
        echo "  MODIFIED: $dst"
        echo "       differs from $src"
        cp "$dst" "$full_src"
        success "Updated $src from system"
    fi
}

deploy_home_files() {
    local op="$1"
    while IFS= read -r -d '' f; do
        local relative="${f#$DOTFILES_DIR/home/}"
        local src="$f"
        local dst="$HOME_DIR/$relative"
        case "$op" in
            link) link_file "$src" "$dst" ;;
            copy) copy_file "$src" "$dst" ;;
            diff) diff_file "$src" "$dst" ;;
        esac
    done < <(find "$DOTFILES_DIR/home" -type f -print0)
}

deploy_ssh_files() {
    local op="$1"
    local src="$DOTFILES_DIR/ssh/config"
    local dst="$HOME_DIR/.ssh/config"
    [ -f "$src" ] || return
    case "$op" in
        link) link_file "$src" "$dst" ;;
        copy) copy_file "$src" "$dst" ;;
        diff) diff_file "$src" "$dst" ;;
    esac
}

deploy_tmux_plugins() {
    local tpm_dir="$HOME_DIR/.tmux/plugins/tmux-gruvbox"
    if [ ! -d "$tpm_dir" ]; then
        mkdir -p "$HOME_DIR/.tmux/plugins"
        announce "Cloning tmux-gruvbox..."
        git clone --depth=1 https://github.com/egel/tmux-gruvbox.git "$tpm_dir" 2>/dev/null && \
            success "tmux-gruvbox installed" || \
            warn "Could not clone tmux-gruvbox, do it manually:\n       git clone https://github.com/egel/tmux-gruvbox.git $tpm_dir"
    else
        success "tmux-gruvbox already installed"
    fi
}

collect_dotfiles() {
    echo "── Scanning system for dotfiles ──"

    local count_new=0
    local count_updated=0

    local scan_targets=()

    for name in .bashrc .bash_logout .zshrc .zshenv .zsh_profile .profile \
                .tmux.conf .fzf.zsh .fzf.bash \
                .tmux-cht-languages .tmux-cht-command; do
        scan_targets+=("$HOME_DIR/$name")
    done

    for name in i3/config i3blocks/config nvim/init.lua \
                gtk-3.0/settings.ini; do
        scan_targets+=("$HOME_DIR/.config/$name")
    done

    for name in tmux-sessionizer tmux-cht.sh scrot-clip; do
        scan_targets+=("$HOME_DIR/.local/bin/$name")
    done

    scan_targets+=("$HOME_DIR/.ssh/config")

    for syspath in "${scan_targets[@]}"; do
        local repopath
        repopath="$(system_to_repo "$syspath")"
        local full_repo="$DOTFILES_DIR/$repopath"

        if [ ! -e "$syspath" ]; then
            if [ -f "$full_repo" ]; then
                echo "  ORPHANED: $repopath (exists in repo but not on system)"
                warn "Remove with: git rm $repopath"
            fi
            continue
        fi

        if [ ! -f "$full_repo" ]; then
            echo "  NEW: $syspath"
            echo "       → $repopath"
            mkdir -p "$(dirname "$full_repo")"
            cp "$syspath" "$full_repo"
            success "Collected $repopath"
            count_new=$((count_new + 1))
        elif ! cmp -s "$syspath" "$full_repo" 2>/dev/null; then
            if [ -L "$syspath" ] && [ "$(readlink "$syspath")" = "$full_repo" ]; then
                continue
            fi
            echo "  MODIFIED: $syspath"
            echo "       differs from $repopath"
            cp "$syspath" "$full_repo"
            success "Updated $repopath"
            count_updated=$((count_updated + 1))
        fi
    done

    echo ""
    if [ "$count_new" -eq 0 ] && [ "$count_updated" -eq 0 ]; then
        echo "  Nothing new to collect, repo is in sync with system."
    else
        echo "  Collected: $count_new new, $count_updated updated."
        echo "  Run 'git diff' to review changes, then commit."
    fi
}

clean_bak_files() {
    echo "── Cleaning .bak files ──"

    local count=0
    local tmpfile
    tmpfile="$(mktemp)"
    find "$HOME_DIR" -name '*.bak' -not -path '*/vaconia/*' -maxdepth 5 -print0 2>/dev/null > "$tmpfile" || true

    while IFS= read -r -d '' bak; do
        [ -z "$bak" ] && continue
        local original="${bak%.bak}"
        if [ -L "$original" ]; then
            local target
            target="$(readlink "$original")"
            if [[ "$target" == "$DOTFILES_DIR"* ]]; then
                rm "$bak"
                success "Removed $bak"
                count=$((count + 1))
            fi
        fi
    done < <(cat "$tmpfile")
    rm -f "$tmpfile"

    if [ "$count" -eq 0 ]; then
        echo "  No .bak files to clean."
    else
        echo "  Removed $count .bak file(s)."
    fi
}

case "$MODE" in
    --collect)
        echo "=== Dotfiles Collect ==="
        echo "Repo: $DOTFILES_DIR"
        echo "Home: $HOME_DIR"
        echo ""
        collect_dotfiles
        ;;

    --clean)
        echo "=== Dotfiles Clean ==="
        echo ""
        clean_bak_files
        ;;

    --link|--copy)
        echo "=== Dotfiles Bootstrap ($MODE) ==="
        echo "Repo: $DOTFILES_DIR"
        echo "Home: $HOME_DIR"
        echo ""

        echo "── Prerequisites ──"
        if ! command -v zsh >/dev/null 2>&1; then
            echo "  ⚠  zsh is required but not installed."
            echo "     Install it first:"
            echo "       Ubuntu/Debian: sudo apt install zsh"
            echo "       macOS:         brew install zsh"
            echo "       Fedora:        sudo dnf install zsh"
            echo ""
            echo "     Then re-run this script."
            exit 1
        fi
        success "zsh found at $(command -v zsh)"

        if ! command -v curl >/dev/null 2>&1; then
            echo "  ⚠  curl is required but not installed."
            echo "     Install it first:"
            echo "       Ubuntu/Debian: sudo apt install curl"
            echo "       macOS:         brew install curl"
            echo ""
            echo "     Then re-run this script."
            exit 1
        fi
        success "curl found"

        if ! command -v git >/dev/null 2>&1; then
            echo "  ⚠  git is required but not installed."
            echo "     Install it first:"
            echo "       Ubuntu/Debian: sudo apt install git"
            echo "       macOS:         brew install git"
            echo ""
            echo "     Then re-run this script."
            exit 1
        fi
        success "git found"

        echo ""
        echo "── Oh My Zsh ──"
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            announce "Installing Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
            success "Oh My Zsh installed"
        else
            success "Oh My Zsh already installed"
        fi

        echo ""
        echo "── Shell & Config ──"
        local op="link"
        [ "$MODE" = "--copy" ] && op="copy"
        deploy_home_files "$op"

        echo ""
        echo "── SSH ──"
        deploy_ssh_files "$op"

        echo ""
        echo "── Tmux Plugins ──"
        deploy_tmux_plugins

        echo ""
        echo "── Done ──"
        echo "Dotfiles installed! Restart your shell or:"
        echo "  source ~/.bashrc   # if using bash"
        echo "  source ~/.zshrc    # if using zsh"
        echo "  tmux source-file ~/.tmux.conf"
        echo "  i3-msg reload"
        echo ""
        echo "For Neovim: launch nvim and :Lazy will auto-install plugins"
        ;;

    --diff)
        echo "=== Dotfiles Diff ==="
        echo "Repo: $DOTFILES_DIR"
        echo "Home: $HOME_DIR"
        echo ""

        echo "── Shell & Config ──"
        deploy_home_files "diff"

        echo ""
        echo "── SSH ──"
        deploy_ssh_files "diff"
        ;;

    *)
        echo "Usage: ./bootstrap.sh [mode]"
        echo ""
        echo "Modes:"
        echo "  --link      Deploy: symlink repo → ~/ (default)"
        echo "  --copy      Deploy: copy repo → ~/"
        echo "  --diff      Show drift between repo and ~/"
        echo "  --collect   Import new/modified dotfiles from ~/ into repo"
        echo "  --clean     Remove .bak files from previous runs"
        exit 1
        ;;
esac
