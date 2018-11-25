# MoonDEX Coin Masternode Installation Script
## Overview
Shell script to install a `MoonDEX Coin Masternode` on a Linux server running Ubuntu 16.04. Supports IPv4 and multiple nodes on a single VPS.  IPv6 is supported by the script, but the current MoonDEX wallets do not support IPv6.  This script does not configure your VPS's iptables entries and will require separate install steps (see instructions) to make additional masternodes work correctly if you install more than one.

**IMPORTANT:**
*Make sure you read all the instructions below before using this script.  It does not install your masternode under the root account and as such, requires slightly different commands than most other scripts.*

```css
[BUG-REPORTS] No current issues.
```

Donations for the creation and maintenance of this script are welcome at:
&nbsp;

MDEX: XoDpG5yrZ3UTtAywge5wNZAbhmxJi7SZbh
BTC: 1DJdhFp6CiVZSBSsXcecp1FnuHXDcsYQPu

&nbsp;

### Masternode Hardware Requirements
The first several months of the MDEX blockchain’s functioning suggests that a good “rule of thumb” is for each server to have at least 250MB of RAM and 10GB of disk storage. Note however, that if you have less than this amount of RAM, you can use a swap disk to offset this limitation (included as part of this install process).  This may change in the future as the project matures and demands more of the MN hardware.

### Summary of steps
1. Configure VPS to have one IP for each MDEX MN being installed on it (through VPS provider).
2. Set up the first masternode and let it sync.
3. Configure your local wallet (GUI wallet) to work with the MN and start the new MN in the local wallet.
4. Confirm successful startup of the MN
5. Repeat from step 2 (above) for each additional MDEX masternode

&nbsp;

## 1. Configuring your Masternode Collateral and Rewards Address
In your local wallet (typically a GUI wallet in Windows, etc.)
1. Make sure you have downloaded the latest wallet from https://github.com/Moondex/MoonDEXCoin/releases
1. Install the wallet on your local PC
1. Start the wallet and let it completely synchronize to the network - this will take some time
1. Create a new Receiving Address from the wallet's *File* menu and name it appropriately, e.g. MN-1
1. Unlock your wallet (if necessary) and send _exactly_ 2,500 MDEX to the address created above
1. Wait for a minimum of 15 confirmations before starting the masternode in the GUI (see steps below).  In the meanwhile, you can proceed with the following steps.
1. Open your wallet's *Debug Console* and type: `masternode outputs`.  Record the reported *transaction ID* and *transaction output index* for the new MN.  These should be a long series of characters, followed by a single digit (each in double quotes).
1. Open your *masternode configuration* file (*masternodes.conf*) from the wallet's *Tools* menu.
1. In the masternodes.conf file, add an entry that looks like: [address-name from above] [ip:port of your VPS from script output] [privkey from script output] [txid from from above] [tx output index from above] -
Your *masternodes.conf* file entry should look like: ```MN-1 127.0.0.2:8906 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2jcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 1``` and it must be all on one line in your *masternode configuration* file
1. Save and close your *masternodes.conf* file
1. *Close* your wallet and *restart* it.
1. Proceed with the VPS setup (you can proceed even if the confirmations have not yet reached 15).

&nbsp;

## 2. Prepare VPS for the Masternode(s)
1. Create new VPS (for example, on VULTR) using Ubuntu 16.04 64 bit and IPv4
1. Record the VPS info (Label, IP, login, pswd, etc.)
1. **If you are intending to install multiple MDEX masternodes on the VPS, you will need to add the additional IP address from the control panel of your VPS provider.**  

   * On the "Settings" tab (assuming the VPS is on VULTR) select the IPv4 settings and Add Another IPv4 Address button. You can find instructions on adding the additional IP address in the VULTR help docs at: https://www.vultr.com/docs/add-secondary-ipv4-address
   * Record the new (additional) IP address.
   * Log into the new VPS using Putty (or similar)
   * Back on the VULTR IPv4 settings page, locate and click on the link for *networking configuration*.  This will bring you to a page that is auto-generated (customized) to give you the exact text that you can copy/paste into the file `/etc/network/interfaces` on your VPS using an editor like `nano` (available on most Ubuntu VPSs).  You should not have to tweak anything in the copied text (it’s pretty simple).  Make sure to copy the text from the example code section for *Ubuntu 16.xx*.  For this example (two MNs using two IPv4 addresses), this looks something like:
