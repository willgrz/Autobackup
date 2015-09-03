#!/bin/bash
#on BSD is /usr/local/bin/bash
#gpg on BSD is /usr/local/bin/gpg

#backup root dir
backupdir=/backup
#file with servers
serverfile=serverlist
#how long to keep backups, 0 to disable
holdbackup=0
#inetnal network
intnet="10.250."
#gpg key for encryption
gkey=2AC179D0


function backupbox {
#call backupbox servername ip:port user"
		sname=$1
		sipp=$2
		suser=$3
		#convert IP:Port to IP and Port
                eip=$(echo $sipp | sed -e 's/:/ /g' | awk '{print $1}')
                eport=$(echo $sipp | sed -e 's/:/ /g' | awk '{print $2}')
#		echo $eip $eport
		#cd into backup dir
		echo cd $backupdir
		#mkdir backupserver dir if not already available
		echo mkdir $backupserver
		#remove old files
		if [ "$holdbackup" != "0" ]; then
			echo find $backupdir/$backupserver/*.enc -mtime +$holdbackup -exec rm {} \;
		fi
		#set ymd
		ymdstr=$(date +'%Y-%m-%d-%H%M')
		#run actual backup
		echo ssh -p $eport $suser@$eip 'tar --numeric-owner --exclude "/var/vmail" --exclude "/nfs" --exclude "/kvm" --exclude "/data" --exclude "/var/www/html" --exclude "/mnt" --exclude "/var/spool/squid" --exclude "/var/spool/squid3" --exclude "/proc" --exclude "/backup" --exclude "/sys" --exclude "/dev" -cz /' \| /usr/bin/gpg --trust-model always --encrypt --recipient $gkey -o "$backupserver/$ymdstr.tar.gz.enc"
}


for server in $(cat serverlist | awk '{print $1}'); do
	backupserver=$server
	inthostp=$(cat serverlist | grep $server | awk '{print $2}')
        exthostp=$(cat serverlist | grep $server | awk '{print $3}')
        luser=$(cat serverlist | grep $server | awk '{print $4}')
#	echo "backing up $backupserver with int $inthostp and ext $exthostp and user $luser"

#check if backup server has int
intcheck=dummy
	ifconfig | grep $intnet  >> /dev/null
		if [ $? -ne 1 ]; then
#		     echo "has int"
		     intcheck=1
		 else
#		     echo "has no int"
		     intcheck=0
	 	fi

#take that and put it in if-else
	if [ "$intcheck" == "0" ]; then
#		echo "has no int, run ext, no further check"	  	
		backupbox $backupserver $exthostp $luser

	elif [ "$intcheck" == "1" ]; then
#		echo 'has int, test int'
		if [ "$inthostp" != "0:0" ]; then
			#server has int, run int
			backupbox $backupserver $inthostp $luser
		elif [ "$inthostp" == "0:0" ]; then
			#server has no int, run ext
			backupbox $backupserver $exthostp $luser
		fi
	else
		echo "Error - intcheck not working"
		exit 1
	fi




done
