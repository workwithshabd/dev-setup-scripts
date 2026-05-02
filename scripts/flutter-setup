#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"

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
    echo "=========== Flutter Setup CLI v3 ==========="
    echo ""
    echo "Commands:"
    echo "  -all     Full setup"
    echo "  -check   Quick check"
    echo "  -doctor  Deep diagnostics + auto-fix"
    echo ""
}

# -------- HELPERS --------
is_installed() { command -v "$1" >/dev/null 2>&1; }

# -------- PATH FIX --------
fix_path() {
    if ! echo "$PATH" | grep -q "/usr/local/bin"; then
        warn "/usr/local/bin not in PATH → fixing"

        echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
        export PATH="/usr/local/bin:$PATH"

        log "PATH updated"
    fi
}

# -------- HOMEBREW --------
install_brew() {
    if is_installed brew; then
        log "Homebrew installed"
    else
        warn "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
        log "Homebrew installed"
    fi
}

# -------- XCODE --------
setup_xcode() {
    if xcode-select -p >/dev/null 2>&1; then
        log "Xcode CLI tools installed"
    else
        warn "Installing Xcode CLI..."
        xcode-select --install || true
    fi
}

# -------- FLUTTER --------
install_flutter() {
    if [[ -d "$FLUTTER_DIR" ]]; then
        log "Flutter already installed"
    else
        warn "Installing Flutter..."
        git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
    fi

    export PATH="$FLUTTER_DIR/bin:$PATH"

    if ! grep -q 'flutter/bin' ~/.zshrc 2>/dev/null; then
        echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
    fi
}

# -------- VSCODE APP --------
check_vscode_app() {
    [[ -d "/Applications/Visual Studio Code.app" ]]
}

# -------- FIX CLI --------
fix_vscode_cli() {
    VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    TARGET="/usr/local/bin/code"

    if ! check_vscode_app; then
        warn "VS Code app missing"
        return
    fi

    if is_installed code; then
        # check if broken
        if [[ ! -x "$(command -v code)" ]]; then
            warn "Broken VS Code CLI detected → fixing"
        else
            log "VS Code CLI OK"
            return
        fi
    fi

    warn "Fixing VS Code CLI..."

    sudo rm -f "$TARGET"
    sudo ln -s "$VSCODE_BIN" "$TARGET"

    if is_installed code; then
        log "VS Code CLI fixed"
    else
        err "Failed to fix CLI → use VS Code manual command"
    fi
}

# -------- INSTALL VSCODE --------
install_vscode() {
    if check_vscode_app; then
        log "VS Code installed"
    else
        warn "Installing VS Code..."
        install_brew
        brew install --cask visual-studio-code
        log "VS Code installed"
    fi
}

# -------- EXTENSIONS --------
install_extensions() {
    if ! is_installed code; then
        warn "Skipping extensions (code CLI missing)"
        return
    fi

    for ext in Dart-Code.dart-code Dart-Code.flutter; do
        if code --list-extensions | grep -q "$ext"; then
            log "$ext already installed"
        else
            code --install-extension "$ext"
            log "$ext installed"
        fi
    done
}

# -------- CHECK --------
check_all() {
    echo ""

    is_installed flutter && log "Flutter OK" || warn "Flutter missing"

    check_vscode_app && log "VS Code app OK" || warn "VS Code missing"

    is_installed code && log "VS Code CLI OK" || warn "VS Code CLI missing"

    is_installed brew && log "Homebrew OK" || warn "Homebrew missing"

    echo ""
}

# -------- DOCTOR --------
doctor() {
    echo ""
    echo "=========== Flutter Doctor (Auto Fix) ==========="
    echo ""

    FAIL=0

    command -v flutter >/dev/null && echo "[OK] Flutter" || { echo "[FAIL] Flutter missing"; FAIL=1; }

    if check_vscode_app; then
        echo "[OK] VS Code app"
    else
        echo "[FAIL] VS Code app missing"
        FAIL=1
    fi

    fix_path
    fix_vscode_cli

    if command -v code >/dev/null; then
        echo "[OK] VS Code CLI"
    else
        echo "[FAIL] VS Code CLI still broken"
        FAIL=1
    fi

    command -v brew >/dev/null && echo "[OK] Homebrew" || echo "[WARN] Homebrew missing"

    echo ""
    [[ $FAIL -eq 0 ]] && echo "✅ System fully fixed" || echo "❌ Issues remain"
}

# -------- MAIN --------
case "${1:-}" in
    -help) show_help ;;
    -check) check_all ;;
    -doctor)
        ask_sudo
        doctor
        ;;
    -all)
        ask_sudo
        setup_xcode
        install_brew
        install_flutter
        install_vscode
        fix_path
        fix_vscode_cli
        install_extensions
        ;;
    *) show_help ;;
esac
