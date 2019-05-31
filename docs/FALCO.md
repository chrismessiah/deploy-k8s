```bash
# Docker install method
apt-get -y install linux-headers-$(uname -r)
docker pull falcosecurity/falco
docker run \
    -i \
    -t \
    --name falco \
    --privileged \
    -v /var/run/docker.sock:/host/var/run/docker.sock \
    -v /dev:/host/dev \
    -v /proc:/host/proc:ro \
    -v /boot:/host/boot:ro \
    -v /lib/modules:/host/lib/modules:ro \
    -v /usr:/host/usr:ro \
    falcosecurity/falco

# Scripted Linux install method
curl -o install-falco.sh -s https://s3.amazonaws.com/download.draios.com/stable/install-falco
md5sum install-falco.sh | grep "3632bde02be5aeaef522138919cfece2"
./install-falco.sh

# Debian install method
curl -s https://s3.amazonaws.com/download.draios.com/DRAIOS-GPG-KEY.public | apt-key add -
curl -s -o /etc/apt/sources.list.d/draios.list https://s3.amazonaws.com/download.draios.com/stable/deb/draios.list
apt-get update
apt-get -y install linux-headers-$(uname -r)
apt-get install -y falco
```
