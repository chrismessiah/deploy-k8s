# TSHARK CheetSheet

```sh
# use tshark to filter away own ip and only UDP (due to VXLAN)
apt install -y tshark iftop

# capture filters
tshark -f 'not host 77.218.255.217'
tshark -f '(not host 206.189.28.133) and (not host 77.218.255.222)'
tshark -f '(not host 206.189.28.133) and (not host 77.218.255.221) and (not host 213.86.144.41) and (not host 206.189.12.73)'
tshark -f 'udp'
tshark -f 'port 290'
tshark -f 'not tcp'

# display filters
tshark -Y http

# interface
tshark -i flannel.1

# total
tshark -i flannel.1 -Y http
tshark -i cali041b8026940 -Y http
tshark -i calif48e9637a36 -Y http

curl http://10.244.2.2:3000
```
