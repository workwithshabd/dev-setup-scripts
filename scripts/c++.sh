#!/usr/bin/env bash
set -euo pipefail

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
    echo "=========== C++ Setup CLI ==========="
    echo ""
    echo "Commands:"
    echo "  -all     Full setup"
    echo "  -check   Quick check"
    echo "  -doctor  Diagnose + fix"
    echo ""
    echo "Run C++:"
    echo "  g++ main.cpp -o app && ./app"
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

# -------- COMPILER --------
install_compiler() {
    if is_installed g++; then
        log "g++ installed"
    else
        warn "Installing gcc..."
        install_brew
        brew install gcc
    fi
}

# -------- XCODE --------
setup_xcode() {
    if xcode-select -p >/dev/null 2>&1; then
        log "Xcode CLI tools OK"
    else
        warn "Installing Xcode CLI..."
        xcode-select --install || true
    fi
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

    for ext in ms-vscode.cpptools ms-vscode.cmake-tools; do
        if code --list-extensions | grep -q "$ext"; then
            log "$ext installed"
        else
            code --install-extension "$ext"
        fi
    done
}

# -------- SAMPLE --------
create_sample() {
    mkdir -p cpp-sample
    cat <<EOF > cpp-sample/main.cpp
#include <iostream>
using namespace std;

int main() {
    cout << "Hello, C++!" << endl;
    return 0;
}
EOF
    log "Sample project created: cpp-sample/"
}

# -------- CHECK --------
check_all() {
    echo ""
    is_installed g++ && log "g++ OK" || warn "g++ missing"
    is_installed clang && log "clang OK" || warn "clang missing"
    check_vscode_app && log "VS Code app OK" || warn "VS Code missing"
    is_installed code && log "VS Code CLI OK" || warn "VS Code CLI missing"
    is_installed brew && log "Homebrew OK" || warn "Homebrew missing"
    echo ""
}

# -------- DOCTOR --------
doctor() {
    echo ""
    echo "=========== C++ Doctor ==========="
    echo ""

    FAIL=0

    command -v g++ >/dev/null && echo "[OK] g++" || { echo "[FAIL] g++ missing"; FAIL=1; }

    command -v clang >/dev/null && echo "[OK] clang" || { echo "[FAIL] clang missing"; FAIL=1; }

    fix_path
    fix_vscode_cli

    command -v code >/dev/null && echo "[OK] VS Code CLI" || echo "[WARN] CLI missing"

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
    -all)
        ask_sudo
        setup_xcode
        install_brew
        install_compiler
        install_vscode
        fix_path
        fix_vscode_cli
        install_extensions
        create_sample
        ;;
    *) show_help ;;
esac
