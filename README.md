# pxe-server
This is a bash script that sets up and configures an Ubunutu 20.04 LTS or 21.04 system to be a PXE server. 

# What it does for you
The main script [setup_pxe_server.bash] performs the following actions:

1. installs the following packages:
     1. PXE OS support Packages
     2. Network File System (NFS)
     3. Trivial File Transfter Protocol (FTP) Server
     4. Dynamic Host Configuration Protocol (DHCP) Server
     5. Apache2 HTTP server
2. Enables the DHCP and TFTP services to start on boot
3. Creates any necessary directores, and specifically the /src/tftp directory
4. Moves the OS ISO file the client will boot to the /var/www/html directory
5. Extracts the necessary PXE OS startup files from the ISO image
6. Creates a default PXE Linux configuration file in the TFTP directory
7. Restarts the TFTP, DHCP, and HTTP servers.

# What you need to do for it
After you have run the above script, you will need to define the /etc/dhcp/dhcpd.conf file to have a configuration that is suitable for your LAN. There is a sample dhcp.conf file included in this repository.

# What does my setup look like?
My LAN is a standard home private network that is behind a firewall router with the typical subnet with IP's from 192.168.1.1 to 192.168.1.254. Since this is my main home network, it has other active machines that are online and in use by the family while I'm playing in PXE land. To keep things on as much as a non-interference basis as I can, I've setup my firewall router to contrain it's use of DHCP assignments from 192.168.1.2 to 192.168.1.99, leaving 192.168.1.100 to 192.168.1.254 available to the "new" DHCP server created by running this script. So far I have not seen any interference between the Ubuntu Server DHCP and the firewall router DHCP

This newly configured Ubuntu VM is serving out DHCP to my test machine - the PXE client in the dhcp.conf file - by specific mac address so I'm not having my other machines getting pulled into PXE boot land when they are powered up. I likely also have an advantage that I have a network swtich connected directly to my PC hosting the Ubuntu VM, the PXE client, and the home firewall/router. I might be getting a little assistnace from this configuration which may preventing my home firewall router from interfering with the DHCP VM Server on my host machine.

Think of it like this: 
- Main PC (Windows w/ VirtualBox) -> Network Switch
- PXE Client (PC with HDD remvoved) -> Network Switch
- Raspberry PI #1 -> Network Switch
- Radpberry PI #2 -> Network Switch
- Network Switch -> Firewal/Router

# Where things are right now
At the moment I have things working to the point the Ubuntu Server on the client hits the main install screen. At this point the keyboard hangs. Given I almost lost all my work yesterday with an aventure with the Windows Subsustem for Linux install, I've decided to put my work here to it lives on despite any untentionally destruvtive things I might end up doing to my computer or to the scripts / configuration files themselves. Now they are contained within the endless memory of the internet.

# Moments of Pain

## Virtual Box IP Issues with Cloned Ubuntu Images
I've been using Virtual Box for a while and like to use a NAT Network to glue multiple VMs together so I can make a small private cloud on my personal PC for learning and expierementation. I've tyically been using CentOS and when I clone, things just work. When I did this with Ubuntu, I started getting the same IP for every VM instance I was running... This ended up being related to the fact that Ubuntu has a UUID for the machine (being the VM) and when you clone, that get's cloned too. I found an online article on how to generate a new one and put it the utils/reset_machine_id.bash file in this repo. 

To use it:
1. Fire up your VM
2. Pull the scipt over to it
3. Run it
4. Reboot
5. Log in
6. run ifconfig to see that you finally have a differing IP.

## Ubuntu didn't notice I enabled new networks for the VM in VirtualBox
Why this isn't autmoatic is beyond me. 
