# Ansible CheetSheet

```sh
# to run all plays
ansible-playbook main.yaml -i ansible_hosts.cfg

# or run them manually
ansible-playbook install-docker.yaml -i ansible_hosts.cfg
ansible-playbook install-crio.yaml -i ansible_hosts.cfg

ansible-playbook install-kubernetes.yaml -i ansible_hosts.cfg
ansible-playbook initalize-cluster.yaml -i ansible_hosts.cfg
ansible-playbook deploy-sdn.yaml -i ansible_hosts.cfg
ansible-playbook install-helm.yaml -i ansible_hosts.cfg
ansible-playbook install-istio.yaml -i ansible_hosts.cfg
ansible-playbook install-vault.yaml -i ansible_hosts.cfg
```
