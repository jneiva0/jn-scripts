#!/usr/bin/env bash

set -euo pipefail

# Color definitions
YW="\033[33m"
BL="\033[36m"
RD="\033[01;31m"
GN="\033[1;92m"
CL="\033[m"
# CROSS="${RD}✗${CL}"
CHECK="${GN}✓${CL}"

# Function to display header
header_info() {
    clear
    cat <<"EOF"
⠀⠀⢀⣀⠤⠿⢤⢖⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡔⢩⠂⠀⠒⠗⠈⠀⠉⠢⠄⣀⠠⠤⠄⠒⢖⡒⢒⠂⠤⢄⠀⠀⠀⠀
⠇⠤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠈⠀⠈⠈⡨⢀⠡⡪⠢⡀⠀
⠈⠒⠀⠤⠤⣄⡆⡂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠢⠀⢕⠱⠀
⠀⠀⠀⠀⠀⠈⢳⣐⡐⠐⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠁⠇
⠀⠀⠀⠀⠀⠀⠀⠑⢤⢁⠀⠆⠀⠀⠀⠀⠀⢀⢰⠀⠀⠀⡀⢄⡜⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠘⡦⠄⡷⠢⠤⠤⠤⠤⢬⢈⡇⢠⣈⣰⠎⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣃⢸⡇⠀⠀⠀⠀⠀⠈⢪⢀⣺⡅⢈⠆⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠶⡿⠤⠚⠁⠀⠀⠀⢀⣠⡤⢺⣥⠟⢡⠃⠀⠀⠀
EOF
    echo -e "\n${BL}Kubernetes Setup Script${CL}\n"
}

# Function to log messages
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${GN}$1${CL}"
}

# Function to handle errors
error() {
    echo -e "${RD}[ERROR]${CL} $1" >&2
    exit 1
}

# Step 1: Disable Swap
disable_swap() {
    log "Step 1: Disabling swap..."
    sudo swapoff -a || error "Failed to disable swap"
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || error "Failed to update fstab"
    log "Swap has been disabled."
}

# Step 2: Enable IPv4 Packet Forwarding
enable_ipv4_forwarding() {
    log "Step 2: Enabling IPv4 packet forwarding..."
    echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s.conf > /dev/null
    sudo sysctl --system || error "Failed to apply sysctl settings"
    log "IPv4 packet forwarding has been enabled."
}

# Step 4: Install containerd
install_containerd() {
    log "Step 4: Installing containerd..."
    # Add Docker's official GPG key
    apt-get update
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y containerd.io
    systemctl enable --now containerd
    log "containerd has been installed and enabled."
}

# Step 5: Install CNI Plugin
install_cni_plugin() {
    log "Step 5: Installing CNI Plugin..."
    wget https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
    mkdir -p /opt/cni/bin
    tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.0.tgz
    rm cni-plugins-linux-amd64-v1.4.0.tgz
    log "CNI Plugin has been installed."
}

# Step 6: Forward IPv4 and Configure iptables
configure_networking() {
    log "Step 6: Forward IPv4 and Configure iptables..."
    cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
    modprobe overlay
    modprobe br_netfilter

    cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

    sysctl --system
    sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
    modprobe br_netfilter
    sysctl -p /etc/sysctl.conf
    log "Networking configuration completed."
}

