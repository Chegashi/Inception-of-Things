#!/bin/bash
# K3s Cluster Setup Script for P1
# Usage: 
#   ./setup.sh controller
#   ./setup.sh worker <controller_ip>

# Enable strict error handling
set -e

# Logging functions
log_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
log_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
log_warn() { echo -e "\e[33m[WARNING]\e[0m $1"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }
verify_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "Command '$1' not found."
    else
        log_info "Command '$1' installed."
    fi
}

# Install required packages
log_info "Installing required packages..."
[[ ! $(ping -c 1 8.8.8.8 &> /dev/null) ]] && log_warn "Internet connectivity issues detected."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y || log_error "Failed to update packages."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl net-tools || log_error "Failed to install packages."

# Configure kubectl alias
log_info "Configuring kubectl alias..."
echo "alias k='kubectl'" >> /home/vagrant/.bashrc
echo 'export PATH="/sbin:$PATH"' >> /home/vagrant/.bashrc

# Validate parameters
[[ -z "$1" ]] && log_error "Usage: $0 [controller|worker] [controller_ip]"
ROLE=$1
CONTROLLER_IP=$2

# Load config if available
CONFIG_FILE="/shared/cluster_config"
[[ -f "$CONFIG_FILE" ]] && { log_info "Loading config from $CONFIG_FILE"; source "$CONFIG_FILE"; }

# Set environment variables
CONTROLLER_IP=${CONTROLLER_IP:-${K3S_CONTROLLER_IP:-"192.168.56.110"}}
K3S_PORT=${K3S_PORT:-"6443"}
log_info "Using controller IP: $CONTROLLER_IP"

# Verify K3s installation
verify_k3s_installation() {
    local max_attempts=5
    local attempt=1
    local service=$([[ "$1" == "controller" ]] && echo "k3s" || echo "k3s-agent")
    
    log_info "Verifying K3s $1 installation..."
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Verification attempt $attempt/$max_attempts..."
        if sudo systemctl is-active $service &>/dev/null; then
            log_success "K3s $1 service is running!"
            return 0
        else
            log_warn "K3s $1 service not running, waiting..."
            sleep 10
            ((attempt++))
        fi
    done
    
    log_error "K3s $1 service failed to start after $max_attempts attempts."
}

# Controller node setup
if [[ "$ROLE" == "controller" ]]; then
    log_info "Setting up controller node (K3s server)..."
    
    # Save config for workers
    echo "K3S_CONTROLLER_IP=$CONTROLLER_IP" > "/shared/cluster_config"
    echo "K3S_PORT=$K3S_PORT" >> "/shared/cluster_config"
    
    # Install K3s server
    log_info "Installing K3s server on eth1 interface..."
    curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" sh - || \
        log_error "Failed to install K3s server."
    
    verify_k3s_installation "controller"
    
    # Wait for k3s.yaml
    log_info "Waiting for K3s config files..."
    local max_wait=60
    local waited=0
    while [[ ! -f "/etc/rancher/k3s/k3s.yaml" && $waited -lt $max_wait ]]; do
        log_info "Waiting for k3s.yaml... ($waited/$max_wait sec)"
        sleep 5
        ((waited+=5))
    done
    
    [[ ! -f "/etc/rancher/k3s/k3s.yaml" ]] && log_error "k3s.yaml not generated after $max_wait seconds."
    sudo chmod 644 "/etc/rancher/k3s/k3s.yaml"
    
    # Wait for node-token
    waited=0
    while [[ ! -e "/var/lib/rancher/k3s/server/node-token" && $waited -lt $max_wait ]]; do
        log_info "Waiting for node-token... ($waited/$max_wait sec)"
        sleep 5
        ((waited+=5))
    done
    
    [[ ! -e "/var/lib/rancher/k3s/server/node-token" ]] && log_error "Node token not generated after $max_wait seconds."
    
    # Share tokens with worker
    log_info "Sharing tokens with worker node..."
    sudo mkdir -p /shared
    sudo chmod 644 /shared
    sudo cp "/var/lib/rancher/k3s/server/node-token" /shared/
    sudo cp "/etc/rancher/k3s/k3s.yaml" /shared/
    
    # Verify kubectl
    if kubectl get nodes &>/dev/null; then
        log_success "kubectl is functioning properly:"
        kubectl get nodes
    else
        log_warn "kubectl not working properly. May need to source .bashrc."
    fi
    
    log_success "Controller node setup complete."

# Worker node setup
elif [[ "$ROLE" == "worker" ]]; then
    [[ -z "$CONTROLLER_IP" ]] && log_error "Controller IP required. Usage: $0 worker <controller_ip>"
    log_info "Setting up worker node (K3s agent)..."
    
    # Check controller connectivity
    [[ ! $(ping -c 1 $CONTROLLER_IP &>/dev/null) ]] && log_warn "Controller at $CONTROLLER_IP not reachable. Setup may fail."
    
    # Wait for token from controller
    log_info "Waiting for auth token from controller..."
    local max_wait=120
    local waited=0
    while [[ ! -f /shared/node-token && $waited -lt $max_wait ]]; do
        log_info "Waiting for token... ($waited/$max_wait sec)"
        sleep 5
        ((waited+=5))
    done
    
    [[ ! -f /shared/node-token ]] && log_error "Auth token not found after $max_wait seconds."
    
    # Install K3s agent
    TOKEN=$(cat /shared/node-token)
    SERVER_IP="${CONTROLLER_IP}:${K3S_PORT}"
    
    log_info "Installing K3s agent on eth1 interface..."
    curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" \
        K3S_URL=https://$SERVER_IP K3S_TOKEN=$TOKEN sh - || log_error "Failed to install K3s agent."
    
    verify_k3s_installation "worker"
    
    # Set up local kubeconfig
    if [[ -f /shared/k3s.yaml ]]; then
        log_info "Setting up local kubeconfig..."
        mkdir -p /home/vagrant/.kube
        cp /shared/k3s.yaml /home/vagrant/.kube/config
        sed -i "s/127.0.0.1/$CONTROLLER_IP/g" /home/vagrant/.kube/config
        chown -R vagrant:vagrant /home/vagrant/.kube
    fi
    
    log_success "Worker node setup complete."
else
    log_error "Invalid role. Use 'controller' or 'worker'"
fi

# Final verification
log_info "Verifying network configuration..."
ip addr show eth1 || log_warn "eth1 interface not found or configured properly."

# Verify K3s tools installation
verify_command kubectl
verify_command k3s

log_success "K3s cluster setup completed successfully."
