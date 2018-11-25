#!/bin/bash

TMP_FOLDER=$(mktemp -d)

DAEMON_ARCHIVE=${1:-"https://github.com/Moondex/MoonDEXCoin/releases/download/v2.0.1.1/linux-no-gui-v2.0.1.1.tar.gz"}
SENTINEL_ARCHIVE=https://github.com/Moondex/moondex_sentinel/archive/master.zip
ARCHIVE_STRIP=""
DEFAULT_PORT=8906
DEFAULT_RPCPORT=8960

COIN_NAME="moondex"
CONFIG_FILE="${COIN_NAME}.conf"
DEFAULT_USER_NAME="${COIN_NAME}-mn1"
DAEMON_FILE="${COIN_NAME}d"
CLI_FILE="${COIN_NAME}-cli"

BINARIES_PATH=/usr/local/bin
DAEMON_PATH="${BINARIES_PATH}/${DAEMON_FILE}"
CLI_PATH="${BINARIES_PATH}/${CLI_FILE}"

DONATION_ADDRESS=XoDpG5yrZ3UTtAywge5wNZAbhmxJi7SZbh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

export LC_ALL=C


#************************************************************************************************
# Confirm proper OS and user, and check if this is a 1st installation
#************************************************************************************************
function checks()
{
  if [[ $(lsb_release -d) != *16.04* ]]; then     # If not running correct version of Ubuntu
    echo -e " ${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
    exit 1
  fi

  if [[ $EUID -ne 0 ]]; then                      # If the user is NOT the root user
     echo -e " ${RED}$0 must be run as root so it can update your system and create the required masternode users.${NC}"
     exit 1
  fi

  if [ -n "$(pidof ${DAEMON_FILE})" ]; then       # If the MDEX MN daemon was found to already be running (existing MN found)
    read -e -p " $(echo -e The ${COIN_NAME} daemon is already running.${YELLOW} Do you want to add another master node? [Y/N] $NC)" NEW_NODE
    clear
    echo -e "${NC}"
  else                                            # If no other MDEX MN is found to be running, this is a new MN
    NEW_NODE="new"
  fi
}


#************************************************************************************************
# Perform updates, upgrades, and install dependencies
#************************************************************************************************
function prepare_system()
{
  clear
  echo -e "Checking if swap space is required."
  local PHYMEM=$(free -g | awk '/^Mem:/{print $2}')

  if [ "${PHYMEM}" -lt "2" ]; then
    local SWAP=$(swapon -s get 1 | awk '{print $1}')
    if [ -z "${SWAP}" ]; then
      echo -e "${GREEN}Server is running without a swap file and has less than 4G of RAM, creating a 4G swap file.${NC}"
      dd if=/dev/zero of=/swapfile bs=1024 count=4M
      chmod 600 /swapfile
      mkswap /swapfile
      swapon -a /swapfile
      echo "/swapfile    none    swap    sw    0   0" >> /etc/fstab
    else
      echo -e "${GREEN}Swap file already exists.${NC}"
    fi
  else
    echo -e "${GREEN}Server running with at least 4G of RAM, no swap file needed.${NC}"
  fi

  echo -e "${GREEN}Updating package manager.${NC}"
  apt update

  echo -e "${GREEN}Upgrading existing packages, it may take some time to finish.${NC}"
  DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade

  echo -e "${GREEN}Installing all dependencies for the ${COIN_NAME} coin master node, it may take some time to finish.${NC}"
  apt install -y software-properties-common
  apt-add-repository -y ppa:bitcoin/bitcoin
  apt update
  apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    automake \
    bsdmainutils \
    build-essential \
    curl \
    git \
    htop \
    libboost-chrono-dev \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libdb4.8-dev \
    libdb4.8++-dev \
    libdb5.3++ \
    libevent-dev \
    libgmp3-dev \
    libminiupnpc-dev \
    libssl-dev \
    libtool autoconf \
    libzmq5 \
    make \
    pkg-config \
    pwgen \
    python-virtualenv \
    software-properties-common \
    tar \
    ufw \
    unzip \
    virtualenv \
    wget
  clear
}


