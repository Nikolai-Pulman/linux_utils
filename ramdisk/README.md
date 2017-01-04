# Linux bash script to start and stop ram drive mounting, data management.

It can run as a service on startup and back up data on reboot

# On Ubuntu system as root:

    mkdir /etc/ramdisk
    cd /etc/ramdisk
    wget https://raw.githubusercontent.com/Nikolai-Pulman/linux/master/ramdisk.sh
    chmod +x ramdisk.sh
    /etc/ramdisk/ramdisk.sh install

#
# Usage
#Start
    /etc/ramdisk/ramdisk.sh start

#   Stop
    /etc/ramdisk/ramdisk.sh stop

#   Backup data 
    /etc/ramdisk/ramdisk.sh backup

#   Check free space
    /etc/ramdisk/ramdisk.sh status


# Please also setup cronjob to backup data periodically!
