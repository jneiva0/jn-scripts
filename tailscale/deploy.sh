#!/usr/bin/env bash

set -e

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
⠀⠀⢀⣀⠤⠿⢤⢖⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
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

# Main deploy function
deploy() {
  header_info

  # Prepare the message for the whiptail dialog
  INFO_MESSAGE="This script automates the deployment of a fix for an issue where a Tailscale node becomes inaccessible from the local LAN when Tailscale is configured with 'accept-routes=true' and routes that point back to the LAN where the node is deployed are present in tailscale.

By deploying a service and timer to the systemd directory, it ensures that local routes are properly prioritised, allowing LAN devices to communicate with the Tailscale node.

Do you want to proceed with the installation?"

  if (whiptail --backtitle "Capivara Scripts" --title "Tailscale LAN Connectivity Fix" --yesno "$INFO_MESSAGE" 16 78); then
    log "User chose to proceed. Continuing with installation."
  else
    log "User chose not to proceed. Exiting."
    exit 0
  fi

  root_check

  if ! command -v tailscale &>/dev/null; then
    error "Tailscale is not installed"
  fi

  # Variables
  REPO_URL="https://raw.githubusercontent.com/jneiva0/jn-scripts/main/tailscale"
  SERVICE_FILE="tailscale-directconnect-routes.service"
  TIMER_FILE="tailscale-directconnect-routes.timer"
  SYSTEMD_DIR="/etc/systemd/system"

  # Download the service and timer files from the repository
  log "Downloading service and timer files..."
  curl -fsSL -o "$SERVICE_FILE" "$REPO_URL/$SERVICE_FILE" || error "Failed to download $SERVICE_FILE"
  curl -fsSL -o "$TIMER_FILE" "$REPO_URL/$TIMER_FILE" || error "Failed to download $TIMER_FILE"
  log "Downloaded service and timer files."

  # Move the files to the systemd directory
  log "Moving files to $SYSTEMD_DIR..."
  mv "$SERVICE_FILE" "$SYSTEMD_DIR/" || error "Failed to move $SERVICE_FILE to $SYSTEMD_DIR"
  mv "$TIMER_FILE" "$SYSTEMD_DIR/" || error "Failed to move $TIMER_FILE to $SYSTEMD_DIR"
  log "Moved files to $SYSTEMD_DIR."

  # Set proper permissions
  log "Setting permissions for systemd files..."
  chmod 644 "$SYSTEMD_DIR/$SERVICE_FILE" || error "Failed to set permissions for $SERVICE_FILE"
  chmod 644 "$SYSTEMD_DIR/$TIMER_FILE" || error "Failed to set permissions for $TIMER_FILE"
  log "Permissions set."

  # Reload systemd to recognize the new service and timer
  log "Reloading systemd daemon..."
  systemctl daemon-reload || error "Failed to reload systemd daemon"
  log "Systemd daemon reloaded."

  # Enable and start the service and timer
  log "Enabling and starting the service and timer..."
  systemctl enable --now tailscale-directconnect-routes.service || error "Failed to enable/start service"
  systemctl enable --now tailscale-directconnect-routes.timer || error "Failed to enable/start timer"
  log "Service and timer are enabled and running."

  log "Deployment complete!"
}

# Run the main deploy function
deploy