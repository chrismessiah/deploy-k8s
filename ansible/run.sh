ansible-playbook install-docker.yaml -i ansible.conf
ansible-playbook install-kubernetes.yaml -i ansible.conf
ansible-playbook initalize-cluster.yaml -i ansible.conf
ansible-playbook deploy-sdn.yaml -i ansible.conf


# ansible-playbook install-crio.yaml -i ansible.conf
