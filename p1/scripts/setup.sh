#!/bin/bash

# Update system and install required packages
echo "Updating system and installing required packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl net-tools
sudo ln -sf /sbin/ifconfig /usr/local/bin/ifconfig

# Create an alias for kubectl as 'k' and update PATH
echo "Configuring .bashrc for kubectl alias and PATH..."
echo "alias k='kubectl'" >> /home/vagrant/.bashrc
echo 'export PATH="/sbin:$PATH"' >> /home/vagrant/.bashrc


# Check if role parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 [controller|worker] [controller_ip]"
    echo "For controller: $0 controller"
    echo "For worker: $0 worker <controller_ip>"
    exit 1
fi

ROLE=$1
CONTROLLER_IP=$2

if [ "$ROLE" = "controller" ]; then
    echo "Setting up controller node..."
    
    # Install K3s in controller mode with full arguments
    curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" sh -
    sleep 10
    
    # Ensure k3s.yaml exists before modifying it
    while [ ! -f "/etc/rancher/k3s/k3s.yaml" ]; do
        sleep 2
        echo "Waiting for k3s.yaml..."
    done
    sudo chmod 644 "/etc/rancher/k3s/k3s.yaml"
    
    # Ensure node-token exists before copying
    while [ ! -e "/var/lib/rancher/k3s/server/node-token" ]; do
        echo "Waiting for node-token..."
        sleep 2
    done
    
    # Ensure /shared exists
    sudo mkdir -p /shared
    sudo chmod 644 /shared
    sudo cp "/var/lib/rancher/k3s/server/node-token" /shared/
    sudo cp "/etc/rancher/k3s/k3s.yaml" /shared/
    echo "Controller node setup complete."

elif [ "$ROLE" = "worker" ]; then
    if [ -z "$CONTROLLER_IP" ]; then
        echo "Error: Controller IP is required for worker setup"
        echo "Usage: $0 worker <controller_ip>"
        exit 1
    fi
    
    echo "Setting up worker node..."
    
    # Wait for the token to be available
    while [ ! -f /shared/node-token ]; do
        sleep 2
        echo "Waiting for the token from the controller..."
    done
    
    # Read the token
    TOKEN=$(cat /shared/node-token)
    SERVER_IP="${CONTROLLER_IP}:6443"
    
    # Install K3s in worker mode
    curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" K3S_URL=https://$SERVER_IP K3S_TOKEN=$TOKEN sh -
    
    sleep 10
    echo "Worker node setup complete."
else
    echo "Invalid role. Use 'controller' or 'worker'"
    exit 1
fi
