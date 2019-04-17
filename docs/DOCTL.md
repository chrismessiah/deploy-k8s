```bash
DO_KEYS="24225182,24202611"
DO_COMPUTE_SIZE="s-2vcpu-4gb"

doctl compute droplet create vault \
  --ssh-keys $DO_KEYS \
  --region lon1 \
  --image ubuntu-18-04-x64 \
  --size $DO_COMPUTE_SIZE  \
  --format ID,Name,PublicIPv4,PrivateIPv4,Status \
  --enable-private-networking \
  --wait
```