#************************************************************************************************
# Install the binaries if they are not already installed.
#************************************************************************************************
function deploy_binary()
{
  if [ -f ${DAEMON_PATH} ]; then      # If the executable is found in the expected place, don't bother installing it
    echo -e " ${GREEN}${COIN_NAME} daemon binary file already exists in expected location [${DAEMON_PATH}].  Using this binary.${NC}"
  else
    cd ${TMP_FOLDER}

    local archive=${COIN_NAME}.tar.gz
    echo -e " ${GREEN}Downloading ${DAEMON_ARCHIVE} and deploying the ${COIN_NAME} service.${NC}"
    wget ${DAEMON_ARCHIVE} -O ${archive}

    tar xvzf ${archive}${ARCHIVE_STRIP} >/dev/null 2>&1
    cp ${DAEMON_FILE} ${CLI_FILE} ${BINARIES_PATH}
    chmod +x ${DAEMON_PATH} >/dev/null 2>&1
    chmod +x ${CLI_PATH} >/dev/null 2>&1
    cd

    rm -rf ${TMP_FOLDER}
  fi
}


#************************************************************************************************
# Ask for user name for the MN to be run under.  It will not run under root.
#  Creates the user and password, which will be reported near the end of the script.
#************************************************************************************************
function ask_user()
{
  read -e -p "$(echo -e $YELLOW Enter a new username to run the ${COIN_NAME} service as: $NC)" -i ${DEFAULT_USER_NAME} USER_NAME

  if [ -z "$(getent passwd ${USER_NAME})" ]; then
    useradd -m ${USER_NAME}
#    local USERPASS=$(pwgen -s 12 1)
    USERPASS=$(pwgen -s 12 1)
    echo "${USER_NAME}:${USERPASS}" | chpasswd

    USER_HOME=$(sudo -H -u ${USER_NAME} bash -c 'echo ${HOME}')
    HOME_FOLDER="${USER_HOME}/.${COIN_NAME}core"

    mkdir -p ${HOME_FOLDER}
    chown -R ${USER_NAME}: ${HOME_FOLDER} >/dev/null 2>&1
  else
    clear
    echo -e "${RED}User already exists. Please enter another username.${NC}"
    ask_user
  fi
}


#************************************************************************************************
# MDEX requires all MNs to use port 8906.
# Below comment lines disable original code giving the user an option for the port.
#************************************************************************************************
function check_port()
{
  PORT=${DEFAULT_PORT}
  echo -e "${YELLOW}Using mandatory MDEX port ${PORT}.${NC}"
#  declare -a PORTS

#  PORTS=($(netstat -tnlp | awk '/LISTEN/ {print $4}' | awk -F":" '{print $NF}' | sort | uniq | tr '\r\n'  ' '))
#  ask_port

#  while [[ ${PORTS[@]} =~ ${PORT} ]] || [[ ${PORTS[@]} =~ $[PORT+1] ]]; do
#    clear
#    echo -e "${RED}Port in use, please choose another port:${NF}"
#    ask_port
#  done
}


#************************************************************************************************
# Ask for port to use. This should not be changed from the default
# All MNs on the VPS should use the same port (they will use different rpcport values though).
#************************************************************************************************
function ask_port()
{
  read -e -p "$(echo -e $YELLOW Enter a port to run the ${COIN_NAME} service on: $NC)" -i ${DEFAULT_PORT} PORT
}


#************************************************************************************************
# Query user for the desired port number to use.  If it is already in use, ask for a different
#  port.
#************************************************************************************************
function check_rpcport()
{
  declare -a PORTS

  PORTS=($(netstat -tnlp | awk '/LISTEN/ {print $4}' | awk -F":" '{print $NF}' | sort | uniq | tr '\r\n'  ' '))
  ask_rpcport

  while [[ ${PORTS[@]} =~ ${RPCPORT} ]] || [[ ${PORTS[@]} =~ $[RPCPORT+1] ]]; do
    clear
    echo -e "${RED}Port in use, please choose another port:${NF}"
    ask_rpcport
  done
}


