# Provisioning Kubernetes using Ansible and Kubeadm

The repo has the following main files

- `provision-servers.sh`: Provisions VMs on Digital Ocean using `doctl`, generates ansible hosts file `hosts.cfg` with configuration vars and creates `teardown.sh`
- `ansible/main.yaml`: Main playbook.

## Prerequisites

- [Ansible](https://www.ansible.com/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/using_helm/#installing-helm)
