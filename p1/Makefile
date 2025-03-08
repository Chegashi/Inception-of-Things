# Command for creating/provisioning VMs
CMD = vagrant up --provision

# Create and start the K3s cluster (Server and Worker)
all:
	@echo "Creating K3s cluster..."
	$(CMD)
	@echo "Done. Connect with: vagrant ssh mochegriS"
	@echo "Check nodes with: kubectl get nodes"

# Reload VMs without recreating them
reload:
	@echo "Reloading VMs..."
	@vagrant reload
	@echo "Done."

# Show status of all VMs
vm:
	@echo "VM status:"
	@vagrant global-status --prune

# Destroy all VMs
clean:
	@echo "Destroying all VMs..."
	@vagrant global-status --prune | grep virtualbox | awk '{print $$1}' | xargs -I {} vagrant destroy -f {}
	@echo "Done."

# Recreate everything from scratch
re: clean all

# Ensure these targets always execute
.PHONY: all clean re vm reload