# Step 7: Modify containerd Configuration for systemd Support
modify_containerd_config() {
    log "Step 7: Modifying containerd configuration for systemd support..."
    cat <<EOF | tee /etc/containerd/config.toml
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[cgroup]
  path = ""

[debug]
  address = ""
  format = ""
  gid = 0
  level = ""
  uid = 0

[grpc]
  address = "/run/containerd/containerd.sock"
  gid = 0
  max_recv_message_size = 16777216
  max_send_message_size = 16777216
  tcp_address = ""
  tcp_tls_cert = ""
  tcp_tls_key = ""
  uid = 0

[metrics]
  address = ""
  grpc_histogram = false

[plugins]

  [plugins."io.containerd.gc.v1.scheduler"]
    deletion_threshold = 0
    mutation_threshold = 100
    pause_threshold = 0.02
    schedule_delay = "0s"
    startup_delay = "100ms"

  [plugins."io.containerd.grpc.v1.cri"]
    disable_apparmor = false
    disable_cgroup = false
    disable_hugetlb_controller = true
    disable_proc_mount = false
    disable_tcp_service = true
    enable_selinux = false
    enable_tls_streaming = false
    ignore_image_defined_volumes = false
    max_concurrent_downloads = 3
    max_container_log_line_size = 16384
    netns_mounts_under_state_dir = false
    restrict_oom_score_adj = false
    sandbox_image = "k8s.gcr.io/pause:3.5"
    selinux_category_range = 1024
    stats_collect_period = 10
    stream_idle_timeout = "4h0m0s"
    stream_server_address = "127.0.0.1"
    stream_server_port = "0"
    systemd_cgroup = true
    tolerate_missing_hugetlb_controller = true
    unset_seccomp_profile = ""

    [plugins."io.containerd.grpc.v1.cri".cni]
      bin_dir = "/opt/cni/bin"
      conf_dir = "/etc/cni/net.d"
      conf_template = ""
      max_conf_num = 1

    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "runc"
      disable_snapshot_annotations = true
      discard_unpacked_layers = false
      no_pivot = false
      snapshotter = "overlayfs"

      [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime]
        base_runtime_spec = ""
        container_annotations = []
        pod_annotations = []
        privileged_without_host_devices = false
        runtime_engine = ""
        runtime_root = ""
        runtime_type = ""

        [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime.options]

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          base_runtime_spec = ""
          container_annotations = []
          pod_annotations = []
          privileged_without_host_devices = false
          runtime_engine = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            BinaryName = ""
            CriuImagePath = ""
            CriuPath = ""
            CriuWorkPath = ""
            IoGid = 0
            IoUid = 0
            NoNewKeyring = false
            NoPivotRoot = false
            Root = ""
            ShimCgroup = ""
            SystemdCgroup = true

      [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime]
        base_runtime_spec = ""
        container_annotations = []
        pod_annotations = []
        privileged_without_host_devices = false
        runtime_engine = ""
        runtime_root = ""
        runtime_type = ""

        [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime.options]

    [plugins."io.containerd.grpc.v1.cri".image_decryption]
      key_model = "node"

    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = ""

      [plugins."io.containerd.grpc.v1.cri".registry.auths]

      [plugins."io.containerd.grpc.v1.cri".registry.configs]

      [plugins."io.containerd.grpc.v1.cri".registry.headers]

      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]

    [plugins."io.containerd.grpc.v1.cri".x509_key_pair_streaming]
      tls_cert_file = ""
      tls_key_file = ""

  [plugins."io.containerd.internal.v1.opt"]
    path = "/opt/containerd"

  [plugins."io.containerd.internal.v1.restart"]
    interval = "10s"

  [plugins."io.containerd.metadata.v1.bolt"]
    content_sharing_policy = "shared"

  [plugins."io.containerd.monitor.v1.cgroups"]
    no_prometheus = false

  [plugins."io.containerd.runtime.v1.linux"]
    no_shim = false
    runtime = "runc"
    runtime_root = ""
    shim = "containerd-shim"
    shim_debug = false

  [plugins."io.containerd.runtime.v2.task"]
    platforms = ["linux/amd64"]

  [plugins."io.containerd.service.v1.diff-service"]
    default = ["walking"]

  [plugins."io.containerd.snapshotter.v1.aufs"]
    root_path = ""

  [plugins."io.containerd.snapshotter.v1.btrfs"]
    root_path = ""

  [plugins."io.containerd.snapshotter.v1.devmapper"]
    async_remove = false
    base_image_size = ""
    pool_name = ""
    root_path = ""

  [plugins."io.containerd.snapshotter.v1.native"]
    root_path = ""

  [plugins."io.containerd.snapshotter.v1.overlayfs"]
    root_path = ""

  [plugins."io.containerd.snapshotter.v1.zfs"]
    root_path = ""

[proxy_plugins]

[stream_processors]

  [stream_processors."io.containerd.ocicrypt.decoder.v1.tar"]
    accepts = ["application/vnd.oci.image.layer.v1.tar+encrypted"]
    args = ["--decryption-keys-path", "/etc/containerd/ocicrypt/keys"]
    env = ["OCICRYPT_KEYPROVIDER_CONFIG=/etc/containerd/ocicrypt/ocicrypt_keyprovider.conf"]
    path = "ctd-decoder"
    returns = "application/vnd.oci.image.layer.v1.tar"

  [stream_processors."io.containerd.ocicrypt.decoder.v1.tar.gzip"]
    accepts = ["application/vnd.oci.image.layer.v1.tar+gzip+encrypted"]
    args = ["--decryption-keys-path", "/etc/containerd/ocicrypt/keys"]
    env = ["OCICRYPT_KEYPROVIDER_CONFIG=/etc/containerd/ocicrypt/ocicrypt_keyprovider.conf"]
    path = "ctd-decoder"
    returns = "application/vnd.oci.image.layer.v1.tar+gzip"

[timeouts]
  "io.containerd.timeout.shim.cleanup" = "5s"
  "io.containerd.timeout.shim.load" = "5s"
  "io.containerd.timeout.shim.shutdown" = "3s"
  "io.containerd.timeout.task.state" = "2s"

[ttrpc]
  address = ""
  gid = 0
  uid = 0