```auto lo
iface lo inet loopback

auto ens3
iface ens3 inet static
	address XXX.XXX.XXX.XXX
	netmask 255.255.254.0
	gateway XXX.XXX.XXX.XXX
	dns-nameservers XXX.XX.XX.XX
	post-up ip route add XXX.XXX.0.0/16 dev ens3

iface ens3 inet6 static
	address XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX
	netmask 64
	dns-nameservers XXXX:XXXX:XXX:XXXX::X

auto ens3:1
iface ens3:1 inet static
	address XXX.XXX.XXX.XXX
	netmask 255.255.254.0
```

&nbsp;

## 3. Run the Installation Script
To start the installation, login as `root` to your VPS and run the two commands listed below. Note that the masternode __does not run as root__ but as a user that the script will create. The installation script, however, needs to run as root so your VPS can be configured correctly.

```
wget -q https://github.com/click2install/moondex/raw/master/install-moondex.sh  
bash install-moondex.sh
```
This script is intended to be used on a clean server, or a server that has used this script to install 1 or more previous MDEX nodes.  It may also work on a VPS with masternodes of other coins, but that may involve additional measures that are beyond the scope of these instructions (give it a shot if you want, but be prepared to troubleshoot).

This script will install the masternode binaries (executable files) `moondexd` and `moondex-cli` into the common directory `/usr/local/bin`.

The script involves these steps requiring responses from you:
1. **New Installation:** If this is detected as the first MDEX masternode on the vps, it will proceed as normal.  If it detects another pre-existing MDEX masternode, it will ask you if you wish to proceed or abort.
1. **User Name:** Provide a user name. This is the user that the masternode will be installed and run under (again, this is NOT the root user).
1. **RPCPORT:** Provide a value for the RPCPORT setting (recommended values are provided in the script).  Each MDEX masternode on the VPS should use a *different* rpcport value.
1. **IP Address:** The script will identify all available IP addresses on the VPS.  Select the address you wish to use.  Do **not** select an address that is already in use by another MDEX masternode.  Also, at present, MDEX does not support IPv6 addresses.
1. **Masternode Key:** Either paste a desired masternode key, or press *Enter* to have the script generate one for you.  It will be reported to you at the end so you can copy it into your records.
1. **Monitor syncing:** You can (optionally) monitor the progress of the syncing and status of the MN when prompted.  When you are done syncing (or just tired of watching), you can press **Ctrl+c** to return back to the installation script screen.
1. **Record the configuration information:** As the final step of the installation, the script will provide a range of configuration information that you should copy for your records (addresses, private key, passwords, etc.).


## 4. Start your Masternode from your local wallet (GUI wallet)
After completing the above steps on the VPS, return to your local wallet (Windows, etc.)

1. Confirm the local wallet is running and fully synced.
1. Confirm that your collateral transaction has received a minimum of 15 confirmations.
1. Confirm that the new MN is listed in the *My Masternodes* tab under the *Masternodes* section in your local wallet.  At this point, it's status will be something like **MISSING**.
1. Make sure the VPS node is fully synchronized and at the correct block height before trying to activate it from the local wallet.  Do this using the command `/usr/local/bin/moondex-cli getinfo` or `/usr/local/bin/moondex-cli mnsync status`
1. Click the row for the masternode you just added (select that masternode)
1. Right click > *Start Alias* to start the masternode
1. You should see the status switch from **MISSING** to **PRE-ENABLED**, and then (after 20ish minutes), to **ENABLED**.  Your node should now be running successfully.
1. Performa a final confirmation check back on the VPS by running (under the user name for the masternode, not root) `/usr/local/bin/moondex-cli masternode status`.  Look for a message along the lines of *Masternode Successfully Started*.  If you see this, then it means the masternode is running properly.  This is the BEST way to confirm it is working (the GUI wallet status can sometimes be mis-reported).

 &nbsp;

