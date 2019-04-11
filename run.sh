echo "Provisioning servers..."
./provision-servers.sh
cd ansible
echo "Sleeping..."
sleep 30
echo "Waking up"
ansible-playbook run.yaml -i hosts.cfg