EOF
    systemctl restart containerd
    log "${CHECK} containerd configuration for systemd support has been updated and service restarted."
}

# Step 8: Restart containerd and Check the Status
restart_containerd() {
    log "Step 8: Restarting containerd and checking status..."
    systemctl restart containerd
    systemctl status containerd --no-pager
    log "${CHECK} containerd has been restarted."
}

# Step 9: Install kubeadm, kubelet, and kubectl
install_kubernetes_components() {
    log "Step 9: Installing kubeadm, kubelet, and kubectl..."
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gpg

    mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

    apt-get update -y
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
    log "${CHECK} kubeadm, kubelet, and kubectl have been installed."
}

# Main function
main() {
    header_info

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi

    # Update and install required packages
    log "Updating package list and installing required packages..."
    apt-get update && apt-get install -y whiptail || error "Failed to update or install packages"

    # Confirm proceeding with setup
    if ! (whiptail --backtitle "Joao Scripts" --title "K8s Base setup" --yesno "This will setup the base components for Kubernetes. Do you want to proceed?" 10 60); then
        log "User chose to exit. Goodbye!"
        exit 0
    fi

    # Step 1: Disable Swap
    if (whiptail --backtitle "Joao Scripts" --title "K8s - Step 1" --yesno "Disable swap? (Recommended for Kubernetes)" 10 60); then
        disable_swap
    else
        log "Swap will remain enabled. Note that Kubernetes recommends disabling swap for optimal performance."
    fi

    # Step 2: Enable IPv4 Packet Forwarding
    if (whiptail --backtitle "Joao Scripts" --title "K8s - Step 2" --yesno "Enable IPv4 Packet Forwarding?" 10 58); then
        enable_ipv4_forwarding
        # Step 3: Check if IPv4 Packet Forwarding is enabled
        local ipv4_forward_status
        ipv4_forward_status=$(sysctl net.ipv4.ip_forward)
        whiptail --backtitle "Joao Scripts" --title "K8s - Step 3" --msgbox "IPv4 Forwarding Status: $ipv4_forward_status" 10 60
    else
        log "Skipping IPv4 Packet Forwarding"
    fi

    # Step 4: Install containerd
    if (whiptail --backtitle "Joao Scripts" --title "K8s - Step 4" --yesno "Install containerd?" 10 58); then
        install_containerd
    else
        log "Skipping containerd installation"
    fi

    # Step 5: Install CNI Plugin
    if (whiptail --backtitle "Joao Scripts" --title "K8s - Step 5" --yesno "Install CNI Plugin?" 10 58); then
        install_cni_plugin
    else
        log "Skipping CNI Plugin installation"
    fi

    # Step 6: Forward IPv4 and Configure iptables
    if (whiptail --backtitle "Joao Scripts" --title "K8s - Step 6" --yesno "Forward IPv4 and Configure iptables?" 10 58); then
        configure_networking
    else
        log "Skipping networking configuration"
    fi

    # Ask if the user wants to continue with Step 7
    if (whiptail --backtitle "Joao Scripts" --title "K8s - Continue?" --yesno "Do you want to continue with Step 7 (Modify containerd Configuration for systemd Support)?" 10 60); then
        # Step 7: Modify containerd Configuration
        if (whiptail --backtitle "Joao Scripts" --title "K8s - Step 7" --yesno "Modify containerd Configuration for systemd Support?" 10 58); then
            modify_containerd_config
        else
            log "Skipping containerd configuration modification"
        fi

        # Step 8: Restart containerd and Check the Status
        if (whiptail --backtitle "Joao Scripts" --title "K8s - Step 8" --yesno "Restart containerd and check its status?" 10 58); then
            restart_containerd
        else
            log "Skipping containerd restart"
        fi

        # Step 9: Install kubeadm, kubelet, and kubectl
        if (whiptail --backtitle "Joao Scripts" --title "K8s - Step 9" --yesno "Install kubeadm, kubelet, and kubectl?" 10 58); then
            install_kubernetes_components
        else
            log "Skipping Kubernetes components installation"
        fi
    else
        log "Setup stopped after Step 6 as per user request."
    fi

    whiptail --backtitle "Joao Scripts" --title "K8s - Summary" --msgbox "If you did all the steps and they worked, you can now proceed from step Step 10\n\nLink in the next page" 10 60

    log "${CHECK} Kubernetes base setup completed."

    echo -e "\n${BL}Next steps:${CL}"
    echo -e "${YW}To initialize the cluster and install CNI, follow the guide at:${CL}"
    echo -e "${GN}https://github.com/lokeshjyo01/kubernetes-v1.30.2-cluster-using-kubeadm/blob/main/README.md#step-10-initialize-the-cluster-and-install-cni${CL}"

}

# Run the main function
main "$@"