## 5. Multiple master nodes on one server
The script allows for multiple nodes to be setup on the same server, using different IP addresses and different rpcport values.  The script will automatically detect if your installation is the first on the VPS, or if it is a multiple-MN installation.  

Generally, the overall installation process is the same for additional MDEX masternodes on the same VPS (Steps 1-4 above).

**If you do setup multiple masternodes on a single VPS, make sure the VPS hardware is capable of running more than one masternode or your masternode stability and rewards will suffer. You have been warned.**

Each node runs under a different user account which the script creates for you.

During the execution of the script you have the opportunity to decide on the *IP address* (if the VPS has more than one) and the value of *rpcport* to use for each node. Each MDEX masternode should use its own IP address, and the script will provide some guidance for the choice of *rpcport* value.

Note that multiple masternodes use only one instance of the executable `moondexd` and `moondex-cli` binary files located in `/usr/local/bin` and they each have their own configuration located in `/home/<username>/.moondexcore` folder.

&nbsp;

## 6. Masternode commands
Because the masternode runs under a user account (not *root*), you cannot login as root to your server and run `moondex-cli masternode status` in the "usual way".  If you do, you will get an error. You need to switch the to the user that you installed the masternode under when running the script.

You can query each of your masternodes by first switching to the user the masternode is running under:
```
 su - <username>
```

If you are asked for a password (generally, it won't ask though), it is in the script output you received when you installed the masternode.

The following commands can then be run under the user you just switched to.

#### To query your masternode information:
```
 moondex-cli getinfo
```

#### To query your masternodes sync status:
```
 moondex-cli mnsync status
```

#### To query your masternodes status:
```
 moondex-cli masternode status
```

#### General Masternode Service commands:
These should be run as the `root` user.
```
systemctl start <username>.service
systemctl stop <username>.service     
systemctl status <username>.service
```
The MDEX masternode uses a sentinel that runs as a service (a Linux application that runs in the background).  The sentinel helps the masternode automatically re-start on its own if needed.  To properly shut the masternode down (so it stays shut down) you should use the above `systemctl stop <username>.service` command as the `root` user (versus the `moondex-cli stop` command).


&nbsp;

## 7. Removing a masternode and user account
If something goes wrong with your installation or you want to remove a masternode, you can do so with the following commands.
First, log in as the `root` user.  If the masternode is still running, you can halt the service using
```
  systemctl stop <username>.service   
```

```
 userdel -r <username>
```
This will remove the user and its home directory. If you then re-run the installation script you can re-use that username.

If you wish to remove the binaries, run the below command as the root user (or use su).  Note, if you have another MDEX masternode running on the samve VPS that you do not wish to uninstall, then do NOT remove the binaries.
```
rm -rf /usr/local/bin/moondex*
```

&nbsp;

## 8. Security
The script will set up the required firewall rules to only allow inbound node communications, whilst blocking all other inbound ports and all outbound ports.

The [fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page) package is also used to mitigate DDoS attempts on your server.

Despite this script needing to run as `root` you should secure your Ubuntu server as normal with the following precautions:

 - disable password authentication
 - disable root login
 - enable SSH certificate login only

If the above precautions are taken you will need to `su root` before running the script. You can find a good tutorial for securing your VPS [here](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04).

&nbsp;

## 9. Disclaimer
Whilst effort has been put into maintaining and testing this script, it will automatically modify settings on your Ubuntu server - use at your own risk. By downloading this script you are accepting all responsibility for any actions it performs on your server.

&nbsp;
