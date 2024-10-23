# Tailscale

## Fix Tailscale breaking direct LAN connectivity to node when `accept-routes` is enabled

This script automates the deployment of the issue fix where a Tailscale node becomes inaccessible from the local LAN when Tailscale is configured with `accept-routes=true` and routes that point back to the LAN where the node is deployed are present in tailscale.

By deploying a service and timer to the systemd directory, it ensures that local routes are properly prioritised, allowing LAN devices to communicate with the Tailscale node.

## How it works:
- Downloads the `.service` and `.timer` files from the repository. Code source originated from here: https://github.com/tailscale/tailscale/issues/1227#issuecomment-2166650995
- Places the files in the `/etc/systemd/system` directory on a Debian/Ubuntu (systemd) system.
- Enables and starts the systemd service and timer.
- Cleans up after itself once the deployment is complete.

## How to use:

To deploy this fix, run the following command on your Debian/Ubuntu (systemd) machine:

```bash
bash -c "$(wget -qO - https://raw.githubusercontent.com/jneiva0/jn-scripts/main/tailscale/deploy.sh)"
```

This will:
1. Download the service and timer files.
2. Move them to the correct location.
3. Enable and start the service and timer to fix the connectivity issue.




## TODO
To uninstall run the following command:

```bash
curl -sS https://github.com/jneiva0/jn-scripts/raw/main/tailscale/uninstall.sh | sudo bash
```

This will:
1. Stop and disable the service and timer.
2. Remove the service and timer files
3. Reload the systemd daemon

**The scripts require root access, granted during execution via sudo.**


## K8s deploy automation

```bash
bash -c "$(wget -qO - https://raw.githubusercontent.com/jneiva0/jn-scripts/main/setup-k8s.sh)"
```

## TODO

```bash
wget https://raw.githubusercontent.com/jneiva0/jn-scripts/main/vendor.yaml -O 900-cloud-init.yml
```