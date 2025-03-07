# P1 - Inception of Things

A minimal K3s cluster setup using Vagrant and VirtualBox.

## How to Run

1. Clone the repository:
   ```bash
   git clone https://github.com/Chegashi/Inception-of-Things/
   cd Inception-of-Things/p1
   ```

2. Run the cluster:
   ```bash
   make all
   ```

3. Wait for the installation to complete (~5-10 minutes)

## Requirement Verification Commands

### 1. Basic Setup Verification
```bash
# Check if Vagrantfile exists
ls Vagrantfile

# View Vagrantfile content
cat Vagrantfile

# Check number of VMs and their configuration
vagrant status
```

### 2. Distribution Version Check
```bash
# Check OS version on both machines
vagrant ssh mochegriS -c "cat /etc/os-release"
vagrant ssh mochegriSW -c "cat /etc/os-release"
```

### 3. Network Interface Verification
```bash
# Check eth1 interface on Server
vagrant ssh mochegriS -c "ifconfig eth1"
# Should show IP: 192.168.56.110

# Check eth1 interface on Worker
vagrant ssh mochegriSW -c "ifconfig eth1"
# Should show IP: 192.168.56.111
```

### 4. Hostname Verification
```bash
# Check hostnames
vagrant ssh mochegriS -c "hostname"
# Should show: mochegriS

vagrant ssh mochegriSW -c "hostname"
# Should show: mochegriSW
```

### 5. K3s Installation Check
```bash
# Check K3s server status on Controller
vagrant ssh mochegriS -c "sudo systemctl status k3s"

# Check K3s agent status on Worker
vagrant ssh mochegriSW -c "sudo systemctl status k3s-agent"

# Verify cluster nodes from Controller
vagrant ssh mochegriS -c "kubectl get nodes -o wide"
```

### 6. Full Cluster Verification
```bash
# One-command full verification
vagrant ssh mochegriS -c "kubectl get nodes -o wide && \
                         kubectl get pods -A && \
                         kubectl cluster-info"
```

### 7. Quick All-in-One Test Script
```bash
#!/bin/bash
echo "=== Checking VMs ==="
vagrant status

echo -e "\n=== Checking Server Node ==="
vagrant ssh mochegriS -c "hostname && \
                         ifconfig eth1 && \
                         sudo systemctl status k3s --no-pager && \
                         kubectl get nodes -o wide"

echo -e "\n=== Checking Worker Node ==="
vagrant ssh mochegriSW -c "hostname && \
                          ifconfig eth1 && \
                          sudo systemctl status k3s-agent --no-pager"
```

## Expected Outputs

### Node Status
```bash
NAME        STATUS   ROLES                  AGE     VERSION
mochegriS   Ready    control-plane,master   10m     v1.27.1+k3s1
mochegriSW  Ready    <none>                 5m      v1.27.1+k3s1
```

### Network Configuration
```
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>
      inet 192.168.56.110/24  # For Server
      inet 192.168.56.111/24  # For Worker
```

## Quick Commands

```bash
# Show VM status
make vm

# Reload VMs
make reload

# Destroy all VMs
make clean

# Rebuild from scratch
make re
```

## Prerequisites

- Vagrant 2.2.19+
- VirtualBox 6.1+
- 2GB+ free RAM
- 10GB+ free disk space

## Files

- `Vagrantfile`: VM and network configuration
- `setup.sh`: K3s installation script
- `conf_files/cluster_config.template`: Cluster configuration template
- `Makefile`: Automation commands

## Troubleshooting

If verification fails:
1. Check VM status: `vagrant status`
2. View logs: `vagrant logs`
3. Verify network: `vagrant ssh mochegriS -c "ping -c 1 192.168.56.111"`
4. Rebuild if needed: `make re`

---
This project is part of the 1337 school curriculum. 