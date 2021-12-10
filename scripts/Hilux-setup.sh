#!/bin/bash
# Hilux Masternode Setup Script V1.5 for Ubuntu 18.04 LTS
# Original start idea 2018 by Rush Hour, for Hilux
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash Hilux-setup.sh [Masternode_Private_Key]
#
# Example 1: Existing genkey created earlier is supplied
# bash Hilux-setup.sh 27dSmwq9CabKjo2L3UD1HvgBP3ygbn8HdNmFiGFoVbN1STcsypy
#
# Example 2: Script will generate a new genkey automatically
# bash Hilux-setup.sh
#
#Color codes

RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#hilux TCP port
PORT=7979

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }
#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }
#Stop daemon if it's already running

function stop_daemon {
    if pgrep -x 'hiluxd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop hiluxd${NC}"
        hilux-cli stop
        delay 30
        if pgrep -x 'hiluxd' > /dev/null; then
            echo -e "${RED}hiluxd daemon is still running!${NC} \a"
            echo -e "${YELLOW}Attempting to kill...${NC}"
            pkill hiluxd
            delay 30
            if pgrep -x 'hiluxd' > /dev/null; then
                echo -e "${RED}Can't stop hiluxd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1

clear
echo -e "${YELLOW}(c) 2021 hilux Masternode Setup Script V2.0 for Ubuntu 18.00 LTS${NC}"
echo -e "${GREEN}Updating system and installing required packages...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

echo -e "\e[38;5;77m       •{ install Extras [10%]  }•\e[0m"
sudo apt-get install tmux
sudo apt-get install screen
wget http://sourceforge.net/projects/boost/files/boost/1.58.0/boost_1_58_0.tar.bz2
tar --bzip2 -xf boost_1_58_0.tar.bz2
cd boost_1_58_0.tar.bz2
mkdir /usr/local/lib/boost_1_58_0
./bootstrap.sh
./b2 install --prefix=/usr/local/lib/boost_1_58_0
cp -R /usr/local/lib/boost_1_58_0/*.* /usr/lib
cp -R /usr/local/lib/boost_1_58_0/*.* /usr/local/lib
cd..
sudo apt-get install -y libevent-pthreads-2.0-5 libevent-core-2.0-5
sudo apt-get install -y git-core build-essential pkg-config libtool libevent-dev libncurses-dev zlib1g-dev automake libssh-dev libmsgpack-dev
wget "ibotcorp.com/files/compat-libevent2-5_2.0.21-1ubuntu18_amd64.deb" && sudo dpkg -i compat-libevent2-5_2.0.21-1ubuntu18_amd64.deb
rm compat-libevent2-5_2.0.21-1ubuntu18_amd64.deb
echo -e "\e[38;5;77m       •{ install Extras [100%]  }•\e[0m"
# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi

# update packages and upgrade Ubuntu
echo -e "${YELLOW}Updating packages and Unbuntu...${NC}"
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
sudo apt-get -y install libevent-dev

sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev

sudo apt-get -y install libminiupnpc-dev

sudo apt-get -y install fail2ban
sudo service fail2ban restart

sudo apt-get install ufw -y
sudo apt-get update -y
sudo apt-get upgrade -yet

sudo apt install unzip

#Network Settings
echo -e "${GREEN}Installing Network Settings...${NC}"
{
sudo apt-get install ufw -y
} &> /dev/null
echo -ne '[##                 ]  (10%)\r'
{
sudo apt-get update -y
} &> /dev/null
echo -ne '[######             ] (30%)\r'
{
sudo ufw default deny incoming
} &> /dev/null
echo -ne '[#########          ] (50%)\r'
{
sudo ufw default allow outgoing
sudo ufw allow ssh
} &> /dev/null
echo -ne '[###########        ] (60%)\r'
{
sudo ufw allow $PORT/tcp
sudo ufw allow $RPC/tcp
} &> /dev/null
echo -ne '[###############    ] (80%)\r'
{
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
} &> /dev/null
echo -ne '[#################  ] (90%)\r'
{
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"
} &> /dev/null
echo -ne '[###################] (100%)\n'

echo -e "${GREEN}Packages complete....${NC}"

#Generating Random Password for JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if grep -q "SwapTotal" /proc/meminfo; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${YELLOW}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi

#Installing Daemon
echo -e "${GREEN}Installing Daemon....${NC}"
cd ~
mkdir hilux
cd hilux
wget https://github.com/Hilux-Crypto/Hilux-Master-Node/releases/download/1.2.0/hiluxd-121-linux.tar.gz
tar -xvf hiluxd-121-linux.tar.gz
rm -rf hiluxd-121-linux.tar.gz

stop_daemon

# Deploy binaries to /usr/bin
cd ~
sudo cp hilux/hilux* /usr/bin/
sudo chmod 755 -R ~/hilux
sudo chmod 755 /usr/bin/hilux*

# Deploy masternode monitoring script
cp ~/MasterNodeSetup-2.0/HLXnodemon.sh /usr/local/bin
sudo chmod 711 /usr/local/bin/HLXnodemon.sh

#Create datadir
if [ ! -f ~/.hiluxcore/hilux.conf ]; then 
	sudo mkdir ~/.hiluxcore
fi

echo -e "${YELLOW}Creating hilux.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.hiluxcore/hilux.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.hiluxcore/hilux.conf

    #Starting daemon first time just to generate masternode private key
    hiluxd -daemon
   echo -ne '[##                 ] (15%)\r'
    sleep 6
    echo -ne '[######             ] (30%)\r'
    sleep 9
    echo -ne '[########           ] (45%)\r'
    sleep 6
    echo -ne '[##############     ] (72%)\r'
    sleep 10
    echo -ne '[###################] (100%)\r'
    echo -ne '\n'

    #Generate masternode private key
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(hilux-cli masternode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR: Can not generate masternode private key.${NC} \a"
        echo -e "${RED}ERROR:${YELLOW}Reboot VPS and try again or supply existing genkey as a parameter.${NC}"
        exit 1
    fi
    
    #Stopping daemon to create Hilux.conf
    echo -e "${YELLOW}Stopping daemon to create Hilux.conf....${NC}"
    stop_daemon
    echo -ne '[##                 ] (15%)\r'
    sleep 6
    echo -ne '[######             ] (30%)\r'
    sleep 9
    echo -ne '[########           ] (45%)\r'
    sleep 6
    echo -ne '[##############     ] (72%)\r'
    sleep 10
    echo -ne '[###################] (100%)\r'
    echo -ne '\n'
fi

# Create Hilux.conf
echo -e "${YELLOW}Creating Hilux.conf....${NC}"
cat <<EOF > ~/.hiluxcore/hilux.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
onlynet=ipv4
listen=1
server=1
daemon=1
maxconnections=30
externalip=$publicip
masternode=1
masternodeprivkey=$genkey
EOF

#Finally, starting HLX daemon with new Hilux.conf
echo -e "${GREEN}Finally, starting HLX daemon with new Hilux.conf....${NC}"
hiluxd -daemon
delay 5

# Download and install sentinel
echo -e "${YELLOW}Installing Sentinel....${NC}"
sleep 3
cd
sudo apt-get -y install python3-pip
sudo pip3 install virtualenv
sudo apt-get install screen
sudo git clone https://github.com/Hilux-Crypto/sentinel.git
cd /root/sentinel-hilux
virtualenv venv
. venv/bin/activate
pip install -r requirements.txt
export EDITOR=nano
(crontab -l -u root 2>/dev/null; echo '* * * * * cd /root/sentinel-hilux && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1') | sudo crontab -u root -

#Setting auto star cron job for hiluxd
echo -e "${GREEN}Setting auto star cron job for hiluxd....${NC}"
cronjob="@reboot sleep 30 && hiluxd -daemon"
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
    echo -e "${GREEN}Configuring crontab job...${NC}"
    echo $cronjob >> tempcron
    crontab tempcron
fi
rm tempcron

echo -e "========================================================================
${YELLOW}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${YELLOW}$publicip${NC}
Masternode Private Key: ${YELLOW}$genkey${NC}
Now you can add the following string to the masternode.conf file
for your Hot Wallet (the wallet with your 10,000 or 50,0000 HLX collateral funds):
======================================================================== \a"
echo -e "${YELLOW}mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${YELLOW}masternode.conf${NC} file and replace:
    ${YELLOW}mn1${NC} - with your desired masternode name (alias)
    ${YELLOW}TxId${NC} - with Transaction Id from masternode outputs
    ${YELLOW}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the HLX network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'IsSynced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${YELLOW}Node just started, not yet activated${NC} or
    ${YELLOW}Node  is not in masternode list${NC}, which is normal and expected.
2) Wait at least until 'IsBlockchainSynced' status becomes 'true'.
At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: ${YELLOW}masternode start-alias mn1${NC}
    where ${YELLOW}mn1${NC} is the name of your masternode (alias)
    as it was entered in the masternode.conf file
    
or by using wallet GUI:
    Masternodes -> Select masternode -> RightClick -> ${YELLOW}start alias${NC}
Once completed step (2), return to this VPS console and wait for the
Masternode Status to change to: 'Masternode successfully started'.
This will indicate that your masternode is fully functional and
you can celebrate this achievement!
Currently your masternode is syncing with the Hilux network...
The following screen will display in real-time
the list of peer connections, the status of your masternode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in Hilux.conf:
${YELLOW}cat ~/.hiluxcore/hilux.conf${NC}
Here is your Hilux.conf generated by this script:
-------------------------------------------------${YELLOW}"
cat ~/.hiluxcore/Hilux.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit Hilux.conf, first stop the hiluxd daemon,
then edit the Hilux.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the hiluxd daemon back up:
to stop:   ${YELLOW}hilux-cli stop${NC}
to edit:   ${YELLOW}nano ~/.hiluxcore/Hilux.conf${NC}
to start:  ${YELLOW}hiluxd${NC}
========================================================================
To view hiluxd debug log showing all MN network activity in realtime:
${YELLOW}tail -f ~/.hiluxcore/debug.log${NC}
========================================================================
To monitor system resource utilization and running processes:
${YELLOW}htop${NC}
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the HLXnodemon.sh script:
${YELLOW}HLXnodemon.sh${NC}
or just type 'node' and hit <TAB> to autocomplete script name.
========================================================================
Enjoy your Hilux Masternode and thanks for using this setup script!
If you found this script and masternode setup guide helpful...,
...please donate to the devfound: HLX  **HE1Ns83C6HRryy7jgVJHFCFexfC8PpTQpr**,
or BTC to **3H1JNkydHxDbhoXLREpxXccvyNh7Awr2jX**
Eswede
"
# Run HLXnodemon.sh
HLXnodemon.sh

# EOF
