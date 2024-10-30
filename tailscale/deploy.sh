#!/usr/bin/env bash

# Source the common utility script from the repository
source <(curl -fsSL https://raw.githubusercontent.com/jneiva0/jn-scripts/main/common.func) || {
  echo "Failed to load common functions."
  exit 1
}

deploy() {
  header_info
  echo -e "${BL}Tailscale LAN Connectivity Fix${CL}\n"

  root_check

  install_whiptail

  # Prepare the message for the whiptail dialog
  INFO_MESSAGE="This script automates the deployment of a fix for an issue where a Tailscale node becomes inaccessible from the local LAN when Tailscale is configured with 'accept-routes=true' and routes that point back to the LAN where the node is deployed are present in Tailscale.

By deploying a service and timer to the systemd directory, it ensures that local routes are properly prioritized, allowing LAN devices to communicate with the Tailscale node.

Do you want to proceed with the installation?"

  # Display confirmation using whiptail
  if whiptail --backtitle "Capivara Scripts" --title "Tailscale LAN Connectivity Fix" --yesno "$INFO_MESSAGE" 16 78; then
    log "User chose to proceed. Continuing with installation."
  else
    log "User chose not to proceed. Exiting."
    exit 0
  fi

  if ! command -v tailscale &>/dev/null; then
    error "Tailscale is not installed. Please install Tailscale before running this script."
  fi

  log "Downloading service and timer files..."

  REPO_URL="https://raw.githubusercontent.com/jneiva0/jn-scripts/main/tailscale"
  SERVICE_FILE="tailscale-directconnect-routes.service"
  TIMER_FILE="tailscale-directconnect-routes.timer"
  SYSTEMD_DIR="/etc/systemd/system"

  # Function to download files with retry logic
  download_with_retry() {
    local url=$1
    local output=$2
    local retries=3
    local count=0

    until curl -fsSL -o "$output" "$url"; do
      count=$((count + 1))
      if [ "$count" -ge "$retries" ]; then
        error "Failed to download $output from $url after $retries attempts."
      fi
      log "Retrying download of $output ($count/$retries)..."
      sleep 2
    done
  }

  # Download files
  download_with_retry "$REPO_URL/$SERVICE_FILE" "$SERVICE_FILE"
  download_with_retry "$REPO_URL/$TIMER_FILE" "$TIMER_FILE"
  log "Downloaded service and timer files."

  # Move the files to the systemd directory
  log "Moving files to $SYSTEMD_DIR..."
  mv "$SERVICE_FILE" "$SYSTEMD_DIR/" || error "Failed to move $SERVICE_FILE to $SYSTEMD_DIR."
  mv "$TIMER_FILE" "$SYSTEMD_DIR/" || error "Failed to move $TIMER_FILE to $SYSTEMD_DIR."
  log "Moved files to $SYSTEMD_DIR."

  # Set proper permissions
  log "Setting permissions for systemd files..."
  chmod 644 "$SYSTEMD_DIR/$SERVICE_FILE" || error "Failed to set permissions for $SERVICE_FILE."
  chmod 644 "$SYSTEMD_DIR/$TIMER_FILE" || error "Failed to set permissions for $TIMER_FILE."
  log "Permissions set."

  # Reload systemd to recognize the new service and timer
  log "Reloading systemd daemon..."
  systemctl daemon-reload || error "Failed to reload systemd daemon."
  log "Systemd daemon reloaded."

  # Enable and start the service and timer
  log "Enabling and starting the service and timer..."
  systemctl enable --now "$SERVICE_FILE" || error "Failed to enable/start service."
  systemctl enable --now "$TIMER_FILE" || error "Failed to enable/start timer."
  log "Service and timer are enabled and running."

  log "Deployment complete!"
}

deploy
