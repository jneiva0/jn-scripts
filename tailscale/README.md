# Tailscale LAN Connectivity Fix

## Fix Tailscale breaking direct LAN connectivity to node when `accept-routes` is enabled

This script automates the deployment of a fix for an issue where a Tailscale node becomes inaccessible from the local LAN when `accept-routes=true` is enabled. It deploys a systemd service and timer to prioritize local routes, ensuring LAN devices can communicate with the Tailscale node.

### How to Use

**The script requires root access.**

To deploy the fix, run the following command on your Debian/Ubuntu (systemd) machine:

-   **With Prompt:**

    ```bash
    bash -c "$(wget -qO - https://raw.githubusercontent.com/jneiva0/jn-scripts/main/tailscale/deploy.sh)"
    ```

-   **Non-Interactive Mode (Auto-Yes):**

    ```bash
    `bash -c "$(wget -qO - https://raw.githubusercontent.com/jneiva0/jn-scripts/main/tailscale/deploy.sh)" --yes`

## How it works:
- Downloads the `.service` and `.timer` files from the repository. Code source originated from here: https://github.com/tailscale/tailscale/issues/1227#issuecomment-2166650995
- Places the files in the `/etc/systemd/system` directory on a Debian/Ubuntu (systemd) system.
- Enables and starts the systemd service and timer.
- Cleans up after itself once the deployment is complete.

This will:
1. Download the service and timer files.
2. Move them to the correct location.
3. Enable and start the service and timer to fix the connectivity issue.


## Uninstall

To uninstall run the following command:

```bash
curl -sS https://github.com/jneiva0/jn-scripts/raw/main/tailscale/uninstall.sh | sudo bash
```

This will:
1. Stop and disable the service and timer.
2. Remove the service and timer files
3. Reload the systemd daemon

## TODO

- [ ] Add prerequisite check mentioning Tailscale installation requirement
- [ ] Document minimum required Tailscale version
- [ ] Add link to official Tailscale installation docs
- [ ] Test the uninstall script
- [ ] Check the script is idempotent