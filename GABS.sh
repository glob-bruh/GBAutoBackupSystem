#!/bin/bash

########
# GABS #
########
# GlobBruh Automated Backup System
# GlobBruh, 2024
# This script MUST be ran as root, or it must be called by a root crontab.

echo "================="
echo "=      GABS     ="
echo "= Version 2.0.0 ="
echo "================="

# Delete this warning after final tests pass and before merge into main.
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "! ! ! !                           WARNING:                           ! ! ! !"
echo "! ! ! !                UNTESTED DEVELOPMENT VERSION                  ! ! ! !"
echo "! ! ! ! Absolutely do NOT use this version in production enviroments ! ! ! !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""

splitText() {
    IFS=$3
    read -ra strArray <<< "$1"
    echo "${strArray[$2]}"
}

showHelp() {
    echo "---------------"
    echo "GABS HELP PAGE:"
    echo "---------------"
    echo ""
    echo "Project Page: https://github.com/glob-bruh/GBAutoBackupSystem"
    echo ""
    echo "Syntax: GABS.sh [-s] <script path> [-F] [-h]"
    echo "Options:"
    echo "h - Show this help screen."
    echo "s - Specify script path."
    echo "F - Force, run script without checking for errors."
    echo "    VERY DANGEROUS, Use with extreme caution."
    echo ""
    echo "Scripting Syntax:"
    echo "Instead of using command line arguments, GABS now relies on scripts for backing up content."
    echo ""
    echo "Created by GlobBruh - (c) 2024 "
    echo ""
}

printHelp=0
while getopts ":hs:" CommandFlags
do
    case "${CommandFlags}" in
		# Parameters:
        h) showHelp ; exit;;
        s) scriptPath=${OPTARG};;
        *) echo "ERROR: Invalid option! Try running 'GABS.sh -h' to view help." ; exit;;
	esac
done
logFilename="/dev/null"
while IFS= read -r lineInFile; do
    inputDeterminingWord=$(splitText "$lineInFile" 0 " ")
    case $inputDeterminingWord in
        "FILECHKCPY")
            targPath=$(splitText "$lineInFile" 1 " ")
            destPath=$(splitText "$lineInFile" 2 " ")
            echo "I will check and copy from $targPath to $destPath."
        	rsync -av --delete $targPath $destPath --log-file /tmp/gabsRsyncLog.txt
        	rsyncstat=$?
        	echo "[$(date)] ### --- RSync Log Start --- ###" >> $logFilename
        	cat /tmp/gabsRsyncLog.txt >> $logFilename
        	echo "[$(date)] ### ---- RSync Log End ---- ###" >> $logFilename
        	rm /tmp/gabsRsyncLog.txt
        	echo "[$(date)] RSync Exit Status: $(echo $rsyncstat)." >> $logFilename
            sleep 7
            ;;
        "MOUNTDRIVE")
            diskToMountUUID=$(splitText "$lineInFile" 1 " ")
            diskPathToMount=$(splitText "$lineInFile" 2 " ")
            echo "I will mount disk $diskToMountUUID to $diskPathToMount."
            mountout=$(mount -t ext4 UUID=$diskToMountUUID $diskPathToMount 2>&1)
            if [ $? -eq 0 ]; then
                echo "Mount Success..."
                echo "[$(date)] Drive $diskToMountUUID Mounted Success." >> $logFilename
                sleep 7
            else
            	echo "[$(date)] Drive $diskToMountUUID Mount FAILURE! Script was aborted! Please investigate!" >> $logFilename
    	        echo "[$(date)] MOUNT output: $(echo $mountout)" >> $logFilename
	            echo "MOUNT DIDNT RETURN 0, aborting!" ; exit
            fi
            ;;
        "REPORTERSP")
            logFilename="/dev/null"
            echo "Logging has been stopped."
            ;;
        "REPORTERST")
            pathToLog=$(splitText "$lineInFile" 1 " ")
            todayDate=$(date +%b-%d-%Y_%H-%M-%S)
            logFilename="${pathToLog}/gabsLog-${todayDate}.log"
            echo "*** GABS LOG FILE FOR $todayDate ***" >> $logFilename
            echo "We will now log to $logFilename."
            ;;
        "UNMOUNTDRV")
            diskToUnmount=$(splitText "$lineInFile" 1 " ")
	        umountout=$(umount $diskToUnmount 2>&1)
	        if [ $? -eq 0 ]; then
	        	echo "Unmount Success..."
	        	echo "[$(date)] Drive at $diskToUnmount Unmounted Success." >> $logFilename
	        else
	        	echo "Unmount Fail! Check log."
	        	echo "[$(date)] Drive at $diskToUnmount Unmounted FAILURE! Script was aborted! Please investigate!" >> $logFilename
	        	echo "[$(date)] UMOUNT output: $(echo $umountout)" >> $logFilename ; exit
	        fi
            ;;
        "VMMODETYPE")
            virtualMachineMode=$(splitText "$lineInFile" 1 " ")
            echo "I will only use $virtualMachineMode-based commands when running VM control commands."
            ;;
    esac
done < $scriptPath