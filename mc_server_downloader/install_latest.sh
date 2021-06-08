#!/bin/bash

#Define jar filenames
release_file="minecraft_server.jar"
snapshot_file="minecraft_latest.jar"

#
#
# NO EDIT BELLOW THIS POINT
#
#


#Manifest json
manifest_json="https://launchermeta.mojang.com/mc/game/version_manifest.json"


#script switch
#
# Accepted arguments are: release, snapshot all
#
command=$(echo $1 | sed 's/--//')

#Get versions
release=$(curl -s $manifest_json | jq -r ".latest.release")
snapshot=$(curl -s $manifest_json | jq -r ".latest.snapshot")

#Metadata json url
release_json_url=$(curl -s  $manifest_json | jq -r --arg version "$release" '.versions[] | select(.id==$version) | .url' | tr -d \" )
snapshot_json_url=$(curl -s $manifest_json | jq -r --arg version "$snapshot" '.versions[] | select(.id==$version) | .url'| tr -d \" )

#jar file download urls
release_url=$(curl -s   $release_json_url | jq -r '.downloads.server.url' | tr -d \" )
snapshot_url=$(curl -s $snapshot_json_url | jq -r '.downloads.server.url' | tr -d \" )

#Publish date times
release_date=$(curl -s   $release_json_url | jq -r '.releaseTime' | tr -d \" )
snapshot_date=$(curl -s $snapshot_json_url | jq -r '.releaseTime' | tr -d \" )

#Files sha1sum
release_sum=$(curl -s   $release_json_url | jq -r '.downloads.server.sha1' | tr -d \" )
snapshot_sum=$(curl -s $snapshot_json_url | jq -r '.downloads.server.sha1' | tr -d \" )

#Download file if switch is preset
case $command in
  release) # Download release version
   wget -q -O $release_file --show-progress $release_url
   exit 1
   ;;
  snapshot) # Download snapshot version
   wget -q -O $snapshot_file --show-progress $snapshot_url
   exit 1
   ;;
  all) # Download both version
   wget -q -O $release_file --show-progress $release_url
   wget -q -O $snapshot_file --show-progress $snapshot_url
   exit 1
   ;;
  *) # No switch, prompt with version to download
   #Print information
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
         echo "Latest release   : " $release
         echo "Publish date     : " $release_date
         echo "File sha1sum     : " $release_sum
         #echo "Release JSON URL : " $release_json_url
         #echo "Server jar URL   : " $release_url
         #echo "Release jar file : " $release_file
          echo ""
          echo "Latest snapshot  : " $snapshot
         echo "Publish date     : " $snapshot_date
         echo "File sha1sum     : " $snapshot_sum
         #echo "Snapshot JSON URL: " $snapshot_json_url
         #echo "Snapshot jar URL : " $snapshot_url
         #echo "Snapshot jar file: " $snapshot_file
         printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
   ;;
esac

#ask and download
read -r -p "Released version is : "$release". Download? [y/N] " response
  if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]];then
   wget -q -O $release_file --show-progress $release_url
        fi


read -r -p "Snapshot version is : "$snapshot". Download? [y/N] " response
        if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]];then
                wget -q -O $snapshot_file --show-progress $snapshot_url
        fi