#************************************************************************************************
# Ask for rpcport to use.
# Should be different from port value, and should be unique for each MN on the VPS.
# The default value for rpcport should work for the first MN, but should be incremented for any
#  additional MNs on the VPS.
#************************************************************************************************
function ask_rpcport()
{
  echo
  echo -e "${YELLOW}Recommended values for RPCPORT${NF}"
  echo -e "${YELLOW}  1st MDEX Masternode on VPS: 8960${NF}"
  echo -e "${YELLOW}  2nd MDEX Masternode on VPS: 8961${NF}"
  echo -e "${YELLOW}  3rd MDEX Masternode on VPS: 8962${NF}"
  read -e -p "$(echo -e $YELLOW Enter an rpcport to run the ${COIN_NAME} service on: $NC)" -i ${DEFAULT_RPCPORT} RPCPORT
}


#************************************************************************************************
# Query the available IP addresses on the machine.  Note that while it will identify IPv6
#  addresses, and a MN with an IPv6 address will sync, we have thus far been unable to get
#  IPv6 to work on the local wallet side.  Therefore, IPv6 is not recommended at present.
#************************************************************************************************
function ask_ip()
{
  declare -a NODE_IPS
  declare -a NODE_IPS_STR

  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')    #For each available interface (ens3, ens3:1, etc.)
  do
    ipv4=$(curl --interface ${ips} --connect-timeout 2 -s4 icanhazip.com) #Get IP for current interface ID and assign to ipv4
    NODE_IPS+=(${ipv4})                                                 #Add current IP to array of ipv4 addresses
    NODE_IPS_STR+=("$(echo -e [IPv4] ${ipv4})")                         #Add new line to string array of addresses

#    ipv6=$(curl --interface ${ips} --connect-timeout 2 -s6 icanhazip.com)
#    NODE_IPS+=(${ipv6})
    #Below doesn't work right if IPv6 isn't set up on the MN (reports blank IP)

#if [[ ${ipv6} == "" ]]; then    #Trap case where IPv6 was not enabled on VPS and reports a null string for address
#  NODE_IPS_STR+=("$(echo -e [IPv6] ${RED}Not available${NC})")
#  #echo -e "ipv6 appears to be blank."
#else
#  NODE_IPS_STR+=("$(echo -e [IPv6] ${ipv6})")
#fi
  done

  echo
  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e " ${GREEN}More than one IP address found (${#NODE_IPS[@]} found).${NC}"
      INDEX=0
      for ip in "${NODE_IPS_STR[@]}"
      do
        echo -e " [${INDEX}] ${ip}"
        let INDEX=${INDEX}+1
      done
      #echo -e " ${YELLOW}Note that Masternodes using IPv6 addresses may not function properly at present.${NC}"

      NODEIP=""
      while [[ "$NODEIP" = "" ]]
      do
          echo -e " ${YELLOW}Which IP address do you want to use? Enter number 0,1,2,etc.${NC}"
          read -e choose_ip
          NODEIP=${NODE_IPS[$choose_ip]}

          if [[ -z "${NODEIP}" ]]; then     #Check for invalid IP address selection (number outside of range)
              echo -e " ${RED}Invalid IP address selection: ${choose_ip}. Try again.${NC}"
              sleep 1.0s
              NODEIP=""
          else
              echo -e " ${YELLOW}Selected IP address: ${NODEIP}${NC}"
              echo -e "${NC}"
          fi
      done

  else
    NODEIP=${NODE_IPS[0]}
    echo -e "${NC}"
  fi
}


