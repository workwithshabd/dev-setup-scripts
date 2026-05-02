#!/usr/bin/env bash
set -euo pipefail

# -------- CONFIG --------
GO_DIR="/usr/local/go"
GOPATH_DIR="$HOME/go"
GO_VERSION="1.22.5"

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

log(){ echo -e "${GREEN}[OK]${NC} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){ echo -e "${RED}[ERROR]${NC} $1"; }

# -------- OS DETECT --------
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    err "Unsupported OS"
    exit 1
fi

# -------- HELP --------
show_help() {
    echo ""
    echo "================================================="
    echo "              Go Setup CLI Manual"
    echo "================================================="
    echo ""

    echo "USAGE:"
    echo "  go-setup [command]"
    echo ""

    echo "COMMANDS:"
    echo "  -help        Show manual"
    echo "  -all         Full setup"
    echo "  -check       Quick check"
    echo "  -doctor      Diagnose issues"
    echo "  -clean       Remove Go"
    echo "  -reinstall   Clean + reinstall Go"
    echo ""

    echo "-------------------------------------------------"
    echo "QUICK START"
    echo "-------------------------------------------------"
    echo "go-setup -all"
    echo "go version"
    echo ""

    echo "-------------------------------------------------"
    echo "CREATE & RUN APP"
    echo "-------------------------------------------------"
    echo "mkdir myapp && cd myapp"
    echo "go mod init myapp"
    echo "echo 'package main; import \"fmt\"; func main(){fmt.Println(\"Hello Go\")}' > main.go"
    echo "go run main.go"
    echo ""

    echo "-------------------------------------------------"
    echo "BUILD"
    echo "-------------------------------------------------"
    echo "go build"
    echo "./myapp"
    echo ""

    echo "-------------------------------------------------"
    echo "COMMON COMMANDS"
    echo "-------------------------------------------------"
    echo "go run main.go"
    echo "go build"
    echo "go mod tidy"
    echo "go get <package>"
    echo ""

    echo "-------------------------------------------------"
    echo "TROUBLESHOOTING"
    echo "-------------------------------------------------"
    echo "export PATH=\$PATH:/usr/local/go/bin"
    echo "export GOPATH=\$HOME/go"
    echo ""
}

# -------- SUDO --------
ask_sudo() {
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

# -------- HELPERS --------
is_installed() { command -v "$1" >/dev/null 2>&1; }
dir_exists() { [[ -d "$1" ]]; }

# -------- INSTALL GO --------
install_go() {
    if is_installed go; then
        log "Go already installed"
        return
    fi

    warn "Installing Go..."

    if [[ "$OS" == "mac" ]]; then
        ARCH=$(uname -m)
        [[ "$ARCH" == "arm64" ]] && FILE="go${GO_VERSION}.darwin-arm64.tar.gz" || FILE="go${GO_VERSION}.darwin-amd64.tar.gz"
    else
        ARCH=$(uname -m)
        [[ "$ARCH" == "x86_64" ]] && FILE="go${GO_VERSION}.linux-amd64.tar.gz" || FILE="go${GO_VERSION}.linux-arm64.tar.gz"
    fi

    curl -LO "https://go.dev/dl/$FILE"

    sudo rm -rf "$GO_DIR"
    sudo tar -C /usr/local -xzf "$FILE"
    rm "$FILE"

    log "Go installed"
}

# -------- PATH SETUP --------
setup_path() {
    if ! grep -q '/usr/local/go/bin' ~/.zshrc 2>/dev/null; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
    fi

    if ! grep -q "$GOPATH_DIR/bin" ~/.zshrc 2>/dev/null; then
        echo "export GOPATH=$GOPATH_DIR" >> ~/.zshrc
        echo "export PATH=\$PATH:\$GOPATH/bin" >> ~/.zshrc
    fi

    export PATH=$PATH:/usr/local/go/bin:$GOPATH_DIR/bin
}

# -------- CLEAN --------
clean_go() {
    warn "Removing Go..."

    sudo rm -rf "$GO_DIR"
    rm -rf "$GOPATH_DIR"

    sed -i '' '/go\/bin/d' ~/.zshrc 2>/dev/null || true

    log "Go removed"
}

# -------- CHECK --------
check_all() {
    is_installed go && log "Go OK" || warn "Go missing"
}

# -------- DOCTOR --------
doctor() {
    echo ""
    echo "=========== Go Doctor ==========="
    echo ""

    FAIL=0

    command -v go >/dev/null && echo "[OK] Go installed" || { echo "[FAIL] Go missing"; FAIL=1; }

    echo "$PATH" | grep -q "/usr/local/go/bin" && echo "[OK] PATH" || { echo "[FAIL] Go not in PATH"; FAIL=1; }

    echo ""
    [[ $FAIL -eq 0 ]] && echo "✅ System looks good" || echo "❌ Issues detected"
}

# -------- MAIN --------
case "${1:-}" in
    -help) show_help ;;
    -check) check_all ;;
    -doctor) doctor ;;
    -clean) ask_sudo; clean_go ;;
    -reinstall)
        ask_sudo
        clean_go
        install_go
        setup_path
        ;;
    -all)
        ask_sudo
        install_go
        setup_path
        ;;
    *) show_help ;;
esac
