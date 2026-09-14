#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="unleash-the-fury.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
WRAPPER_PATH="/usr/local/bin/unleash-the-fury-startup"
ENV_PATH="/etc/default/unleash-the-fury"

usage() {
  cat <<'EOF'
Usage: sudo ./setup-systemd-service.sh '<command to run at startup>'

Installs and enables a oneshot systemd service named unleash-the-fury.service.
The provided command is stored in /etc/default/unleash-the-fury and executed
through /usr/local/bin/unleash-the-fury-startup on every boot.
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

write_env_file() {
  local command_string="$1"

  if [[ "${command_string}" == *$'\n'* ]]; then
    echo "The startup command must be a single line." >&2
    exit 1
  fi

  printf 'UNLEASH_THE_FURY_COMMAND=%q\n' "${command_string}" > "${ENV_PATH}"
  chmod 0644 "${ENV_PATH}"
}

write_wrapper() {
  cat > "${WRAPPER_PATH}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ENV_PATH="/etc/default/unleash-the-fury"

if [[ ! -r "${ENV_PATH}" ]]; then
  echo "Missing ${ENV_PATH}" >&2
  exit 1
fi

# shellcheck disable=SC1091
source "${ENV_PATH}"

if [[ -z "${UNLEASH_THE_FURY_COMMAND:-}" ]]; then
  echo "UNLEASH_THE_FURY_COMMAND is not set in ${ENV_PATH}" >&2
  exit 1
fi

exec /bin/sh -lc "${UNLEASH_THE_FURY_COMMAND}"
EOF

  chmod 0755 "${WRAPPER_PATH}"
}

write_service() {
  cat > "${SERVICE_PATH}" <<EOF
[Unit]
Description=Run the Unleash the Fury startup command
After=local-fs.target

[Service]
Type=oneshot
ExecStart=${WRAPPER_PATH}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  chmod 0644 "${SERVICE_PATH}"
}

enable_service() {
  systemctl daemon-reload
  systemctl enable "${SERVICE_NAME}"

  if systemctl is-active --quiet "${SERVICE_NAME}"; then
    systemctl restart "${SERVICE_NAME}"
  else
    systemctl start "${SERVICE_NAME}"
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

  local command_string="$*"

  write_env_file "${command_string}"
  write_wrapper
  write_service
  enable_service

  echo "Installed ${SERVICE_NAME}."
  echo "Command: ${command_string}"
  echo "Service file: ${SERVICE_PATH}"
  echo "Command file: ${ENV_PATH}"
  echo "Wrapper: ${WRAPPER_PATH}"
}

main "$@"