#************************************************************************************************
# Assign genkey, creating one if necessary
#************************************************************************************************
function create_key()
{

  #read -e -p "$(echo -e ${YELLOW}Paste your masternode private key and press ENTER or leave it blank to generate a new private key using genkey.$NC)" PRIVKEY
  echo -e " ${YELLOW}Paste your masternode private key and press ENTER or leave it blank to generate a new private key using genkey.${NC}"
  read -e PRIVKEY

  if [[ -z "${PRIVKEY}" ]]; then
      echo -e " ${YELLOW}No key entered. Generating new private key...${NC}"
      get_key
  fi
  echo -e "${NC}"
}


#************************************************************************************************
# Generate a new private key
#************************************************************************************************
function get_key()
{
  sudo -u ${USER_NAME} ${DAEMON_PATH} -datadir=${HOME_FOLDER} -conf=${HOME_FOLDER}/${CONFIG_FILE} -daemon >/dev/null 2>&1
  sleep 5

  if [ -z "$(pidof ${DAEMON_FILE})" ]; then
    echo -e "${RED}${COIN_NAME} deamon couldn't start, could not generate a private key. Check /var/log/syslog for errors.${NC}"
    exit 1
  fi

  local privkey=$(sudo -u ${USER_NAME} ${CLI_PATH} -datadir=${HOME_FOLDER} -conf=${HOME_FOLDER}/${CONFIG_FILE} masternode genkey 2>&1)
  if [[ -z "${privkey}" ]] || [[ "${privkey^^}" = *"ERROR"* ]];
  then
    local retry=5
    echo -e "${GREEN} - Unable to request private key, node not ready, retrying in ${retry} seconds ...${NC}"
    sleep ${retry}

    get_key
  else
    echo -e "${GREEN} - Privkey successfully generated${NC}"
    PRIVKEY=${privkey}

    sudo -u ${USER_NAME} ${CLI_PATH} -datadir=${HOME_FOLDER} -conf=${HOME_FOLDER}/${CONFIG_FILE} stop >/dev/null 2>&1
    sleep 5
  fi
}


#************************************************************************************************
# Create the configuration file (also see update_config)
#************************************************************************************************
function create_config()
{
  RPCUSER=$(pwgen -s 8 1)
  RPCPASSWORD=$(pwgen -s 15 1)

#Create moondex.conf file (overwriting any previous contents)
  cat << EOF > ${HOME_FOLDER}/${CONFIG_FILE}
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
rpcallowip=127.0.0.1
port=${PORT}
rpcport=${RPCPORT}
listen=1
server=1
daemon=1
staking=1

logtimestamps=1
maxconnections=256
masternode=1

masternodeprivkey=${PRIVKEY}
externalip=${NODEIP}
EOF

# If this is not the first MN on the VPS, then define the bind address.
# Add any bind= text to end of moondex.conf file (appending to any previous contents)
if [ -n "$(pidof ${DAEMON_FILE})" ]; then       # If the MDEX MN daemon was found to already be running (existing MN found)
  cat << EOF >> ${HOME_FOLDER}/${CONFIG_FILE}
bind=${NODEIP}

EOF
else                                            # If no other MDEX MN is found to be running, this is a new MN

#Note that the below code option (declaring bind even on 1st MN usually works.)
  cat << EOF >> ${HOME_FOLDER}/${CONFIG_FILE}
bind=${NODEIP}

EOF
fi

}


#************************************************************************************************
# Add some peer nodes to the configuration file (also see create_config)
#************************************************************************************************
function update_config()
{
  # Add lines to end of moondex.conf file (appending to any previous contents)
  cat << EOF >> ${HOME_FOLDER}/${CONFIG_FILE}

addnode=45.32.140.21
addnode=104.18.51.247
addnode=149.28.251.54
addnode=149.28.106.146
addnode=104.238.162.199
EOF
#chown ${USER_NAME}: ${HOME_FOLDER}/${CONFIG_FILE} >/dev/null
  chown ${USER_NAME} ${HOME_FOLDER}/${CONFIG_FILE} >/dev/null
}


