# DaVinci Resolve PostgreSQL Workflow Tools
## Tools to effortlessly set up automatic backups and automatic optimizations of DaVinci Resolve 14 Studio PostgreSQL databases

This is a `bash` script that is designed to be run on a macOS Sierra 10.12.6 system that's running as a PostgreSQL server for DaVinci Resolve Studio 14.

## How to use
1. Download the file `automate-workflow.sh` to your `~/Downloads` folder.
2. In Terminal, execute the following commands to run the script:
```
chmod 755 ~/Downloads/automate-workflow.sh
~/Downloads/automate-workflow.sh
```

The script will then:
1. Prompt you for the name of your PostgreSQL database;
2. Prompt you for the path of the folder where your backups will go;
3. Prompt you for how often you want to back the database up, in seconds; and
4. Prompt you for how often you want to optimize the database, in seconds.

Once you run through this script, you will be automatically backing up and optimizing your database according to whatever parameters you inputted.

The script creates macOS `launchd` user agents, so these automatic backups and automatic database optimizations will continue on schedule, even after the system is rebooted. There is no need to run the script more than once per database.

To verify that everything is in working order, you can periodically check the log files located in `~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs`.

N.B. Because the script generates `launchd` user agents, the backups and optimizations will only occur while you are logged into the same account that you were using when you ran the script.

## System requirements:
* macOS Sierra 10.12.6 (16G1036 or 16G1212)
* Blackmagic Design DaVinci Resolve Studio (14.0.0.078, 14.0.1.008, 14.1.0.018, 14.1.1.005, 14.2.0.012, 14.2.1.007, or 14.3.0.005)
* PostgreSQL 9.5.4 or later (as provided by the DaVinci Resolve Studio installer)
* pgAdmin III
	
## Background

Jathavan Sriram wrote [a great article back in 2014](http://jathavansriram.github.io/2014/04/20/davinci-resolve-how-to-backup-optimize/) about how to use `./pg_dump` inside of pgAdmin in `bash`, instead of having to use the `psql` shell. 

The core insights from his 2014 article still apply, but several crucial changes need to be made for modern systems:
1. Apple [has deprecated `cron` in favor of `launchd`](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html). 
2. Starting with DaVinci Resolve 12.5.4 on macOS, DaVinci Resolve has been using PostgreSQL 9.5.
3. The locations of `reindexdb` and `vacuumdb` in PostgreSQL 9.5.4 have changed.

## What this script does

This script creates and installs all the files necessary to have `launchd` continuously backup and optimize the PostgreSQL databases that DaVinci Resolve Studio uses. `launchd` is macOS's built-in tool

Three files are provided in this respository:
* A template `plist` for `launchd`, which should be modified and put into `~/Library/LaunchAgents` with permissions `755`
* A template `bash` script
* A `.pgpass` file, which she be put into `~` with permissions `600`

These files are designed to be installed to the boot drive of the Mac that is the PostgreSQL server, not a remote machine on the network.

## Installation tips

The `.pgpass` file assumes that your password for the PostgreSQL database is `DaVinci` as per the recommendation from the Resolve 14 manual. If you've set up your PostgreSQL database with a different password, use that.
	
There are comments within the template `plist` file and template `bash` file that explain which parameters to modify.

These files can be installed to and run from a regular user account with admin privileges. It's neither necessary nor desirable to run this script from within either the `root` or `postgres` user accounts.

## Style guide

I recommend duplicating one `plist` file and one `bash` script per individual PostgreSQL database, and naming these files identically to their individual PostgreSQL databases--the same names that are created from within Resolve's GUI. Wherever you see `yourdbname` in the templates, use the same names assigned from Resolve's GUI.

## Configuration options

By default, the`plist` file for `launchd` will back up the configured PostgreSQL database every 3 hours [every 10800 seconds]. This value can be changed in the `plist` file.

## Loading the agent into `launchd`

Once you have the files configured and installed into the correct directories, you can *either* reboot your computer, *or* you can use `launchctl` to load the `plist` file into `launchd` and start the agent without rebooting:

	launchctl load ~/Library/LaunchAgents/yourdbname.plist
	launchctl start com.resolve.backup.yourdbname

## Restoring from backup

The `./pg_dump` command used in the `bash` script is the equivalent of pressing the "Backup" button in the Resolve GUI's database manager window. The `*.backup` files that this script generates can be restored into a new, totally blank PostgreSQL database in the event of a disk failure. These `*.backup` files are also handy even just to migrate databases to a different PostgreSQL server.

These `*.backup` files can be easily restored via the Resolve GUI's database manager window. Just press the "Restore" button and select the `*.backup` file you wish to restore.

Enjoy!
