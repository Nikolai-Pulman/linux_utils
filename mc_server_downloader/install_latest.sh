#!/bin/bash

jsonurl="https://launchermeta.mojang.com/mc/game/version_manifest.json"

releasename="minecraft_server.jar"
snapshotname="minecraft_latest.jar"

#No change after that point

release=$(curl -s $jsonurl | jq -r ".latest.release")
snapshot=$(curl -s $jsonurl | jq -r ".latest.snapshot")

#ask and download
read -r -p "Latest released version is : "$release". Update [y/N] " response
	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]];then
		wget -q -O $releasename --show-progress https://s3.amazonaws.com/Minecraft.Download/versions/$release/minecraft_server.$release.jar
        fi


read -r -p "Latest snapshot version is : "$snapshot". Update [y/N] " response
        if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]];then
                wget -q -O $snapshotname --show-progress https://s3.amazonaws.com/Minecraft.Download/versions/$snapshot/minecraft_server.$snapshot.jar
        fi