#************************************************************************************************
# set up firewall
#************************************************************************************************
function enable_firewall()
{
  echo -e " ${GREEN}Installing fail2ban and setting up firewall to allow access on port ${PORT}.${NC}"

  apt install ufw -y >/dev/null 2>&1

  ufw disable >/dev/null 2>&1
  ufw allow ${PORT}/tcp comment "${COIN_NAME} Masternode port" >/dev/null 2>&1

  ufw allow 22/tcp comment "SSH port" >/dev/null 2>&1
  ufw limit 22/tcp >/dev/null 2>&1

  ufw logging on >/dev/null 2>&1
  ufw default deny incoming >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1

  echo "y" | ufw enable >/dev/null 2>&1
  systemctl enable fail2ban >/dev/null 2>&1
  systemctl start fail2ban >/dev/null 2>&1
}


#************************************************************************************************
# Set up and deploy sentinel for MN
#************************************************************************************************
function deploy_sentinel()
{
  echo -e "${GREEN} Deploying sentinel.${NC}"

  local tmp_folder=$(mktemp -d)
  cd ${tmp_folder}

  wget ${SENTINEL_ARCHIVE} -O sentinel.zip
  unzip sentinel.zip

  mv ./moondex_sentinel-master ${USER_HOME}/.sentinel

  cd  ${USER_HOME}/.sentinel
  virtualenv ./venv
  ./venv/bin/pip install -r requirements.txt
  chown -R ${USER_NAME}: ${USER_HOME}

  echo "moondex_conf=${HOME_FOLDER}/moondex.conf" >> ${USER_HOME}/.sentinel/sentinel.conf

  echo -e "${GREEN} Creating sentinel schedule${NC}"
  crontab -l > tempcron

  echo "* * * * * cd ${USER_HOME}/.sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> tempcron
  crontab tempcron
  rm tempcron

  SENTINEL_DEBUG=1

  rm -rf ${tmp_folder}
  echo -e "${GREEN} Sentinel Installed${NC}"
}


#************************************************************************************************
# Configure and start the MN daemon
#************************************************************************************************
function add_daemon_service()
{
  cat << EOF > /etc/systemd/system/${USER_NAME}.service
[Unit]
Description=${COIN_NAME} masternode daemon service
After=network.target
After=syslog.target
[Service]
Type=forking
User=${USER_NAME}
Group=${USER_NAME}
WorkingDirectory=${HOME_FOLDER}
ExecStart=${DAEMON_PATH} -datadir=${HOME_FOLDER} -conf=${HOME_FOLDER}/$CONFIG_FILE -daemon
ExecStop=${CLI_PATH} stop
Restart=always
RestartSec=3
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3

  echo -e " ${GREEN}Starting the ${COIN_NAME} service from ${DAEMON_PATH} on port ${PORT}.${NC}"
  systemctl start ${USER_NAME}.service >/dev/null 2>&1

  echo -e " ${GREEN}Enabling the service to start on reboot.${NC}"
  systemctl enable ${USER_NAME}.service >/dev/null 2>&1

  if [[ -z $(pidof $DAEMON_FILE) ]]; then
    echo -e "${RED}The ${COIN_NAME} masternode service is not running${NC}. You should start by running the following commands as root:"
    echo "systemctl start ${USER_NAME}.service"
    echo "systemctl status ${USER_NAME}.service"
    echo "less /var/log/syslog"
    exit 1
  fi
}


