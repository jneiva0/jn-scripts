<div align="center">
  <a href="#">
 </a>

 ![caplogo](radcap.webp "Wise Capybara"){height=200px}

<h1 align="center ">Capybara Scripts Trove</h1>
</div>

---

Run these scripts **at your own risk.** No guarantees. Understand them, have backups. **You’ve been warned**.

---

## Available Scripts

### Tailscale LAN Connectivity Fix [Here](tailscale/README.md)
Fix for Tailscale breaking direct LAN connectivity when `accept-routes` is enabled. [Learn more](tailscale/README.md)

---

### Proxmox-Enhanced-Configuration-Utility (PECU) [Here](pecu/README.md)

**Proxmox-Enhanced-Configuration-Utility (PECU)** is a Bash script that simplifies Proxmox VE configuration and management through an simple interactive CLI menu for key tasks like package repository management and GPU passthrough setup.

- **Modify `sources.list`**: Edit the `sources.list` file directly within the script interface using Nano or automatically add recommended repositories.

- **Backup and Restore**: Create and restore backups of the `sources.list` file to ensure you have safe points to revert to.
  
- **GPU Passthrough**: Automatically configure GPU passthrough to assign a dedicated graphics card to virtual machines

- **System Config Checks**:
  - Verifies if the Proxmox package repositories are correctly configured.
  - Displays the state of IOMMU and MSI options for better hardware optimization.

---

## WIP

### K8s deploy automation

- [ ] TODO: Add more details

```bash
bash -c "$(wget -qO - https://raw.githubusercontent.com/jneiva0/jn-scripts/main/setup-k8s.sh)"
```

### Cloud-init vendor file

```bash
wget https://raw.githubusercontent.com/jneiva0/jn-scripts/main/vendor.yaml -O 900-cloud-init.yml
```
