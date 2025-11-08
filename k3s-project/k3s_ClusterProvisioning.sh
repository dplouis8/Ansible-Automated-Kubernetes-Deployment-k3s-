#!/bin/bash

# Configuration
CONTROL_VM_NAME="ControlNode"
LEADER="k3sMaster"
WORKER1="k3sWorker1"
WORKER2="k3sWorker2"
PROJECT_DIR_ON_MAC="$(pwd)"
ANSIBLE_PROJECT_DIR="ansible"
ANSIBLE_INVENTORY_PATH="$ANSIBLE_PROJECT_DIR/inventory/hosts.ini"
ANSIBLE_PLAYBOOK_PATH="$ANSIBLE_PROJECT_DIR/playbooks/k3s-install.yml"
ANSIBLE_CONFIG_PATH="$ANSIBLE_PROJECT_DIR/ansible.cfg"
SSH_KEY_NAME="ansible_key" # The name for the new SSH key pair

# Function to wait for a successful SSH connection using multipass exec
wait_for_boot() {
    echo "Waiting for instance '$1' to boot..."
    while ! multipass exec "$1" -- ls >/dev/null 2>&1; do
        printf "."
        sleep 5
    done
    echo "Instance '$1' is ready."
}

# --- Provisioning steps ---

# Step 1: Provision the control VM if it doesn't exist
if ! multipass info "$CONTROL_VM_NAME" &>/dev/null; then
    echo "Control VM '$CONTROL_VM_NAME' not found. Launching..."
    multipass launch --name "$CONTROL_VM_NAME"
    wait_for_boot "$CONTROL_VM_NAME"
else
    echo "Control VM '$CONTROL_VM_NAME' already exists. Skipping launch."
fi

# Step 2: Install Ansible and generate SSH key pair inside the control VM
echo "Installing Ansible and generating SSH key on the control node..."
multipass exec "$CONTROL_VM_NAME" -- sudo apt-get update
multipass exec "$CONTROL_VM_NAME" -- sudo apt-get install -y ansible sshpass
multipass exec "$CONTROL_VM_NAME" -- bash -c "ssh-keygen -t rsa -N '' -f ~/.ssh/$SSH_KEY_NAME"
echo "Ansible installed and SSH key pair generated on the control node."

# Step 3: Get the public key from the control node for cloud-init
echo "Retrieving public key from ControlNode..."
CONTROL_NODE_PUB_KEY=$(multipass exec "$CONTROL_VM_NAME" -- bash -c "cat ~/.ssh/${SSH_KEY_NAME}.pub")
echo "Public key retrieved successfully."

# Step 4: Create a cloud-init file with the public key for other VMs
echo "Creating cloud-init file for other nodes..."
cat << EOF > cloud-init.yaml
#cloud-config
ssh_authorized_keys:
  - $CONTROL_NODE_PUB_KEY
EOF

# Step 5: Launch the k3s cluster nodes with cloud-init
echo "Launching k3s cluster nodes with cloud-init..."
multipass launch --name $LEADER --cpus 2 --memory 2G --disk 10G --cloud-init ./cloud-init.yaml
multipass launch --name $WORKER1 --cpus 2 --memory 2G --disk 10G --cloud-init ./cloud-init.yaml
multipass launch --name $WORKER2 --cpus 2 --memory 2G --disk 10G --cloud-init ./cloud-init.yaml

# Wait for all nodes to boot before proceeding
wait_for_boot "$LEADER"
wait_for_boot "$WORKER1"
wait_for_boot "$WORKER2"

# # Step 6: Generate Ansible inventory and config on the macOS host
# echo "Generating Ansible inventory and config file on macOS host..."
# mkdir -p "$ANSIBLE_PROJECT_DIR"/{inventory,playbooks,roles}


# Get dynamic IPs
LEADER_IP=$(multipass info $LEADER | grep IPv4 | awk '{print $2}')
WORKER1_IP=$(multipass info $WORKER1 | grep IPv4 | awk '{print $2}')
WORKER2_IP=$(multipass info $WORKER2 | grep IPv4 | awk '{print $2}')

# Generate inventory
{
    echo "[k3s-cluster:vars]"
    echo "ansible_user=ubuntu"
    echo "ansible_ssh_private_key_file=/home/ubuntu/.ssh/$SSH_KEY_NAME"
    echo ""
    echo "[leader]"
    echo "$LEADER_IP"
    echo ""
    echo "[workers]"
    echo "$WORKER1_IP"
    echo "$WORKER2_IP"
    echo ""
    echo "[k3s-cluster:children]"
    echo "leader"
    echo "workers"
} > "$ANSIBLE_INVENTORY_PATH"

# Generate ansible.cfg
{
    echo "[defaults]"
    echo "inventory = ./inventory/hosts.ini"
    echo "roles_path = ./roles"
    echo "host_key_checking = False"
} > "$ANSIBLE_CONFIG_PATH"
echo "Ansible inventory and config files created."

# Step 7: Copy Ansible project to the control VM
echo "Copying Ansible project to control node..."
multipass transfer -r "$ANSIBLE_PROJECT_DIR" "$CONTROL_VM_NAME":/home/ubuntu/k3s-project/
echo "Copy complete."

# Step 8: Execute Ansible playbook inside the control VM for live output
echo "Executing Ansible playbook interactively for live output..."
multipass shell "$CONTROL_VM_NAME" << EOF
    cd /home/ubuntu/k3s-project/
    ansible-playbook -i inventory/hosts.ini playbooks/k3s-install.yml
    ansible-playbook -i inventory/hosts.ini playbooks/verify-deploy.yml
    ansible-playbook -i inventory/hosts.ini playbooks/deploy-nginx.yml
    echo "Ansible playbook execution finished."
    exit
EOF

echo "Full cluster provisioning process finished."
