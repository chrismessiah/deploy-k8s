echo "Provisioning servers..."
./provision-servers.sh
cd ansible
echo "Sleeping..."
sleep 30
echo "Waking up"
ansible-playbook main.yaml -i hosts.cfg

KERNEL=$(uname)
if [ "$KERNEL" == "Darwin" ]; then
	say "Cluster setup complete" -v Samantha
	osascript -e 'display notification "Cluster setup complete"'
fi

watch -n 2 kubectl get pods --all-namespaces
