# Scripts Collection

A collection of useful scripts and automation tools.

## Available Scripts

### Tailscale LAN Connectivity Fix
Fix for Tailscale breaking direct LAN connectivity when `accept-routes` is enabled. [Learn more](tailscale/README.md)

### K8s deploy automation

- [ ] TODO: Add more details

```bash
bash -c "$(wget -qO - https://raw.githubusercontent.com/jneiva0/jn-scripts/main/setup-k8s.sh)"
```

## WIP

### Cloud-init vendor file

```bash
wget https://raw.githubusercontent.com/jneiva0/jn-scripts/main/vendor.yaml -O 900-cloud-init.yml
```