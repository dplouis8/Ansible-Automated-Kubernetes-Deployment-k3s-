# Infrastructure-as-Code (IaC) Demonstration: Ansible-Automated k3s Cluster Deployment

# Overview

This project showcases a complete Infrastructure-as-Code pipeline using Ansible and Bash to provision and deploy a secure, high-availability  {k3s}  Kubernetes cluster.

The primary goal was to automate the transition from a fresh virtual machine (or bare metal host) to a fully operational, multi-node  {Kubernetes}  environment hosting a containerized application, simulating a mature  {DevOps}  delivery process.

# Technology Stack

- Orchestration

 {k3s}  (Lightweight  {Kubernetes} )

Container orchestration and cluster management.

- IaC / Automation

Ansible ( {YAML} ), Bash

Automated provisioning, configuration, and application deployment.

- Infrastructure

 {Ubuntu}   {Linux}   {VMs} ,  {SSH} 

Target operating system and secure connectivity.

- Containerization

 {Docker}  /  {Containerd} 

Packaging and running the Nginx web service.

# Architecture and Automation Pipeline

The project follows a two-stage automated approach:

- Stage 1: Cluster Provisioning (Ansible & Bash)

A Bash script (k3s_ClusterProvisioning.sh) initiates the entire process.

Ansible is executed to manage all hosts defined in the hosts.ini inventory.

Ansible Roles (k3s-cluster/tasks/main.yml) manage the complex installation logic:

One host is designated as the primary leader/control-plane.

Other hosts join the cluster as worker nodes using the token obtained from the leader.

This ensures the cluster foundation is repeatable, immutable, and fully configured before deployment.

- Stage 2: Application Deployment (Ansible & Manifests)

A dedicated  \mathbf{Ansible}  playbook (deploy-nginx.yml) targets the newly provisioned  {Kubernetes}  leader.

This playbook is responsible for securely copying the  {YAML}  manifest to the host.

It then executes the kubectl apply -f ... command to create the application resources, demonstrating a clear separation of provisioning (Ansible) and orchestration (Kubernetes).

# Key Project Files and Manifests

- 1. Application Manifest (k8s/nginxDeploy.yaml)

This single manifest defines the application architecture:

Deployment: Creates a replica set of three ( \mathbf{HA}  focus) Nginx pods, ensuring the service remains available even if a node fails.

Service: Exposes the Nginx pods externally using a NodePort type, providing a stable access IP and port across the cluster.

- 2. Ansible Files

- inventory/hosts.ini

Defines the target  {VM}   {IPs}  and their role (leader or worker).

- playbooks/k3s-install.yml

Main playbook to execute the cluster provisioning role.

- roles/k3s-cluster/tasks/main.yml

Handles the installation of  {k3s} , certificate copying, and worker node joining logic.

- roles/nginx-deploy/tasks/main.yaml

Executes the  {kubectl}  command to apply the  {Nginx}  manifest.

# Execution and Verification

To run this project:

Prerequisites: Ensure you have  {Ansible}  installed on your local machine and three  {Ubuntu}   {VMs}  running with  {SSH}  access.

Update Inventory: Configure the  {VM}   {IP}  addresses in inventory/hosts.ini.

Run Provisioning: Execute the main  {Bash}  script, which calls the  {Ansible}  playbooks in order:

./k3s_ClusterProvisioning.sh


Verify Cluster Health:

# Run from the leader node:
kubectl get nodes


Verify Application:

# Run from the leader node to see the deployed pods:
kubectl get pods -o wide
# Find the NodePort for the service:
kubectl get svc


The application is accessible via any worker node  {IP}  at the specified  {NodePort} .