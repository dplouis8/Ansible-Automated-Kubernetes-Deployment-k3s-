#!/bin/bash

# delete and purge ControlNode
if multipass info "ControlNode" &>/dev/null; then
    echo "Control VM ControlNode found. Deleting..."
    multipass delete ControlNode
    
else
    echo "Control VM ControlNode not found."
fi

# delete and purge k3sMaster
if multipass info "k3sMaster" &>/dev/null; then
    echo "Master VM k3sMaster found. Deleting..."
    multipass delete k3sMaster
    
else
    echo "Master VM k3sMaster not found."
fi

# delete and purge k3sWorker1
if multipass info "k3sWorker1" &>/dev/null; then
    echo "Worker VM k3sWorker1 found. Deleting..."
    multipass delete k3sWorker1
    
else
    echo "Worker VM k3sWorker1 not found."
fi

# delete and purge k3sWorker2
if multipass info "k3sWorker2" &>/dev/null; then
    echo "Worker VM k3sWorker2 found. Deleting..."
    multipass delete k3sWorker2
    
else
    echo "Worker VM k3sWorker2 not found."
fi

# purge all
multipass purge
echo "All VMs Purged."