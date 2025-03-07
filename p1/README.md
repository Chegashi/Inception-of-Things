# P1 - Inception of Things

A minimal K3s cluster setup using Vagrant and VirtualBox.

## Quick Start

```bash
# Create and start the cluster
make all

# Show VM status
make vm

# Connect to controller node
vagrant ssh mochegriS

# Destroy all VMs
make clean
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

## Verification

After installation, SSH to controller and run:

```bash
kubectl get nodes
```

Both nodes should be listed and in "Ready" state.

---
This project is part of the 1337 school curriculum.
