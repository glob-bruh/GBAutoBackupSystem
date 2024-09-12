#!/bin/bash

########
# GABS #
########
# GlobBruh Automated Backup System
# GlobBruh, 2024
# This script MUST be ran as root, or it must be called by a root crontab.

echo "===================================="
echo "= GlobBruh Automated Backup System ="
echo "=               GABS               ="
echo "=          Version 2.0.0           ="
echo "===================================="

# Delete this warning after final tests pass and before merge into main.
REDTEXT='\033[0;31m'
NOCOLOR='\033[0m'
echo -e ""
echo -e "${REDTEXT}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo -e "${REDTEXT}! ! ! !                           WARNING:                            ! ! ! !"
echo -e "${REDTEXT}! ! ! !                      PROTOTYPE VERSION                        ! ! ! !"
echo -e "${REDTEXT}! ! ! ! Absolutely do NOT use this version in production enviroments. ! ! ! !"
echo -e "${REDTEXT}! ! ! !        As stated by GPL3, I am not liable for damages.        ! ! ! !"
echo -e "${REDTEXT}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo -e "${NOCOLOR}"

splitText() {
    IFS=$3
    read -ra strArray <<< "$1"
    echo "${strArray[$2]}"
}

showHelp() {
    echo "---------------"
    echo "GABS HELP PAGE:"
    echo "---------------"
    if [ "$EUID" -ne 0 ] ; then
        echo ""
        echo "Note that this script has to be ran as root."
    fi
    echo ""
    echo "Project Page: https://github.com/glob-bruh/GBAutoBackupSystem"
    echo ""
    echo "Syntax: GABS.sh [ -s <script path> ] [ -F ] [ -h ]"
    echo "Options:"
    echo "-s: Specify script path."
    echo "-h: Show this help screen."
    echo ""
    echo "Scripting Syntax:"
    echo "Instead of using command line arguments, GABS now relies on scripts for backing up content."
    echo ""
    echo "Please see GABSManual.txt for more info."
    echo ""
    echo "Created by GlobBruh - (c) 2024 "
    echo ""
}

vboxGetVMState() {
    x=$(sudo -u "$vmUserToRunAs" vboxmanage showvminfo "$1" --machinereadable)
    x=$(echo "$x" | grep "VMState=")
    x=$(splitText "$x" 1 "=")
    z=$(splitText $x 1 '"')
    echo $z
}

