#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="unleash-the-fury.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
COMMAND_SCRIPT_PATH="/usr/local/bin/unleash-the-fury-command"
INSTALL_PATH="/usr/local/bin/fury-rgb-off"
REPO_REF="${REPO_REF:-main}"
SCRIPT_URL="https://raw.githubusercontent.com/cynodia/unleash-the-fury/${REPO_REF}/fury-rgb-off"
BUS="${BUS:-}"

usage() {
  cat <<'EOF'
Usage: install-systemd-service.sh [--bus <number>]

Downloads fury-rgb-off, optionally runs it once as a test, and installs/enables
the unleash-the-fury systemd service.
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

require_i2c_tools() {
  if ! command -v i2cdetect >/dev/null 2>&1 || ! command -v i2cset >/dev/null 2>&1; then
    echo "i2c-tools is required (missing i2cdetect and/or i2cset)." >&2
    exit 1
  fi
}

download_script() {
  local destination="$1"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${SCRIPT_URL}" -o "${destination}"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "${destination}" "${SCRIPT_URL}"
    return
  fi

  echo "curl or wget is required to download ${SCRIPT_URL}." >&2
  exit 1
}

prompt_yes_no() {
  local prompt="$1"
  local default_answer="$2"
  local reply

  default_answer="${default_answer,,}"
  case "${default_answer}" in
    y|yes) default_answer="y" ;;
    n|no) default_answer="n" ;;
    *)
      echo "Internal error: invalid default answer '${default_answer}'." >&2
      exit 1
      ;;
  esac

  if [[ ! -r /dev/tty ]]; then
    echo "No TTY detected; using default answer '${default_answer}' for: ${prompt}"
    [[ "${default_answer}" == "y" ]]
    return
  fi

  while true; do
    read -r -p "${prompt} " reply </dev/tty
    reply="${reply:-${default_answer}}"
    reply="${reply,,}"

    case "${reply}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *)
        echo "Please answer y or n." >&2
        ;;
    esac
  done
}

run_test() {
  local script_path="$1"

  echo "Running a one-time test with ${script_path}..."
  if [[ -n "${BUS:-}" ]]; then
    echo "Using BUS=${BUS} for the test and installed service."
    BUS="${BUS}" "${script_path}"
    return
  fi

  "${script_path}"
}

write_command_script() {
  cat > "${COMMAND_SCRIPT_PATH}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
$(if [[ -n "${BUS:-}" ]]; then printf 'export BUS=%q\n' "${BUS}"; fi)
exec ${INSTALL_PATH}
EOF

  chmod 0755 "${COMMAND_SCRIPT_PATH}"
}

write_service() {
  cat > "${SERVICE_PATH}" <<EOF
[Unit]
Description=Disable Kingston Fury RGB at startup
After=local-fs.target

[Service]
Type=oneshot
ExecStart=${COMMAND_SCRIPT_PATH}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  chmod 0644 "${SERVICE_PATH}"
}

enable_service() {
  systemctl daemon-reload

  if systemctl is-enabled --quiet "${SERVICE_NAME}" >/dev/null 2>&1; then
    systemctl restart "${SERVICE_NAME}"
  else
    systemctl enable --now "${SERVICE_NAME}"
  fi
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --bus)
        if [[ $# -lt 2 || -z "${2}" ]]; then
          echo "--bus requires a value." >&2
          exit 1
        fi
        BUS="$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        usage >&2
        exit 1
        ;;
    esac
  done

  require_root
  require_systemd
  require_i2c_tools

  local temp_dir temp_script
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "${temp_dir}"' EXIT

  temp_script="${temp_dir}/fury-rgb-off"
  download_script "${temp_script}"
  chmod 0755 "${temp_script}"

  if prompt_yes_no "Run fury-rgb-off once now before installing the service? [Y/n]" "y"; then
    if ! run_test "${temp_script}"; then
      echo "The test run failed." >&2
      if ! prompt_yes_no "Install the service anyway? [y/N]" "n"; then
        echo "Installation cancelled."
        exit 1
      fi
    fi
  elif ! prompt_yes_no "Install the service without a test run? [y/N]" "n"; then
    echo "Installation cancelled."
    exit 1
  fi

  install -m 0755 "${temp_script}" "${INSTALL_PATH}"
  write_command_script
  write_service
  enable_service

  echo "Installed ${SERVICE_NAME}."
  echo "RGB script: ${INSTALL_PATH}"
  echo "Command script: ${COMMAND_SCRIPT_PATH}"
  echo "Service file: ${SERVICE_PATH}"
  if [[ -n "${BUS:-}" ]]; then
    echo "Configured BUS=${BUS} for future runs."
  fi
}

main "$@"
