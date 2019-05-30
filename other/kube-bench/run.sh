# install Go
curl -O https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz
tar xvf go1.12.1.linux-amd64.tar.gz
chown -R root:root ./go
mv go /usr/local
echo "export GOPATH=$HOME/work" >> ~/.profile
echo "export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin"  >> ~/.profile
source ~/.profile

# Install Kube-bench
go get github.com/aquasecurity/kube-bench
go get github.com/golang/dep/cmd/dep
cd $GOPATH/src/github.com/aquasecurity/kube-bench
$GOPATH/bin/dep ensure -vendor-only
go build -o kube-bench .

# Run the all checks
./kube-bench
