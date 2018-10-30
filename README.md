# MoonDEX Coin

Shell script to install a `MoonDEX Coin Masternode` on a Linux server running Ubuntu 16.04. Supports IPv4, IPv6 and multiple nodes on a single VPS, it does not configure your iptables entries and will require post install steps to make additional masternodes work correctly if you install more than one.

**Make sure you read all the instructions below before using this script, it does not install your masternode under the root account and as such requires different commands to most other scripts**


## Installation
To start the installation, login as `root` to your VPS and run the two commands listed below. Note that the masternode does not run as root but as a user that the script will create. The script, however, needs to run as root so your VPS can be configured correctly.

```
wget -q https://github.com/click2install/moondex/raw/master/install-moondex.sh  
bash install-moondex.sh
```
This script is intended to be used on a clean server, o# MoonDEX Coin

Shell script to install a `MoonDEX Coin Masternode` on a Linux server running Ubuntu 16.04. Supports IPv4, IPv6 and multiple nodes on a single VPS.

**Make sure you read all the instructions below before using this script, it does not install your masternode under the root account and as such requires different commands to most other scripts**


## Installation
To start the installation, login as `root` to your VPS and run the two commands listed below. Note that the masternode does not run as root but as a user that the script will create. The script, however, needs to run as root so your VPS can be configured correctly.

```
wget -q https://github.com/click2install/moondex/raw/master/install-moondex.sh  
bash install-moondex.sh
```
This script is intended to be used on a clean server, or a server that has used this script to install 1 or more previous nodes. 

This script will work alongside masternodes that were installed by other means provided the masternode binaries `moondexd` and `moondex-cli` are installed to `/usr/local/bin`.

Donations for the creation and maintenance of this script are welcome at:
&nbsp;

MDEX: XoDpG5yrZ3UTtAywge5wNZAbhmxJi7SZbh

BTC: 1DJdhFp6CiVZSBSsXcecp1FnuHXDcsYQPu

&nbsp;

