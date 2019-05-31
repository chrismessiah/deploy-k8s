brew install doctl
brew install hcloud

brew install kontena/chpharos/chpharos
echo "source /usr/local/opt/chpharos/share/chpharos/chpharos.sh" >> ~/.bash_profile
source ~/.bash_profile

chpharos login

chpharos install latest --use
