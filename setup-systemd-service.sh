#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="unleash-the-fury.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
COMMAND_SCRIPT_PATH="/usr/local/bin/unleash-the-fury-command"

usage() {
  cat <<'EOF'
Usage: sudo ./setup-systemd-service.sh <command> [args...]

Installs and enables a oneshot systemd service named unleash-the-fury.service.
The provided command path and literal arguments are written into
/usr/local/bin/unleash-the-fury-command and executed on every boot.
EOF
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
  fi
}

require_systemd() {
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl is required but was not found." >&2
    exit 1
  fi
}

validate_command() {
  if [[ "$1" == */* ]]; then
    if ! command -v realpath >/dev/null 2>&1; then
      echo "realpath is required when using a command path." >&2
      exit 1
    fi

    if [[ ! -x "$1" ]]; then
      echo "Command is not executable: $1" >&2
      exit 1
    fi

    realpath "$1"
    return
  fi

  command -v -- "$1" 2>/dev/null || {
    echo "Command not found: $1" >&2
    exit 1
  }
}

write_command_script() {
  local quoted_args

  quoted_args="$(printf ' %q' "$@")"

  cat > "${COMMAND_SCRIPT_PATH}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

exec${quoted_args}
EOF

  chmod 0755 "${COMMAND_SCRIPT_PATH}"
}

write_service() {
  cat > "${SERVICE_PATH}" <<EOF
[Unit]
Description=Run the Unleash the Fury startup command
After=local-fs.target

[Service]
Type=oneshot
ExecStart=${COMMAND_SCRIPT_PATH}

[Install]
WantedBy=multi-user.target
EOF

  chmod 0644 "${SERVICE_PATH}"
}

enable_service() {
  systemctl daemon-reload

  if systemctl is-enabled --quiet "${SERVICE_NAME}" >/dev/null 2>&1; then
    systemctl start "${SERVICE_NAME}"
  else
    systemctl enable --now "${SERVICE_NAME}"
  fi
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  require_root
  require_systemd
  local resolved_command
  resolved_command="$(validate_command "$1")"

  shift
  write_command_script "${resolved_command}" "$@"
  write_service
  enable_service

  echo "Installed ${SERVICE_NAME}."
  printf 'Command:'
  printf ' %q' "${resolved_command}" "$@"
  printf '\n'
  echo "Service file: ${SERVICE_PATH}"
  echo "Command script: ${COMMAND_SCRIPT_PATH}"
}

main "$@"
