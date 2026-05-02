#!/usr/bin/env bash
set -euo pipefail

CARGO_ENV="$HOME/.cargo/env"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

log(){ echo -e "${GREEN}[OK]${NC} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){ echo -e "${RED}[ERROR]${NC} $1"; }

# -------- SUDO --------
ask_sudo() {
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

# -------- HELP --------
show_help() {
    echo ""
    echo "=========== Rust Setup CLI v4 ==========="
    echo ""
    echo "Commands:"
    echo "  -all     Full setup"
    echo "  -check   Quick check"
    echo "  -doctor  Diagnose + auto-fix"
    echo "  -init    Create project"
    echo ""
    echo "Run Rust:"
    echo "  cargo new app && cd app && cargo run"
    echo ""
}

# -------- HELPERS --------
is_installed() { command -v "$1" >/dev/null 2>&1; }

# -------- PATH FIX --------
fix_path() {
    if ! echo "$PATH" | grep -q "/usr/local/bin"; then
        warn "Fixing PATH..."
        echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
        export PATH="/usr/local/bin:$PATH"
    fi

    if ! echo "$PATH" | grep -q ".cargo"; then
        warn "Adding Cargo to PATH..."
        echo 'source $HOME/.cargo/env' >> ~/.zshrc
        source "$CARGO_ENV"
    fi
}

# -------- HOMEBREW --------
install_brew() {
    if is_installed brew; then
        log "Homebrew OK"
    else
        warn "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
}

# -------- RUST --------
install_rust() {
    if is_installed rustc; then
        log "Rust already installed"
        return
    fi

    warn "Installing Rust (rustup)..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$CARGO_ENV"
    log "Rust installed"
}

# -------- VSCODE --------
check_vscode_app() {
    [[ -d "/Applications/Visual Studio Code.app" ]]
}

install_vscode() {
    if check_vscode_app; then
        log "VS Code installed"
    else
        warn "Installing VS Code..."
        install_brew
        brew install --cask visual-studio-code
    fi
}

fix_vscode_cli() {
    BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    TARGET="/usr/local/bin/code"

    if is_installed code; then
        log "VS Code CLI OK"
        return
    fi

    if check_vscode_app; then
        warn "Fixing VS Code CLI..."
        sudo rm -f "$TARGET"
        sudo ln -s "$BIN" "$TARGET"
    fi
}

install_extensions() {
    if ! is_installed code; then
        warn "Skipping extensions"
        return
    fi

    for ext in rust-lang.rust-analyzer; do
        if code --list-extensions | grep -q "$ext"; then
            log "$ext installed"
        else
            code --install-extension "$ext"
        fi
    done
}

# -------- RUSTLINGS --------
install_rustlings() {
    read -p "Install Rustlings? (y/n): " CHOICE
    if [[ "$CHOICE" != "y" ]]; then return; fi

    if cargo install --list | grep -q rustlings; then
        log "Rustlings already installed"
    else
        cargo install rustlings
    fi

    if [[ ! -d "$HOME/rustlings" ]]; then
        git clone https://github.com/rust-lang/rustlings "$HOME/rustlings"
    fi

    log "Rustlings ready"
}

# -------- PROJECT --------
init_project() {
    read -p "Project name (default: rust-app): " NAME
    NAME=${NAME:-rust-app}
    cargo new "$NAME"
    log "Project created: $NAME"
}

# -------- CHECK --------
check_all() {
    echo ""
    is_installed rustc && log "rustc OK" || warn "rustc missing"
    is_installed cargo && log "cargo OK" || warn "cargo missing"
    check_vscode_app && log "VS Code app OK" || warn "VS Code missing"
    is_installed code && log "VS Code CLI OK" || warn "VS Code CLI missing"
    is_installed brew && log "Homebrew OK" || warn "Homebrew missing"
    echo ""
}

# -------- DOCTOR --------
doctor() {
    echo ""
    echo "=========== Rust Doctor (Auto Fix) ==========="
    echo ""

    FAIL=0

    command -v rustc >/dev/null && echo "[OK] rustc" || { echo "[FAIL] rustc missing"; FAIL=1; }
    command -v cargo >/dev/null && echo "[OK] cargo" || { echo "[FAIL] cargo missing"; FAIL=1; }

    fix_path
    fix_vscode_cli

    command -v code >/dev/null && echo "[OK] VS Code CLI" || { echo "[FAIL] CLI still broken"; FAIL=1; }

    echo ""
    [[ $FAIL -eq 0 ]] && echo "✅ System ready" || echo "❌ Issues found"
}

# -------- MAIN --------
case "${1:-}" in
    -help) show_help ;;
    -check) check_all ;;
    -doctor)
        ask_sudo
        doctor
        ;;
    -init) init_project ;;
    -all)
        ask_sudo
        install_rust
        install_vscode
        fix_path
        fix_vscode_cli
        install_extensions
        install_rustlings
        ;;
    *) show_help ;;
esac
