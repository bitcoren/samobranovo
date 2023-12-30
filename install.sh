#!/usr/bin/env bash

current_dir=$(pwd)
if [ "$current_dir" != "/opt/samobranovo" ]; then
    echo "Current directory is not /opt/samobranovo, moving..."
    cd /opt && sudo mkdir samobranovo && sudo chmod 777 samobranovo && sudo chown $USER:$USER samobranovo
    sudo mv $current_dir /opt
else
    echo "Already in /opt/samobranovo"
fi

cd /opt/samobranovo
mkdir temp apps
sudo chmod 777 data
echo PATH="$PATH:/home/$USER/.local/bin:/opt/firebird/bin:/usr/local/go/bin:$PWD/bin" | sudo tee /etc/environment
echo SAMOBRANOVO="$PWD" | sudo tee -a /etc/environment
echo IPFS_PATH="/opt/samobranovo/data/.ipfs" | sudo tee -a /etc/environment
sudo sed -i 's/usr\/local\/sbin/opt\/firebird\/bin\:\/usr\/local\/sbin/g' /etc/sudoers
source /etc/environment
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -yq
sudo DEBIAN_FRONTEND=noninteractive apt install -y build-essential libssl-dev libffi-dev python3-dev python3-pip python3-venv tmux
python3 -m venv venv
source venv/bin/activate
pip3 install feedparser fdb
if [[ $(uname -m) == "x86_64" ]]; then
  echo "x86_64 64-bit CPU detected"
  wget -O temp/firebird.tar.gz https://github.com/FirebirdSQL/firebird/releases/download/v5.0.0-RC2/Firebird-5.0.0.1304-RC2-linux-x64.tar.gz
else
  echo "ARM 64-bit CPU detected"
  wget -O temp/firebird.tar.gz https://github.com/FirebirdSQL/firebird/releases/download/v5.0.0-RC2/Firebird-5.0.0.1304-RC2-linux-arm64.tar.gz
fi
tar xvzf temp/firebird.tar.gz -C temp
sudo DEBIAN_FRONTEND=noninteractive apt install -y libtommath-dev
cd temp && find . -type d -name "Firebird*" -exec mv {} firebird \;
cd firebird
echo "vm.max_map_count = 256000" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
sudo ./install.sh << 'EOF'

samobranovo
EOF
sudo usermod -a -G firebird $USER
cd $SAMOBRANOVO

if [[ $(uname -m) == "x86_64" ]]; then
  echo "x86_64 64-bit CPU detected"
  wget -O temp/go.tar.gz https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
else
  echo "ARM 64-bit CPU detected"
  wget -O temp/firebird.tar.gz https://go.dev/dl/go1.21.5.linux-arm64.tar.gz
fi
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf temp/go.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
git clone -b v1.53.2 --recurse-submodules https://github.com/anacrolix/torrent temp/torrent
go install github.com/anacrolix/torrent/cmd/...@latest
cd /opt/samobranovo/temp/torrent/fs/cmd/torrentfs
go install
cd $SAMOBRANOVO
cp ~/go/bin/* bin/

export IPFS_PATH=/opt/samobranovo/data/.ipfs
wget -O temp/kubo.tar.gz https://github.com/ipfs/kubo/releases/download/v0.25.0/kubo_v0.25.0_linux-amd64.tar.gz
tar xvzf temp/kubo.tar.gz -C temp
sudo mv temp/kubo/ipfs /usr/local/bin/ipfs
ipfs init --profile server
ipfs config --json Experimental.FilestoreEnabled true
ipfs config --json Pubsub.Enabled true
ipfs config --json Ipns.UsePubsub true
echo -e "\
[Unit]\n\
Description=InterPlanetary File System (IPFS) daemon\n\
Documentation=https://docs.ipfs.tech/\n\
After=network.target\n\
\n\
[Service]\n\
MemorySwapMax=0\n\
TimeoutStartSec=infinity\n\
Type=notify\n\
User=$USER\n\
Group=$USER\n\
Environment=IPFS_PATH=/opt/samobranovo/data/.ipfs\n\
ExecStart=/usr/local/bin/ipfs daemon --enable-gc\n\
Restart=on-failure\n\
KillSignal=SIGINT\n\
\n\
[Install]\n\
WantedBy=default.target\n\
" | sudo tee /etc/systemd/system/ipfs.service
sudo systemctl daemon-reload
sudo systemctl enable ipfs
sudo systemctl start ipfs

echo -e "\
[Unit]\n\
Description=InterPlanetary File System (IPFS) subscription\n\
After=ipfs.target\n\
\n\
[Service]\n\
Type=simple\n\
User=$USER\n\
Group=$USER\n\
Environment=IPFS_PATH=/opt/samobranovo/data/.ipfs\n\
ExecStart=/opt/samobranovo/bin/ipfssub.sh\n\
Restart=on-failure\n\
KillSignal=SIGINT\n\
\n\
[Install]\n\
WantedBy=default.target\n\
" | sudo tee /etc/systemd/system/ipfssub.service
sudo systemctl daemon-reload
sudo systemctl enable ipfssub
sudo systemctl restart ipfssub
sleep 9

(echo -n "$(date) Samobranovo system is installed" && ipfs id | grep \"ID\":) >> /opt/samobranovo/data/log.txt
ipfspub 'Initial message'
ipfs pubsub pub samobranovo /opt/samobranovo/data/log.txt

sleep 9
rm -rf temp
mkdir temp
sudo reboot
