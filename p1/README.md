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

4. Connect to the controller node:
   ```bash
   vagrant ssh mochegriS
   ```

5. Verify the cluster is running:
   ```bash
   kubectl get nodes
   ```
   Both nodes should show as "Ready"

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

---
This project is part of the 1337 school curriculum. 