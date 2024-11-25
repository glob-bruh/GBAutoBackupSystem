# GlobBruh Automated Backup System (GABS)

# This readme is outdated. Please see [GABS Manual](./doc/GABS-Manual.txt) for latest info.

## Preface:

This script is designed to automatically replicate contents from one drive to another. Its original use is to have data replication without the use of RAID. 

For example, if Drive A hosts a folder and Drive B is the backup drive for the aformentioned folder, then the following will happen:

1) Drive B will be mounted.
2) If requested, server configuration files will be copied from Drive A to Drive B.
3) The contents of the requested folder in Drive A will be synchronized with Drive B using RSYNC.
4) Drive B will be unmounted when RSYNC finishes.

## Setup:

### Usage:

```
GABS.sh <BACKUPDISKUUID> <BACKUPMOUNTPATH> <SOURCERUNNINGPATH> <BACKUPDESTINATIONPATH> <BACKUPCONFIG>

BACKUPDISKUUID         = Disk Partition UUID of the backup drive.
BACKUPMOUNTPATH        = The path where the backup disk from above should be mounted.
SOURCERUNNINGPATH      = Path where files should be checked from.
BACKUPDESTINATIONPATH  = Path where the files being backed up should go.
BACKUPCONFIG           = Should configuration files be backed up? Only takes "true" or "false".
```
Permissions to mount disks is required. 

### Automated Use:

The script can be automatically ran by using cron. Run the command `crontab -e` and add an entry that executes the script. You will need to make an entry for each disk pair. 

## Contributing:

Please thoroughly test the script before creating a pull request. Ensure it can be executed on-the-fly without **any** script-related failures.

Be sure to increase the version number (found in a comment near the top of the script). 

## License:

This project is licensed under [The 3-Clause BSD License](https://opensource.org/license/bsd-3-clause).