#************************************************************************************************
# Manage log files
#************************************************************************************************
function add_log_truncate()
{
  LOG_FILE="${HOME_FOLDER}/debug.log";

  cat << EOF >> /home/${USER_NAME}/logrotate.conf
${HOME_FOLDER}/*.log {
    rotate 4
    weekly
    compress
    missingok
    notifempty
}
EOF

  if ! crontab -l >/dev/null | grep "/home/${USER_NAME}/logrotate.conf"; then
    (crontab -l ; echo "1 0 * * 1 /usr/sbin/logrotate /home/${USER_NAME}/logrotate.conf --state /home/${USER_NAME}/logrotate-state") | crontab -
  fi
}


#************************************************************************************************
# After installation and start, report configuration information to user.
#************************************************************************************************
function show_output()
{
 echo
 echo -e "================================================================================================================================"
 echo -e "${GREEN}"
 echo -e "                                                 ${COIN_NAME} installation completed${NC}"
 echo
 echo -e " Your ${COIN_NAME} coin master node is up and running."
 echo -e "  - it is running as the ${GREEN}${USER_NAME}${NC} user, listening on port ${GREEN}${PORT}${NC} at your VPS address ${GREEN}${NODEIP}${NC}."
 echo -e "  - the ${GREEN}${USER_NAME}${NC} password is ${GREEN}${USERPASS}${NC}"
 echo -e "  - the ${GREEN}RPCPORT${NC} is ${GREEN}${RPCPORT}${NC}"
 echo -e "  - the ${COIN_NAME} configuration file is located at ${GREEN}${HOME_FOLDER}/${CONFIG_FILE}${NC}"
 echo -e "  - the masternode privkey is ${GREEN}${PRIVKEY}${NC}"
 echo
 echo -e " You can manage your ${COIN_NAME} service from the cmdline with the following commands:"
 echo -e "  - ${GREEN}systemctl start ${USER_NAME}.service${NC} to start the service for the given user."
 echo -e "  - ${GREEN}systemctl stop ${USER_NAME}.service${NC} to stop the service for the given user."
 echo -e "  - ${GREEN}systemctl status ${USER_NAME}.service${NC} to see the service status for the given user."
 echo
 echo -e " The installed service is set to:"
 echo -e "  - auto start when your VPS is rebooted."
 echo -e "  - rotate your ${GREEN}${LOG_FILE}${NC} file once per week and keep the last 4 weeks of logs."
 echo
 echo -e " Log in as ${GREEN}${USER_NAME}${NC} using ${YELLOW}su ${USER_NAME}${NC} so that you can get information on your Masternode using the below commands:"
 echo -e "  - ${GREEN}${CLI_FILE} getinfo${NC} to retreive your node's status and information"
 echo -e "  - ${GREEN}${CLI_FILE} mnsync status${NC} to retreive a sync status summary"
 echo -e "  - ${GREEN}${CLI_FILE} masternode status${NC} to retreive a masternode status summary"
 echo
 #echo -e "   running the ${GREEN}${CLI_FILE} getinfo${NC} command."
 echo -e "   NOTE: the ${DAEMON_FILE} daemon must be running first before trying these commands. See notes above on service commands usage."
 echo
 echo -e " Make sure you keep the information above somewhere private and secure so you can refer back to it."
 echo -e "${RED} NEVER SHARE YOUR PRIVKEY WITH ANYONE, IF SOMEONE OBTAINS IT THEY CAN STEAL ALL YOUR COINS.${NC}"
 echo
 echo -e "================================================================================================================================"
 echo
 echo
}


#************************************************************************************************
# As the last action of the script, ask if user wants to monitor the syncing process
#  Otherwise it will just exit.
#************************************************************************************************
function ask_watch()
{
  read -e -p " $(echo -e ${YELLOW}OPTIONAL: Do you want to watch the ${COIN_NAME} daemon status whilst it is synchronizing?  [Y/N]${NC})" WATCH_CHOICE
#  read -e -p " $(printf ${YELLOW}OPTIONAL: Do you want to watch the ${COIN_NAME} daemon status whilst it is synchronizing? Use Ctrl+C to exit. [Y/N]${NC})" WATCH_CHOICE

  if [[ ("${WATCH_CHOICE}" == "y" || "${WATCH_CHOICE}" == "Y") ]]; then
    echo -e "${YELLOW}Use Ctrl+C to exit watching and return to command prompt.${NC}"
    local cmd=$(echo "${CLI_PATH} -datadir=${HOME_FOLDER} -conf=${HOME_FOLDER}/${CONFIG_FILE} getinfo && ${CLI_PATH} -datadir=${HOME_FOLDER} -conf=${HOME_FOLDER}/${CONFIG_FILE} mnsync status && ${CLI_PATH} -datadir=${HOME_FOLDER} -conf=${HOME_FOLDER}/${CONFIG_FILE} masternode status")
    watch -n 5 ${cmd}
  fi
}


#************************************************************************************************
# Steps for configuring the Masternode and launching it
#************************************************************************************************
function setup_node()
{
  ask_user
  check_port
  check_rpcport
  ask_ip
  create_key
  create_config
  update_config
  enable_firewall
  deploy_sentinel
  add_daemon_service
  add_log_truncate
  show_output
  ask_watch
}

clear

echo
echo -e "${GREEN}"
echo -e "============================================================================================================="
echo
echo -e "                                    8b    d8 8888b.  888888 Yb  dP"
echo -e "                                    88b  d88 8I   Yb 88__    YbdP"
echo -e "                                    88YbdP88 8I   dY 88\"\"    dPYb"
echo -e "                                    88 YY 88 8888Y\"  888888 dP  Yb"
echo
echo
echo -e "${NC}"
echo -e " Install script version 1.1"
echo -e " This script will automate the installation of your ${COIN_NAME} coin masternode and server configuration by"
echo -e " performing the following steps:"
echo
echo -e "  - Prepare your system with the required dependencies"
echo -e "  - Obtain the latest ${COIN_NAME} masternode files from the ${COIN_NAME} GitHub repository"
echo -e "  - Create a user and password to run the ${COIN_NAME} masternode service"
echo -e "  - Install the ${COIN_NAME} masternode service under the new user [not root]"
echo -e "  - Add DDoS protection using fail2ban"
echo -e "  - Update the system firewall to only allow the masternode port and outgoing connections"
echo -e "  - Rotate and archive the masternode logs to save disk space"
echo
echo -e " You will see ${YELLOW}questions${NC}, ${GREEN}information${NC} and ${RED}errors${NC}. A summary of what has been done will be shown at the end."
echo
echo -e " The files will be downloaded and installed from:"
echo -e " ${GREEN}${DAEMON_ARCHIVE}${NC}"
echo
echo -e " Script created by click2install.  Additional tweaks by Bitmucker."
echo -e "  - GitHub: https://github.com/click2install"
echo -e "  - Discord: click2install#9625"
echo -e "  - ${COIN_NAME}: ${DONATION_ADDRESS}"
echo -e "  - BTC: 1DJdhFp6CiVZSBSsXcecp1FnuHXDcsYQPu"
echo -e "${GREEN}"
echo -e "============================================================================================================="
echo -e "${NC}"
read -e -p "$(echo -e ${YELLOW} Do you want to continue? [Y/N] ${NC})" CHOICE

if [[ ("${CHOICE}" == "n" || "${CHOICE}" == "N") ]]; then
  exit 1;                   # Exit from script
fi

checks                      # Perform some basic checks (linux version, user, existing MDEX MN)

if [[ ("${NEW_NODE}" == "y" || "${NEW_NODE}" == "Y") ]]; then     # Another MN was found running, and user wants to continue to install another.
  deploy_binary             # In case previous node was not installed as expected, then install it again.
  setup_node
  exit 0
elif [[ "${NEW_NODE}" == "new" ]]; then       # No other MDEX MN found to be running.  This will be a new one.
  prepare_system
  deploy_binary
  setup_node
else                                          # Another MN was found running, and user has decided to NOT proceed with installing another.
  echo -e "${GREEN}${COIN_NAME} daemon already running. User has selected to not proceed with new installation.${NC}"
  exit 0
fi
