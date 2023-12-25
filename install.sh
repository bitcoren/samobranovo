#!/usr/bin/env bash

mkdir temp apps
sudo chmod 777 data
echo PATH="$PATH:/home/$USER/.local/bin:/opt/firebird/bin:/usr/local/go/bin:$PWD/bin" | sudo tee /etc/environment
echo SAMOBRANOVO="$PWD" | sudo tee -a /etc/environment
sudo sed -i 's/usr\/local\/sbin/opt\/firebird\/bin\:\/usr\/local\/sbin/g' /etc/sudoers
source /etc/environment
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -yq
sudo DEBIAN_FRONTEND=noninteractive apt install -y build-essential libssl-dev libffi-dev python3-dev python3-pip python3-venv tmux
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

wget -O temp/go.tar.gz https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf temp/go.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
git clone -b v1.53.2 --recurse-submodules https://github.com/anacrolix/torrent temp/torrent
go install github.com/anacrolix/torrent/cmd/...@latest
cd /opt/samobranovo/temp/torrent/fs/cmd/torrentfs
go install
cd $SAMOBRANOVO
cp ~/go/bin/* bin/

sleep 9
rm -rf temp
mkdir temp
sudo reboot