## How to setup your masternode with this script and a cold wallet on your PC
The script assumes you are running a cold wallet on your local PC and this script will execute on a Ubuntu Linux VPS (server). The steps involved are:

 1. Run the masternode installation script as per the [instructions above](https://github.com/click2install/moondex#installation).
 2. When you are finished this process you will get some information on what has been done as well as some important information you will need for your cold wallet setup.
 3. **Copy/paste the output of this script into a text file and keep it safe.**

You are now ready to configure your local wallet and finish the masternode setup

 1. Make sure you have downloaded the latest wallet from https://github.com/Moondex/MoonDEXCoin/releases
 2. Install the wallet on your local PC
 3. Start the wallet and let if completely synchronize to the network - this will take some time
 4. Create a new `Receiving Address` from the wallets `File` menu and name it appropriately, e.g. MN-1
 5. Unlock your wallet and send **exactly 2,500 MDEX** to the address created in step #4
 6. Wait for the transaction from step #5 to be fully confirmed. Look for a tick in the first column in your transactions tab
 7. Once confirmed, open your wallet console and type: `masternode outputs` **or use the generated private key from the script**
 8. Open your masternode configuration file from the wallets `Tools` menu item.
 9. In your masternodes.conf file add an entry that looks like: `[address-name from #4] [ip:port of your VPS from script output] [privkey from script output] [txid from from #7] [tx output index from #7]` - 
 10. Your masternodes.conf file entry should look like: `MN-1 127.0.0.2:8906 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0` and it must be all on one line in your masternodes config file
 11. Save and close your masternodes.conf file
 12. Close your wallet and restart
 13. Go to Masternodes > My MasterNodes
 14. Make sure the VPS node is fully synchronised and at the correct block height before trying to activate it from the wallet.
 15. Click the row for the masternode you just added
 16. Right click > Start Alias
 17. Your node should now be running successfully, wait for some time for it to connect with the network and the `Active` time to start counting up.

 &nbsp;

## Multiple master nodes on one server
The script allows for multiple nodes to be setup on the same server, using the same IP address and different ports. It also allows for either IPv4 and/or IPv6 addresses to be used. 

During the execution of the script you have the opportunity to decide on a port to use for the node. Each node runs under are different user account which the script creates for you.

**Important:** when installing more than one masternode, make sure the port number you choose is above 1024 and at least 2 greater than any other node you have running. It needs to be 2 as the masternode uses the port you enter and the masternode rpcserver uses the next highest port.

The easiest ports to choose would be 8906 for your first masternode, then 8908, 8910. The RPC port will be chosen based on your port selection.

At this stage the script auto detects the IP addresses of the server, if there is more than one address found, it will ask you which address to use, otherwise it will use the only address found without user input.

If you do setup multiple masternodes on a single VPS, make sure the VPS is capable of running more than one masternode or your masternode rewards will suffer. **You have been warned.**

Once you have setup the 2nd or more masternodes, use the output of the script for each masternode and follow the [steps above](https://github.com/click2install/moondex#how-to-setup-your-masternode-with-this-script-and-a-cold-wallet-on-your-pc) in your wallet, where each new masternode is a new line in your `masternode.conf` file. **NOTE:** All the port numbers in your masternode.conf file will be 8906 or the wallet will not re-start after you save the config file.

Note that multiple masternodes use only one instance of the `moondexd` and `moondex-cli` binary files located in `/usr/local/bin` and they each have their own configuration located in `/home/<username>/.moondexcore` folder.

&nbsp;


## Running the script
When you run the script it will tell you what it will do on your system. Once completed there is a summary of the information you need to be aware of regarding your node setup which you can copy/paste to your local PC. **Make sure you keep this information safe for later.**

If you want to run the script before setting up the node in your cold wallet the script will generate a priv key for you to use, otherwise you can supply the privkey during the script execution by pasting it into the SSH shel [right click for paste] when asked.

&nbsp;


## Masternode commands
Because the masternode runs under a user account, you cannot login as root to your server and run `moondex-cli masternode status` (or other commands the "usual way"), if you do you will get an error. You need to switch the to the user that you installed the masternode under when running the script. **So make sure you keep the output of the script after it runs.**

You can query each of your masternodes by first switching to the user the masternode is running as:
```
 su - <username>
```

If you are asked for a password, it is in the script output you received when you installed the masternode, you can right click and paste the password. 
The following commands can then be run against the node that is running as the user you just switched to.

#### To query your masternodes status
```
 moondex-cli masternode status 
```

#### To query your masternode information
```
 moondex-cli getinfo
```

#### To query your masternodes sync status
```
 moondex-cli mnsync status
```

## Removing a masternode and user account
If something goes wrong with your installation or you want to remove a masternode, you can do so with the following command.
```
 userdel -r <username>
```
This will remove the user and its home directory. If you then re-run the installation script you can re-use that username.

&nbsp;

## Security
The script will set up the required firewall rules to only allow inbound node communications, whilst blocking all other inbound ports and all outbound ports.

The [fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page) package is also used to mitigate DDoS attempts on your server.

Despite this script needing to run as `root` you should secure your Ubuntu server as normal with the following precautions:

 - disable password authentication
 - disable root login
 - enable SSH certificate login only

If the above precautions are taken you will need to `su root` before running the script. You can find a good tutorial for securing your VPS [here](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04).

&nbsp;

## Disclaimer
Whilst effort has been put into maintaining and testing this script, it will automatically modify settings on your Ubuntu server - use at your own risk. By downloading this script you are accepting all responsibility for any actions it performs on your server.

&nbsp;






r a server that has used this script to install 1 or more previous nodes. 

This script will work alongside masternodes that were installed by other means provided the masternode binaries `moondexd` and `moondex-cli` are installed to `/usr/local/bin`.

Donations for the creation and maintenance of this script are welcome at:
&nbsp;

MDEX: XoDpG5yrZ3UTtAywge5wNZAbhmxJi7SZbh

BTC: 1DJdhFp6CiVZSBSsXcecp1FnuHXDcsYQPu

&nbsp;

## How to setup your masternode with this script and a cold wallet on your PC
The script assumes you are running a cold wallet on your local PC and this script will execute on a Ubuntu Linux VPS (server). The steps involved are:

 1. Run the masternode installation script as per the [instructions above](https://github.com/click2install/moondex#installation).
 2. When you are finished this process you will get some information on what has been done as well as some important information you will need for your cold wallet setup.
 3. **Copy/paste the output of this script into a text file and keep it safe.**

You are now ready to configure your local wallet and finish the masternode setup

 1. Make sure you have downloaded the latest wallet from https://github.com/Moondex/MoonDEXCoin/releases
 2. Install the wallet on your local PC
 3. Start the wallet and let if completely synchronize to the network - this will take some time
 4. Create a new `Receiving Address` from the wallets `File` menu and name it appropriately, e.g. MN-1
 5. Unlock your wallet and send **exactly 2,500 MDEX** to the address created in step #4
 6. Wait for the transaction from step #5 to be fully confirmed. Look for a tick in the first column in your transactions tab
 7. Once confirmed, open your wallet console and type: `masternode outputs` **or use the generated private key from the script**
 8. Open your masternode configuration file from the wallets `Tools` menu item.
 9. In your masternodes.conf file add an entry that looks like: `[address-name from #4] [ip:port of your VPS from script output] [privkey from script output] [txid from from #7] [tx output index from #7]` - 
 10. Your masternodes.conf file entry should look like: `MN-1 127.0.0.2:8906 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0` and it must be all on one line in your masternodes config file
 11. Save and close your masternodes.conf file
 12. Close your wallet and restart
 13. Go to Masternodes > My MasterNodes
 14. Make sure the VPS node is fully synchronised and at the correct block height before trying to activate it from the wallet.
 15. Click the row for the masternode you just added
 16. Right click > Start Alias
 17. Your node should now be running successfully, wait for some time for it to connect with the network and the `Active` time to start counting up.

 &nbsp;

## Multiple master nodes on one server
The script allows for multiple nodes to be setup on the same server, using the same IP address and different ports. It also allows for either IPv4 and/or IPv6 addresses to be used. 

During the execution of the script you have the opportunity to decide on a port to use for the node. Each node runs under are different user account which the script creates for you.

**Important:** when installing more than one masternode, make sure the port number you choose is above 1024 and at least 2 greater than any other node you have running. It needs to be 2 as the masternode uses the port you enter and the masternode rpcserver uses the next highest port.

The easiest ports to choose would be 8906 for your first masternode, then 8908, 8910. The RPC port will be chosen based on your port selection.

At this stage the script auto detects the IP addresses of the server, if there is more than one address found, it will ask you which address to use, otherwise it will use the only address found without user input.

If you do setup multiple masternodes on a single VPS, make sure the VPS is capable of running more than one masternode or your masternode rewards will suffer. **You have been warned.**

Once you have setup the 2nd or more masternodes, use the output of the script for each masternode and follow the [steps above](https://github.com/click2install/moondex#how-to-setup-your-masternode-with-this-script-and-a-cold-wallet-on-your-pc) in your wallet, where each new masternode is a new line in your `masternode.conf` file. **NOTE:** All the port numbers in your masternode.conf file will be 8906 or the wallet will not re-start after you save the config file.

Note that multiple masternodes use only one instance of the `moondexd` and `moondex-cli` binary files located in `/usr/local/bin` and they each have their own configuration located in `/home/<username>/.moondexcore` folder.

&nbsp;


## Running the script
When you run the script it will tell you what it will do on your system. Once completed there is a summary of the information you need to be aware of regarding your node setup which you can copy/paste to your local PC. **Make sure you keep this information safe for later.**

If you want to run the script before setting up the node in your cold wallet the script will generate a priv key for you to use, otherwise you can supply the privkey during the script execution by pasting it into the SSH shel [right click for paste] when asked.

&nbsp;


## Masternode commands
Because the masternode runs under a user account, you cannot login as root to your server and run `moondex-cli masternode status` (or other commands the "usual way"), if you do you will get an error. You need to switch the to the user that you installed the masternode under when running the script. **So make sure you keep the output of the script after it runs.**

You can query each of your masternodes by first switching to the user the masternode is running as:
```
 su - <username>
```

If you are asked for a password, it is in the script output you received when you installed the masternode, you can right click and paste the password. 
The following commands can then be run against the node that is running as the user you just switched to.

#### To query your masternodes status
```
 moondex-cli masternode status 
```

#### To query your masternode information
```
 moondex-cli getinfo
```

#### To query your masternodes sync status
```
 moondex-cli mnsync status
```

## Removing a masternode and user account
If something goes wrong with your installation or you want to remove a masternode, you can do so with the following command.
```
 userdel -r <username>
```
This will remove the user and its home directory. If you then re-run the installation script you can re-use that username.

&nbsp;

## Security
The script will set up the required firewall rules to only allow inbound node communications, whilst blocking all other inbound ports and all outbound ports.

The [fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page) package is also used to mitigate DDoS attempts on your server.

Despite this script needing to run as `root` you should secure your Ubuntu server as normal with the following precautions:

 - disable password authentication
 - disable root login
 - enable SSH certificate login only

If the above precautions are taken you will need to `su root` before running the script. You can find a good tutorial for securing your VPS [here](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04).

&nbsp;

## Disclaimer
Whilst effort has been put into maintaining and testing this script, it will automatically modify settings on your Ubuntu server - use at your own risk. By downloading this script you are accepting all responsibility for any actions it performs on your server.

&nbsp;
