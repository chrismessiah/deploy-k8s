# to run all plays
ansible-playbook run.yaml -i hosts.cfg

# or run them manually
ansible-playbook install-docker.yaml -i hosts.cfg
ansible-playbook install-crio.yaml -i hosts.cfg

ansible-playbook install-kubernetes.yaml -i hosts.cfg
ansible-playbook initalize-cluster.yaml -i hosts.cfg
ansible-playbook deploy-sdn.yaml -i hosts.cfg
ansible-playbook install-helm.yaml -i hosts.cfg
ansible-playbook install-istio.yaml -i hosts.cfg
