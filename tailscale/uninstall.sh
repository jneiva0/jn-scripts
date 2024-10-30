#!/usr/bin/env bash

# Source the common utility script from the repository
source <(curl -fsSL https://raw.githubusercontent.com/jneiva0/jn-scripts/main/tailscale/common.func) || {
  echo "Failed to load common functions."
  exit 1
}

undeploy() {
  header_info

  root_check

  install_whiptail

  # Prepare the message for the whiptail dialog
  INFO_MESSAGE="This script will uninstall the Tailscale LAN connectivity fix, stopping and removing all related services and timers.

Do you want to proceed with the uninstallation?"

  # Display confirmation using whiptail
  if whiptail --backtitle "Capivara Scripts" --title "Uninstall Tailscale LAN Connectivity Fix" --yesno "$INFO_MESSAGE" 16 78; then
    log "User chose to proceed. Continuing with uninstallation."
  else
    log "User chose not to proceed. Exiting."
    exit 0
  fi

  REPO_URL="https://raw.githubusercontent.com/jneiva0/jn-scripts/main/tailscale"
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
