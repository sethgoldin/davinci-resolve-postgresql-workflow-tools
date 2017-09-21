# backup-resolve-postgresql
## Automatic backups for Resolve 14's PostgreSQL databases

This project has three files that are designed to be modified and installed onto a macOS Sierra 10.12.6 system.

## System requirements:
* macOS Sierra 10.12.6
* Blackmagic Design DaVinci Resolve 14.0.0.078
* PostgreSQL 9.5.9
* pgAdmin III
	
These files are designed to be installed to the boot drive of the Mac that is the PostgreSQL server, not a remote machine on the network.

## Background

Jathavan Sriram wrote [a great article back in 2014](http://jathavansriram.github.io/2014/04/20/davinci-resolve-how-to-backup-optimize/) about how to use `./pg_dump` inside of pgAdmin in `bash`, instead of having to use the `psql` shell. 

The core insights from his 2014 article still apply, but two crucial changes need to be made for modern systems:
1. Apple [has deprecated `cron` in favor of `launchd`](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html). 
2. Starting with DaVinci Resolve 12.5.4 on macOS, DaVinci Resolve has been using PostgreSQL 9.5.

## What's included in this repository

Three files are provided in this respository:
* A template `plist` for `launchd`, which should be modified and put into `~/Library/LaunchAgents` with permissions `755`
* A template `bash` script
* A `.pgpass` file, which she be put into `~` with permissions `600`

## Installation tips

The `.pgpass` file assumes that your password for the PostgreSQL database is `DaVinci` as per the recommendation from the Resolve 14 manual. If you've set up your PostgreSQL database with a different password, use that.
	
There are comments within the template `plist` file and template `bash` file that explain which parameters to modify.

These files can be installed to and run from a regular user account with admin privileges. It's neither necessary nor desirable to run this script from within either the `root` or `postgres` user accounts.

## Style guide

I recommend duplicating one `plist` file and one `bash` script per individual PostgreSQL database, and naming these files identically to their individual PostgreSQL databases--the same names that are created from within Resolve's GUI. Wherever you see `yourdbname` in the templates, use the same names assigned from Resolve's GUI.

## Configuration options

By default, the `launchd` will back up the configured PostgreSQL database every 3 hours [every 10800 seconds]. This value can be changed in the `plist` file.

## Restoring from backup

The `./pg_dump` command in the `bash` script is the equivalent of the "Backup" button in the Resolve GUI's database manager window. The `*.backup` files that this script generates can be restored into a new, totally blank PostgreSQL database in the event of a disk failure. These `*.backup` files are also handy even just to migrate databases to a different PostgreSQL server.

These `*.backup` files can be easily restored via the Resolve GUI's database manager window.

## Loading the agent into `launchd`

Once you have the files configured and installed into the correct directories, you can *either* reboot your computer, *or* you can use `launchctl` to load the `plist` file into `launchd` and start the agent without rebooting:

	launchctl load ~/Library/LaunchAgents/yourdbname.plist
	launchctl start com.resolve.backup.yourdbname
	
Enjoy!
