#!/bin/bash

########
# GABS #
########
# GlobBruh Automated Backup System
# GlobBruh, 2023
# Version 1.0
# This script MUST be ran as root, or it must be called by a root crontab.

echo "================================"
echo "=             GABS             ="
echo "= (Formerly GBUS-R&I and GBBS) ="
echo "================================"

# Parameters:
BACKUPDISKUUID=$1 # Disk UUID of the backup drive.
BACKUPMOUNTPATH=$2 # The path where the backup disk from above should be mounted.
SOURCERUNNINGPATH=$3 # Path where files should be checked from.
BACKUPDESTINATIONPATH=$4 # Path where the files being backed up should go.
BACKUPCONFIG=$5 # Should configuration files be backed up? Only takes "true" or "false".


todayDate=$(date +%b-%d-%Y)
echo "*** GABS LOG FILE FOR $todayDate ***" >> /var/log/gbbs/gbbsLog-$todayDate.txt
echo "Parameters: $BACKUPDISKUUID - $BACKUPMOUNTPATH - $SOURCERUNNINGPATH - $BACKUPDESTINATIONPATH - $BACKUPCONFIG"
echo "[$(date)] ### ---- Parameter Log Start ---- ###" >> /var/log/gbbs/gbbsLog-$todayDate.txt
echo "[$(date)] Drive $BACKUPDISKUUID mounts to $BACKUPMOUNTPATH." >> /var/log/gbbs/gbbsLog-$todayDate.txt
echo "[$(date)] New files from $SOURCERUNNINGPATH are copied to $BACKUPDESTINATIONPATH." >> /var/log/gbbs/gbbsLog-$todayDate.txt
if [ $BACKUPCONFIG == "true" ]; then
	echo "[$(date)] Configuration files will be copied" >> /var/log/gbbs/gbbsLog-$todayDate.txt
else
	echo "[$(date)] Configuration files will NOT be copied" >> /var/log/gbbs/gbbsLog-$todayDate.txt
fi
echo "[$(date)] ### ---- Parameter Log End ---- ###" >> /var/log/gbbs/gbbsLog-$todayDate.txt
mountout=$(mount -t ext4 UUID=$BACKUPDISKUUID $BACKUPMOUNTPATH 2>&1)
if [ $? -eq 0 ]; then
	echo "Mount Success..."
	echo "[$(date)] Drive Mounted Success." >> /var/log/gbbs/gbbsLog-$todayDate.txt
	sleep 10
	rsync -av --delete $SOURCERUNNINGPATH $BACKUPDESTINATIONPATH --log-file /var/log/gbbs/rsyncLOG.txt
	rsyncstat=$?
	echo "[$(date)] ### --- RSync Log Start --- ###" >> /var/log/gbbs/gbbsLog-$todayDate.txt
	cat /var/log/gbbs/rsyncLOG.txt >> /var/log/gbbs/gbbsLog-$todayDate.txt
	echo "[$(date)] ### ---- RSync Log End ---- ###" >> /var/log/gbbs/gbbsLog-$todayDate.txt
	rm /var/log/gbbs/rsyncLOG.txt
	echo "[$(date)] RSync Exit Status: $(echo $rsyncstat)." >> /var/log/gbbs/gbbsLog-$todayDate.txt
	if [ $BACKUPCONFIG == "true" ]; then
		echo "Copy operations..."
		# Add locations to your own configs here!
		cp /etc/ssh/banner.txt ${BACKUPMOUNTPATH}Configs/OpenSSH/
		cp /etc/ssh/sshd_config ${BACKUPMOUNTPATH}Configs/OpenSSH/
		cp /etc/vsftpd.conf ${BACKUPMOUNTPATH}Configs/VSFTPD/
		cp /etc/openvpn/server.conf ${BACKUPMOUNTPATH}Configs/OpenVPN/
	fi
	sleep 10
	umountout=$(umount $BACKUPMOUNTPATH 2>&1)
	if [ $? -eq 0 ]; then
		echo "Unmount Success..."
		echo "[$(date)] Drive Unmounted Success." >> /var/log/gbbs/gbbsLog-$todayDate.txt
	else
		echo "Unmount Fail! Check log."
		echo "[$(date)] Drive Unmounted FAILURE! Please investigate!" >> /var/log/gbbs/gbbsLog-$todayDate.txt
		echo "[$(date)] UMOUNT output: $(echo $umountout)" >> /var/log/gbbs/gbbsLog-$todayDate.txt
	fi
else
	echo "[$(date)] Drive Mount FAILURE!" >> /var/log/gbbs/gbbsLog-$todayDate.txt
	echo "[$(date)] MOUNT output: $(echo $mountout)" >> /var/log/gbbs/gbbsLog-$todayDate.txt
	echo "MOUNT DIDNT RETURN 0, not performing backup for this drive!"
fi
echo "[$(date)] All done!" >> /var/log/gbbs/gbbsLog-$todayDate.txt
echo "-------------"
echo "- All done! -"
echo "-------------"
