#!/bin/bash

set -e

SETUP_MARKER=".mysql_setup_done"
MYSQL_ROOT_PASSWORD="rootuser"

# ---------- HELP ----------

show_help() {
cat <<EOF

MySQL First-Time Setup Script

USAGE:
  ./setup_mysql.sh          Run setup (only once)
  ./setup_mysql.sh --help   Show this help
  ./setup_mysql.sh --reset  Completely remove MySQL (DANGEROUS)

AFTER SETUP:

Login:
  mysql -u root -p
  password: rootuser

Manual Control:
  Start:    mysql.server start
  Stop:     mysql.server stop
  Restart:  mysql.server restart

Auto-start:
  Enable:   brew services start mysql
  Disable:  brew services stop mysql

Check Status:
  brew services list

Change Password:
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'newpassword';

RESET (WARNING):
  --reset will DELETE MySQL, all databases, configs, and logs permanently.

EOF
}

# ---------- SUDO ----------

keep_sudo_alive() {
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

# ---------- RESET ----------

reset_mysql() {
  echo "⚠️  This will completely REMOVE MySQL and ALL data."
  read -p "Type 'DELETE' to confirm: " confirm

  if [[ "$confirm" != "DELETE" ]]; then
    echo "Aborted."
    exit 1
  fi

  echo "Stopping MySQL..."
  mysql.server stop || true
  brew services stop mysql || true

  echo "Uninstalling MySQL..."
  brew uninstall mysql || true
  brew cleanup

  echo "Removing data directories..."
  sudo rm -rf /usr/local/var/mysql
  sudo rm -rf /opt/homebrew/var/mysql

  echo "Removing config files..."
  sudo rm -f /etc/my.cnf
  sudo rm -f /usr/local/etc/my.cnf
  sudo rm -f /opt/homebrew/etc/my.cnf

  echo "Removing logs..."
  sudo rm -rf /usr/local/var/log/mysql*
  sudo rm -rf /opt/homebrew/var/log/mysql*

  echo "Removing setup marker..."
  rm -f "$SETUP_MARKER"

  echo "Reset complete. You can run setup again."
}

# ---------- VERIFY ----------

verify_setup() {
  echo "Verifying MySQL setup..."

  # Check server running
  if ! mysqladmin ping >/dev/null 2>&1; then
    echo "❌ MySQL server is not running."
    exit 1
  fi

  # Check root login + query
  if ! mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SELECT 1;" >/dev/null 2>&1; then
    echo "❌ Cannot login as root or execute queries."
    exit 1
  fi

  echo "✅ MySQL setup verified successfully."
}

# ---------- ARGUMENTS ----------

if [[ "$1" == "--help" ]]; then
  show_help
  exit 0
fi

if [[ "$1" == "--reset" ]]; then
  keep_sudo_alive
  reset_mysql
  exit 0
fi

# ---------- PREVENT RE-RUN ----------

if [[ -f "$SETUP_MARKER" ]]; then
  echo "MySQL already configured. Setup will not run again."
  echo "Use --help to see commands."
  exit 1
fi

# ---------- SETUP ----------

echo "Requesting sudo access..."
keep_sudo_alive

echo "Installing MySQL if needed..."
if ! command -v mysql >/dev/null 2>&1; then
  brew install mysql
else
  echo "MySQL already installed."
fi

echo "Starting MySQL..."
mysql.server start || true

echo "Waiting for MySQL..."
sleep 5

echo "Setting root password..."

mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo "Cleaning default insecure settings..."

mysql -u root -p${MYSQL_ROOT_PASSWORD} <<EOF
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# ---------- VERIFY ----------

verify_setup

# ---------- MARK COMPLETE ----------

touch "$SETUP_MARKER"

echo
echo "🎉 Setup completed successfully."
echo
show_help
