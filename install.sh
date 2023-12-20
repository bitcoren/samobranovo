#!/usr/bin/env bash

mkdir temp apps
sudo chmod 777 data
echo PATH="$PATH:/home/$USER/.local/bin:/opt/firebird/bin:$PWD/bin" | sudo tee /etc/environment
echo SAMOBRANOVO="$PWD" | sudo tee -a /etc/environment
sudo sed -i 's/usr\/local\/sbin/opt\/firebird\/bin\:\/usr\/local\/sbin/g' /etc/sudoers
source /etc/environment
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -yq
sudo DEBIAN_FRONTEND=noninteractive apt install -y build-essential libssl-dev libffi-dev python3-dev python3-pip python3-venv tmux btfs
python3 -m venv venv
source venv/bin/activate
pip3 install feedparser fdb
wget -O temp/firebird.tar.gz https://github.com/FirebirdSQL/firebird/releases/download/v5.0.0-RC2/Firebird-5.0.0.1304-RC2-linux-x64.tar.gz
tar xvzf temp/firebird.tar.gz -C temp
sudo DEBIAN_FRONTEND=noninteractive apt install -y libtommath-dev
mv temp/Firebird-5.0.0.1304-RC2-linux-x64 temp/firebird
cd temp/firebird
echo "vm.max_map_count = 256000" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
sudo ./install.sh << 'EOF'

samobranovo
EOF
sudo usermod -a -G firebird $USER
cd $SAMOBRANOVO

export IPFS_PATH=/opt/samobranovo/data/.ipfs
wget -O temp/kubo.tar.gz https://github.com/ipfs/kubo/releases/download/v0.25.0/kubo_v0.25.0_linux-amd64.tar.gz
tar xvzf temp/kubo.tar.gz -C temp
sudo mv temp/kubo/ipfs /usr/local/bin/ipfs
ipfs init --profile server
ipfs config --json Experimental.FilestoreEnabled true
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


sleep 9
rm -rf temp
mkdir temp
sudo reboot
