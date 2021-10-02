#!/bin/bash

#
# This socript captures all of the files that you need to PXE Boot the Ubuntu 21.04 server OS.
# This setup can be run on any recent Ubuntu linux disto, I used Ubuntu Server 20.04 LTS for
# the PXE server. This should work on most Ubuntu versions around this distro.
#

TFTP_DIR=/srv/tftp
TFTP_SERVER_IP=192.168.1.89
ISO_IMAGE_FILE_NAME=ubuntu-21.04-live-server-amd64.iso
ISO_IMAGE_SOURCE_PATH=/home/ubuntu/iso_images/${ISO_IMAGE_FILE_NAME}
ISO_URL=http://${TFTP_SERVER_IP}/${ISO_IMAGE_FILE_NAME}

# Ensure this script is being run as root
if [ ${EUID} -ne 0 ]; then
    echo "This script must be run as root, did you forget sudo?"
    exit
fi

# Ensure the system is up to date
echo ""
echo "[Updating OS]: ----------------------------------------------------------------"
apt-get update && apt-get upgrade -y
echo "[Updating OS]: ----------------------------------------------------------------"
echo ""

# Install necessary packages for PXE support
# NFS is so we can use network mounts for PXE booted machines to use
echo ""
echo "[Installing OS PXE Linux support packages] :-----------------------------------"
apt-get install -y pxelinux syslinux-efi syslinux-common nfs-kernel-server initramfs-tools
echo "[Installing OS PXE Linux support packages] :-----------------------------------"
echo ""

# Install the trivial ftp server, the http server, and the DHCP server
echo ""
echo "[Installing Trivial FTP, Apache2 HTTP Server, and DHCP server]:----------------"
apt-get install -y tftpd-hpa apache2 isc-dhcp-server
echo "[Installing Trivial FTP, Apache2 HTTP Server, and DHCP server]:----------------"
echo ""

# Enable the Dynamic Host Configuration (DHCP) Protocol
echo ""
echo "[Enable trivial ftp service to start on boot]: --------------------------------"
systemctl enable isc-dhcp-server.service
echo "[Enable trivial ftp service to start on boot]: --------------------------------"
echo ""

# Enable the Trivial File Transfer Protocol (TFTP) server to start on boot
echo ""
echo "[Enable Trivial File Transfer Protocol (TFTP) service to start on boot]:-------"
systemctl enable tftpd-hpa
echo "[Enable Trivial File Transfer Protocol (TFTP) service to start on boot]:-------"
echo ""

# If the TFTP direcotry does not exist, create it.
if [ ! -d ${TFTP_DIR} ]; then
    echo "Creating the trivial ftp directory [${TFTP_DIR}]."
    mkdir -p /srv/tftp
    echo ""
fi

# Copy the ISO Image to the HTTP directory, if it isn't already there
if [ ! -f /var/www/html/${ISO_IMAGE_FILE_NAME} ]; then
    echo "Copying ISO image file [${ISO_IMAGE_FILE_NAME}] to /var/www/html."
    cp ${ISO_IMAGE_SOURCE_PATH} /var/www/html
fi

# Change into the TFTP directory
pushd ${TFTP_DIR}

# Create the following directories if they don't exist in the TFTP directory
for dir in iso_mount pxelinux.cfg; do
    if [ ! -d ${dir} ]; then
	echo "Creating directory [${dir}] in the trivial ftp directory [${TFTP_DIR}]."
        mkdir -p ${dir}
        echo ""
    fi
done

# Mount the ISO Image
echo "Mounting the ISO Image [${ISO_IMAGE_FILE_NAME}]."
mount -o loop ${ISO_IMAGE_SOURCE_PATH} iso_mount
echo ""

# Pull out the rqeuired files from the ISO image
echo "Copying vmlinuz and initrd from the ISO image."
cp -p iso_mount/casper/vmlinuz .
cp -p iso_mount/casper/initrd .
echo ""

# Unmount the ISO image
echo "Unmounting the ISO image."
umount iso_mount
echo ""

echo "Removing the iso_mount directory."
rmdir iso_mount

# Copy the files needed for UEFI style booting
#echo "Copying required files for UFEI booting."
#cp -p /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi .
#cp -p /usr/lib/syslinux/modules/efi64/ldlinux.e64 .
#cp -p /usr/lib/syslinux/modules/efi64/libcom32.c32 .
#cp -p /usr/lib/syslinux/modules/efi64/libutil.c32 .
#cp -p /usr/lib/syslinux/modules/efi64/vesamenu.c32 .
#echo ""

# Copy the files needed for Legacy BIOS style booting
echo "Copying required files for BIOS booting."
cp -p /usr/lib/PXELINUX/pxelinux.0 .
cp -p /usr/lib/syslinux/modules/bios/ldlinux.c32 .
cp -p /usr/lib/syslinux/modules/bios/libcom32.c32 .
cp -p /usr/lib/syslinux/modules/bios/libutil.c32 .
cp -p /usr/lib/syslinux/modules/bios/vesamenu.c32 .
echo ""


#Create the default config file if one doesn't exist
if [ ! -f ${TFTP_DIR}/pxelinux.cfg/default ]; then
    echo "Creating a default pxelinux.cfg/default file."

cat > ${TFTP_DIR}/pxelinux.cfg/default << EOF
DEFAULT vesamenu.c32
PROMPT 0
NOESCAPE 1

MENU TITLE PXE System Installation
LABEL Ubuntu 21.04
  MENU LABEL ubuntu_21.04
  KERNEL vmlinuz
  INITRD initrd
  APPEND root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=${ISO_URL} ds=nocloud-net;
EOF

    echo ""
fi

# Return to where the user started
popd

echo "Restart TFTP Service."
systemctl restart tftpd-hpa
sleep 1
echo ""

echo "Restart DHCP Service."
systemctl restart isc-dhcp-server.service
sleep 1
echo ""

echo "Restart the HTTP Service."
systemctl restart apache2
sleep 1
echo ""

echo "This system now has the basics setup to be a PXE Boot Server."
echo "From here you need to ensure that:"
echo "    1) The /etc/dhcp/dhcpd.conf file is setup for your network"
echo "    2) The /etc/default/tftpd-hpa configuration file points to the /srv/tftp directory"
echo ""
