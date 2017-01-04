#!/bin/bash

# ramdisk.sh -- Ubuntu ram disk script
#
# Copyright (C) <2017> <Nikolai Pulman>
# All rights reserved.
#
# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.
#

#Check for config file
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
config=$scriptdir"/ramdisk.conf"

if [ ! -f $config ]; then
        config_exist=false
        echo "Config not found!"
        par='install'
else
        par=$1
        config_exist=true
        source $config
        #Check if location is mounted
        if mountpoint $location> /dev/null; then
                mounted=true
        else
                mounted=false
        fi
fi



##Check if root
if [[ $EUID -ne 0 ]]; then
        echo "You must be a root user" 2>&1
        exit 1
fi

#
#       Start
#
start(){
#If filesystem is mounted abort
        if $mounted; then
                echo "RAMDisk is runnig"
                exit 1
        fi

#Mount filesystem
        mount -t tmpfs -o size=$size"G" tmpfs $location
#check if filesystem is mounted
        if mountpoint $location> /dev/null; then
#Get file list count
        filecount="$(rsync -naic $data $location | awk '{ print } END { print NR }'| grep -vE .....)"
        (( filecount += 18 ))
#Rsync files to ram disk from data
                rsync -vrltD --stats --human-readable -ar $data $location | pv -N "Starting RAMDisk" -lp -s $filecount >/dev/null
        else
                echo "Could not mount location, exiting"
                exit 1
        fi
}



#
#       Stop
#
stop(){

#Stops only if location is mounted, otherwise backup data is overwritten
        if ! $mounted; then
                echo "RAMDisk is not running!"
                exit 1
        fi
#Get file list count
        filecount="$(rsync -naic $location $data | awk '{ print } END { print NR }'| grep -vE .....)"
        (( filecount += 18 ))
#Rsync to data folder
        rsync -vrltD --stats --human-readable -ar $location $data --delete| pv -N "Stopping RAMDisk" -lp -s $filecount >/dev/null
#Umount tmpfs
        umount -l $location
}



#
#       Backup Data
#
backup(){

#Backup only if mounted
        if ! $mounted; then
                echo "Filesystem is not mounted"
                exit 1
        fi
#Get file list count
        filecount="$(rsync -naic $location $data | awk '{ print } END { print NR }'| grep -vE .....)"
        (( filecount += 18 ))
#Rsync files to data folder
        rsync -vrltD --stats --human-readable -ar $location $data --delete | pv -N "Backing up data to datastore" -lp -s $filecount >/dev/null
}



#
#       Check free space
#
status(){
        if $mounted; then
                df -h "$location"
        else
                echo "RAMDisk is not started"
        fi
}



#
#       Installation
#
install(){
#Checking rsync and rv

#rv
if pv -h >/dev/null; then
        pv_exist=true
else
        echo "please install pv - apt-get install pv"
        exit 1
fi

#rsync
if rsync -h >/dev/null; then
        pv_exist=true
else
        echo "please install rsync - apt-get install rsync"
        exit 1
fi

#Promnt user first
read -r -p "Run install? [y/N] " response
if [[  $response =~ ^([yY][eE][sS]|[yY])$ ]];then
        echo ""
else
        echo "Fine, i exit."
        exit 1
fi

#If config exist load those values

install_location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
install_disk_location="/RAMDisk/"
install_disk_size=1
install_datastore=$install_location"/data"
install_archive=$install_location"/archive"


if [  -f $config ]; then
        read -r -p "Config file exist, do i read it? [y/N] " response
        if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]];then
                echo "Reading config file:"
                echo ""
                install_disk_location=$location
                install_disk_size=$size
                install_datastore=$data
                install_archive=$install_location"/archive"
        fi
fi

#Get data from user
read -p "RAMDisk script folder? : " -e -i $install_location"/" install_location

#mount dir
read -p "Where to mount RAMDisk? : " -e -i $install_disk_location install_disk_location
if [ ! -d "$install_disk_location" ]; then
                read -r -p "Folder do not exist, create it? [y/N] " response
        if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]];then
                        mkdir $install_disk_location
        fi
fi

#Datastore location
read -p "Data store location? : " -e -i $install_datastore"" install_datastore
if [ ! -d "$install_datastore" ]; then
        read -r -p "Folder do not exist, create it? [y/N] " response
        if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]];then
                        mkdir $install_datastore
        fi
fi

#Disk Size in GB
read -p "Disk size (in GB)? : " -e -i $install_disk_size install_disk_size

#Archive(not yet implemented)
read -p "Archive location? : " -e -i $install_archive"/" install_archive
if [ ! -d "$install_archive" ]; then
         read -r -p "Folder do not exist, create it? [y/N] " response
        if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]];then
                        mkdir $install_archive
        fi
fi

configfile=$install_location"/ramdisk.conf"

echo "writing config file"
echo "#Disk mount location" > $configfile
echo "location="$install_disk_location >> $configfile
echo "">> $configfile
echo "#Folder size" >> $configfile
echo "size="$install_disk_size >> $configfile
echo "" >> $configfile
echo "#Where to store ram disk data" >> $configfile
echo "data="$install_datastore >> $configfile
echo ""
echo "#Archive location">> $configfile
echo "archive="$install_archive >> $configfile


#
#       Make ramdisk as a service
#
        read -r -p "Make RAMDisk as a service? [y/N] " response
        if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]];then
                echo ""
                echo "Writing service file"
                echo "[Unit]" > $install_location"/ramdisk.service"
                echo "Description=A script that save and restore the data on the RAM disk" >> $install_location"/ramdisk.service"
                echo "Before=umount.target" >> $install_location"/ramdisk.service"
                echo "" >> $install_location"/ramdisk.service"
                echo "[Service]" >> $install_location"/ramdisk.service"
                echo "Type=oneshot" >> $install_location"/ramdisk.service"
                echo "User=root" >> $install_location"/ramdisk.service"
                echo "ExecStart="$install_location"ramdisk.sh start" >> $install_location"/ramdisk.service"
                echo "ExecStop="$install_location"ramdisk.sh stop" >> $install_location"/ramdisk.service"
                echo "RemainAfterExit=yes" >> $install_location"/ramdisk.service"
                echo "" >> $install_location"/ramdisk.service"
                echo "[Install]" >> $install_location"/ramdisk.service"
                echo "WantedBy=multi-user.target" >> $install_location"/ramdisk.service"
                echo "" >> $install_location"/ramdisk.service"
                echo "copying service file"
                mv $install_location"/ramdisk.service" /lib/systemd/system/ramdisk.service
                echo "Refreshing service"
                systemctl daemon-reload
                echo "Starting ramdisk service"
                systemctl stop  ramdisk.service
                systemctl start  ramdisk.service
                echo ""
                df -h "$location"
                echo ""


        fi


}
#
#       Select case switch
#
case "$par" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        backup)
                backup
                ;;
        status)
                status
                ;;
        install)
                install
                ;;
        *)
            echo $"Usage: $0 {start|stop|status|backup|install|}"
            exit 1

esac
