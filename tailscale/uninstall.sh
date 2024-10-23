#!/usr/bin/env bash

# Color definitions
YW="\033[33m"
BL="\033[36m"
RD="\033[01;31m"
GN="\033[1;92m"
CL="\033[m"
CHECK="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

# Function to display header
header_info() {
  clear
  cat <<"EOF"
⠀⠀⠀⢀⣀⠤⠿⢤⢖⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡔⢩⠂⠀⠒⠗⠈⠀⠉⠢⠄⣀⠠⠤⠄⠒⢖⡒⢒⠂⠤⢄⠀⠀⠀⠀
⠇⠤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠈⠀⠈⠈⡨⢀⠡⡪⠢⡀⠀
⠈⠒⠀⠤⠤⣄⡆⡂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠢⠀⢕⠱⠀
⠀⠀⠀⠀⠀⠈⢳⣐⡐⠐⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠁⠇
⠀⠀⠀⠀⠀⠀⠀⠑⢤⢁⠀⠆⠀⠀⠀⠀⠀⢀⢰⠀⠀⠀⡀⢄⡜⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠘⡦⠄⡷⠢⠤⠤⠤⠤⢬⢈⡇⢠⣈⣰⠎⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣃⢸⡇⠀⠀⠀⠀⠀⠈⢪⢀⣺⡅⢈⠆⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠶⡿⠤⠚⠁⠀⠀⠀⢀⣠⡤⢺⣥⠟⢡⠃⠀⠀⠀
EOF
  echo -e "\n${BL}Tailscale LAN Connectivity Fix${CL}\n"
}

# Function to log messages
log() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${GN}$1${CL}"
}

# Function to handle errors
error() {
  echo -e "\n${RD}[ERROR] $(date +'%Y-%m-%d %H:%M:%S')${CL}"
  echo -e "${RD}$1${CL}"
  exit 1
}

# Function to check if running as root
root_check() {
  if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
  fi
}

undeploy() {
  header_info

  root_check

  # Variables
  SERVICE_FILE="tailscale-directconnect-routes.service"
  TIMER_FILE="tailscale-directconnect-routes.timer"
  SYSTEMD_DIR="/etc/systemd/system"

  log "Stopping and disabling the service and timer..."
  systemctl stop $SERVICE_FILE
  systemctl stop $TIMER_FILE
  systemctl disable $SERVICE_FILE
  systemctl disable $TIMER_FILE

  log "Removing service and timer files from $SYSTEMD_DIR..."
  rm -f $SYSTEMD_DIR/$SERVICE_FILE
  rm -f $SYSTEMD_DIR/$TIMER_FILE

  log "Reloading systemd daemon..."
  systemctl daemon-reload

  log "Uninstallation complete!"
}

undeploy
