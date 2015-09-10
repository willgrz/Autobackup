#!/bin/bash
#!/usr/local/bin/bash on BSD

#backup root dir
backupdir=/data/serverbackups/autobackup
#file with servers
serverfile=serverlist
#inetnal network
intnet="10.250."
#gpg key for encryption
gkey=2AC179D0
#gpg binary, change for BSD
cgpg=$(which gpg)




function backupbox {
#call backupbox servername ip:port user holdb"
		sname=$1
		sipp=$2
		suser=$3
		sholdb=$4
		#convert IP:Port to IP and Port
                eip=$(echo $sipp | sed -e 's/:/ /g' | awk '{print $1}')
                eport=$(echo $sipp | sed -e 's/:/ /g' | awk '{print $2}')
#		echo $eip $eport
		#cd into backup dir
		cd $backupdir
		#mkdir backupserver dir if not already available
		mkdir $backupserver
		#remove old files
		if [ "$sholdb" != "0" ]; then
			find $backupdir/$backupserver/*.enc -mtime +$sholdb -exec rm {} \;
		fi
		#set ymd
		ymdstr=$(date +'%Y-%m-%d-%H%M')
		#run actual backup
		ssh -p $eport $suser@$eip 'tar --numeric-owner --exclude "/smokeping" --exclude "/var/vmail" --exclude "/nfs" --exclude "/kvm" --exclude "/data" --exclude "/var/www/html" --exclude "/mnt" --exclude "/var/spool/squid" --exclude "/var/spool/squid3" --exclude "/proc" --exclude "/backup" --exclude "/sys" --exclude "/dev" -cz /' | $cgpg --trust-model always --encrypt --recipient $gkey -o "$backupserver/$ymdstr.tar.gz.enc"
}


for server in $(cat serverlist | awk '{print $1}' | grep -v '#'); do
	backupserver=$server
	inthostp=$(cat serverlist | grep $server | awk '{print $2}')
        exthostp=$(cat serverlist | grep $server | awk '{print $3}')
        luser=$(cat serverlist | grep $server | awk '{print $4}')
	holdb=$(cat serverlist | grep $server | awk '{print $5}')
	echo "backing up $backupserver with int $inthostp and ext $exthostp and user $luser with holdbackup of $holdb"

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
		backupbox $backupserver $exthostp $luser $holdb

	elif [ "$intcheck" == "1" ]; then
#		echo 'has int, test int'
		if [ "$inthostp" != "0:0" ]; then
			#server has int, run int
			backupbox $backupserver $inthostp $luser $holdb
		elif [ "$inthostp" == "0:0" ]; then
			#server has no int, run ext
			backupbox $backupserver $exthostp $luser $holdb
		fi
	else
		echo "Error - intcheck not working"
		exit 1
	fi




done