scriptFunction() {
    logFilename="/dev/null"
    while IFS= read -r lineInFile ; do
        inputDeterminingWord=$(splitText "$lineInFile" 0 " ")
        case $inputDeterminingWord in
            "FLDRCHKCPY")
                targPath=$(splitText "$lineInFile" 1 " ")
                destPath=$(splitText "$lineInFile" 2 " ")
                echo "[$(date)] RSync - Copy NEW files from $targPath to $destPath." >> $logFilename
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
                mountout=$(mount -t ext4 UUID=$diskToMountUUID $diskPathToMount 2>&1)
                if [ $? -eq 0 ]; then
                    echo "Mount Success."
                    echo "[$(date)] Drive $diskToMountUUID Mounted Success." >> $logFilename
                    sleep 7
                else
                	echo "[$(date)] Drive $diskToMountUUID Mount FAILURE! Script was aborted! Please investigate!" >> $logFilename
        	        echo "[$(date)] MOUNT output: $(echo $mountout)" >> $logFilename
                    echo "MOUNT DIDNT RETURN 0! Mount Fail, aborting and please check log!" ; exit
                fi
                ;;
            "REPORTERSP")
                echo "Logging stopped."
                logFilename="/dev/null"
                ;;
            "REPORTERST")
                echo "Logging started."
                pathToLog=$(splitText "$lineInFile" 1 " ")
                todayDate=$(date +%b-%d-%Y_%H-%M-%S)
                logFilename="${pathToLog}/gabsLog-${todayDate}.log"
                echo "*** GABS LOG FILE FOR $todayDate ***" >> $logFilename
                ;;
            "UNMOUNTDRV")
                diskToUnmount=$(splitText "$lineInFile" 1 " ")
    	        umountout=$(umount $diskToUnmount 2>&1)
    	        if [ $? -eq 0 ]; then
    	        	echo "Unmount Success."
    	        	echo "[$(date)] Drive at $diskToUnmount Unmounted Success." >> $logFilename
                    sleep 7
    	        else
    	        	echo "[$(date)] Drive at $diskToUnmount Unmounted FAILURE! Script was aborted! Please investigate!" >> $logFilename
    	        	echo "[$(date)] UMOUNT output: $(echo $umountout)" >> $logFilename
                    echo "UMOUNT DIDNT RETURN 0! Unount Fail, aborting and please check log!" ; exit
    	        fi
                ;;
            "VMCLOSESYS")
                vmToClose=$(splitText "$lineInFile" 1 " ")
                vmStopType=$(splitText "$lineInFile" 2 " ")
                echo "Close VM ${vmToClose}."
                case "${virtualMachineMode}" in
                    "vbox")
                        case "$vmStopType" in
                            "pause") sudo -u "$vmUserToRunAs" vboxmanage controlvm "$vmToClose" pause;;
                            "save")  sudo -u "$vmUserToRunAs" vboxmanage controlvm "$vmToClose" savestate;;
                            "acpi")
                                sudo -u "$vmUserToRunAs" vboxmanage controlvm "$vmToClose" acpipowerbutton
                                if [ $? -eq 0 ]; then
                                    while [ $(vboxGetVMState $vmToClose) != "poweroff" ] ; do 
                                        sleep 5
                                    done
                                fi
                                ;;
                        esac
                        ;;
                    "kvm")
                        echo "NOT IMPLEMENTED YET! Aborting for safety." ; exit
                        ;;
                esac
                echo "[$(date)] Close VM $vmToClose using stop type $vmStopType." >> $logFilename
                ;;
            "VMMODETYPE")
                virtualMachineMode=$(splitText "$lineInFile" 1 " ")
                vmUserToRunAs=$(splitText "$lineInFile" 2 " ")
                if [ -z "${vmUserToRunAs}" ] ; then
                    vmUserToRunAs=$USER
                fi
                echo "VM mgnt configured in ${virtualMachineMode} mode."
                echo "[$(date)] VM managment mode set to $virtualMachineMode. VM user has been set to $vmUserToRunAs." >> $logFilename
                ;;
            "VMSTARTSYS")
                vmToStart=$(splitText "$lineInFile" 1 " ")
                vmCurrentState=$(vboxGetVMState $vmToStart)
                echo "Start VM ${vmToStart}."
                case "${virtualMachineMode}" in
                    "vbox")
                        case "${vmCurrentState}" in
                            "paused")   sudo -u "$vmUserToRunAs" vboxmanage controlvm "$vmToStart" resume;;
                            "poweroff") sudo -u "$vmUserToRunAs" vboxmanage startvm --type headless "$vmToStart";;
                            "saved")    sudo -u "$vmUserToRunAs" vboxmanage startvm --type headless "$vmToStart";;
                        esac
                        ;;
                    "kvm")
                        echo "NOT IMPLEMENTED YET! Aborting for safety." ; exit
                        ;;
                esac
                echo "[$(date)] Start VM $vmToStart. VM was in $vmCurrentState state before being started." >> $logFilename
                ;;
            *) echo "$inputDeterminingWord is an unknown term. Skipping line.";;
        esac
    done < $scriptPath
}

while getopts "hs:" CommandFlags ; do
    case "${CommandFlags}" in
        h) showHelp ; exit;;
        s) scriptPath=${OPTARG};;
        *) echo "ERROR: Invalid option! Try running 'GABS.sh -h' to view help." ; exit;;
	esac
done

if [ "$EUID" -ne 0 ] ; then
    echo "This script must be ran as root!" ; exit
fi

if [ -z "${scriptPath}" ] ; then
    echo "You need to provide a script path!" ; exit
fi

scriptFunction
