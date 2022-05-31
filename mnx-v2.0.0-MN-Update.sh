#!/bin/bash

#stop_daemon function
function stop_daemon {
    if pgrep -x 'nodetraded' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop nodetraded${NC}"
        nodetrade-cli stop
        sleep 30
        if pgrep -x 'nodetraded' > /dev/null; then
            echo -e "${RED}nodetraded daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 nodetraded
            sleep 30
            if pgrep -x 'nodetraded' > /dev/null; then
                echo -e "${RED}Can't stop nodetraded! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}


echo "Your Nodetrade Masternode Will be Updated To The Latest Version v2.0.0 Now" 
sudo apt-get -y install unzip

#remove crontab entry to prevent daemon from starting
crontab -l | grep -v 'mnxauto.sh' | crontab -

#Stop nodetraded by calling the stop_daemon function
stop_daemon

rm -rf /usr/local/bin/nodetrade*
mkdir MNX_2.0.0
cd MNX_2.0.0
wget https://github.com/IDCHAINGROUP/MNX/releases/download/v2.0.0/mnx-2.0.0-ubuntu-daemon.tar.gz
tar -xzvf mnx-2.0.0-ubuntu-daemon.tar.gz
mv nodetraded /usr/local/bin/nodetraded
mv nodetrade-cli /usr/local/bin/nodetrade-cli
chmod +x /usr/local/bin/nodetrade*
rm -rf ~/.nodetrade/blocks
rm -rf ~/.nodetrade/chainstate
rm -rf ~/.nodetrade/sporks
rm -rf ~/.nodetrade/peers.dat
cd ~/.nodetrade/
wget https://github.com/IDCHAINGROUP/MNX/releases/download/v2.0.0/bootstrap.zip
unzip bootstrap.zip

cd ..
rm -rf ~/.nodetrade/bootstrap.zip ~/MNX_2.0.0

sudo mkdir ~/.nodetrade-params
cd ~/.nodetrade-params && wget https://github.com/IDCHAINGROUP/MNX/raw/main/params/sapling-output.params && wget https://github.com/IDCHAINGROUP/MNX/raw/main/params/sapling-spend.params	
cd ..

# add new nodes to config file
sed -i '/addnode/d' ~/.nodetrade/nodetrade.conf

echo "addnode=45.76.9.162
addnode=45.77.105.52
addnode=45.77.98.136
addnode=45.77.153.2" >> ~/.nodetrade/nodetrade.conf

#start nodetraded
nodetraded -daemon

printf '#!/bin/bash\nif [ ! -f "~/.nodetradecoin/nodetrade.pid" ]; then /usr/local/bin/nodetraded -daemon ; fi' > /root/mnxauto.sh
chmod -R 755 /root/mnxauto.sh
#Setting auto start cron job for Nodetrade
if ! crontab -l | grep "mnxauto.sh"; then
    (crontab -l ; echo "*/5 * * * * /root/mnxauto.sh")| crontab -
fi

echo "Masternode Updated!"
echo "Please wait a few minutes and start your Masternode again on your Local Wallet"