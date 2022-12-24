# DaVinci Resolve PostgreSQL Workflow Tools
## Effortlessly set up automatic backups and automatic optimizations of DaVinci Resolve's PostgreSQL databases

Here are some workflow tools designed for **macOS** or **Linux** systems that are running as PostgreSQL servers for DaVinci Resolve.

This repository includes:
* For macOS Ventura:
	* A `bash` script that will let you effortlessly create, load, and start `launchd` user agents that will automatically backup and automatically optimize your PostgreSQL 13 databases
	* A `bash` script to *uninstall* the above tools
* For Red Hat Enterprise Linux 9:
	* A `bash` script that will let you effortlessly create and start `systemd` units and timers that will automatically backup and automatically optimize your PostgreSQL 13 databases
	* A `bash` script to *uninstall* the above tools

## How to use on macOS
Download the `macos-install.sh` file and execute the script with `sudo` permissions:
```
sudo sh macos-install.sh
```

The script will then:
1. Prompt you for the name of your PostgreSQL database;
2. Prompt you for the path of the folder where your backups will go;
3. Prompt you for how often you want to back the database up, in seconds; and
4. Prompt you for how often you want to optimize the database, in seconds.

Once you run through this script, you will be automatically backing up and optimizing your database according to whatever parameters you entered.

The script creates macOS `launchd` daemons, so these automatic backups and automatic database optimizations will continue on schedule, even after the system is rebooted. It's neither necessary nor desirable to run the script more than once per individual Resolve database.

To verify that everything is in working order, you can periodically check the log files located in `/Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/`.

### `zsh` vs. `bash`
macOS Ventura's the default shell is `zsh`. However, these scripts' shebangs still specify the use of `bash`, which has still been included since the switch from back in macOS Catalina. The scripts do not use any incompatible word splitting or array indices, so the scripts should be easily converted to native `zsh` in future releases of macOS. For more information, see [Scripting OS X](https://scriptingosx.com/zsh/).

## How to use on Red Hat Enterprise Linux
From an administrative user account, download the `enterprise-linux-install.sh` file and then execute the script:
```
sudo sh enterprise-linux-install.sh
```

The script will then:
1. Prompt you for the name of your PostgreSQL database;
2. Prompt you for the path of the folder where your backups will go;
    - Be sure to use the absolute path
3. Prompt you for how often you want to back the database up; and
    - Be sure to use [`systemd` notation](https://www.freedesktop.org/software/systemd/man/systemd.time.html) like `1h` or `3h` or `1d`, etc.
4. Prompt you for how often you want to optimize the database.
    - Be sure to use [`systemd` notation](https://www.freedesktop.org/software/systemd/man/systemd.time.html) like `1h` or `3h` or `1d`, etc.

Once you run through this script, you will be automatically backing up and optimizing your database according to whatever parameters you entered.

The script creates `systemd` units and timers, so these automatic backups and automatic database optimizations will continue on schedule, even after the system is rebooted. It's neither necessary nor desirable to run the script more than once per individual Resolve database.

To verify that everything is in working order, you can periodically check the log files located in `/usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs`.

## System requirements

This script has been tested and works for PostgreSQL 13 servers for:
- DaVinci Resolve 18

### macOS

* macOS Ventura
* EnterpriseDB PostgreSQL 13, as included from Blackmagic Design's DaVinci Resolve Project Server app

### Red Hat Enterprise Linux

* Red Hat Enterprise Linux 9
* PostgreSQL 13 from [RHEL's included DNF repository](https://www.postgresql.org/download/linux/redhat/)

## Background

Jathavan Sriram [wrote a great article back in 2014](https://web.archive.org/web/20141204010929/http://jathavansriram.github.io/2014/04/20/davinci-resolve-how-to-backup-optimize/) about how to use pgAdmin III tools in `bash`, instead of having to use the `psql` shell.

The core insights from his 2014 article still apply, but several crucial changes need to be made for modern systems:
1. Apple [deprecated `cron` in favor of `launchd`](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html). 
2. From DaVinci Resolve 12.5.4 through 17, DaVinci Resolve used PostgreSQL 9.5. For DaVinci Resolve 18 an onward, PostgreSQL 13 is recommended.
3. The locations of the `pg_dump`, `reindexdb`, and `vacuumdb` binaries in PostgreSQL 13 are different from what they were in PostgreSQL 8.4 and 9.5.

## What this script does

On macOS, this script creates and installs `bash` scripts and `launchd` daemons that, together, regularly and automatically backup and optimize the PostgreSQL databases that DaVinci Resolve uses.

On Red Hat Enterprise Linux, this script creates and installs `bash` scripts, `systemd` units, and `systemd` timers that, together, regularly and automatically backup and optimize the PostgreSQL databases that DaVinci Resolve uses. After a reboot, each `systemd` timer will be delayed by a random number of seconds, up to 180 seconds, so as to stagger the database utilities for optimal performance.

## Configuration

### macOS

The `.pgpass` file that the script creates assumes that the password for your PostgreSQL database is `DaVinci`, which is a convention from Blackmagic Design.

Make sure that you create the directory where your backups are going to go *before* running the script.

If you have any spaces in the full path of the directory where your backups are going, be sure to escape them with `\` when you run the script.

The script can be run from any admin user so long as it's run with `sudo` so as to have `root` user permissions.

Because the script generates `launchd` daemons, the backups and optimizations will occur if the machine is running, even without any user being logged in. 

### Red Hat Enterprise Linux

The `.pgpass` file that the script creates assumes that the password for your PostgreSQL database is `DaVinci`, which is a convention from Blackmagic Design.

Make sure that you create the directory where your backups are going to go *before* running the script.

Be sure to use the absolute path for the directory into which the backups will go.

The script can be run from any admin user so long as it's run with `sudo` so as to have `root` user permissions.

## Restoring from backup

The `*.backup` files that this script generates can be restored into a new, totally blank PostgreSQL database in the event of a disk failure. These `*.backup` files are also handy even just to migrate entire databases from one PostgreSQL server to another.

In the event of a disk failure hosting the PostgreSQL database, the procedure to restore from these `*.backup` files to a new PostgreSQL server is as follows:
1. Set up a new, totally fresh PostgreSQL server
2. Create a fresh PostgreSQL database on the server, naming your database whatever you want it to be named
	1. If the version of Resolve you're using is the same version you were using when the `*.backup` file was created, you can just connect your client workstation and create a new blank database via the GUI;
	2. But if your `*.backup` file was created for some earlier version of Resolve, you'll need to become the `postgres` user with `root` permissions and create a _completely blank_ database:
		```
		$ sudo su - postgres
		$ createdb <newdatabasename>
		```
3. Run the command:
	```
	$ pg_restore --host localhost --username postgres --password --single-transaction --clean --if-exists --dbname=<dbname> <full path to your backup file>
	```
	You'll need to enter the password for the `postgres` user. This is the password for the PostgreSQL database user `postgres`, not the OS user.

4. If the version of Resolve you're using is the same version you were using when the `*.backup` file was created, you should be good to go, but if your `*.backup` file was created for some earlier version of Resolve, you should now be able to connect the the database via the GUI on the client and then upgrade it for your current version.

## Uninstall

### Uninstall on macOS

If you wish to stop automatically backing up and optimizing a particular database, you can run `macos-uninstall.sh`:

```
sudo sh macos-uninstall.sh
```

The script will ask you what database you want to stop backing up and optimizing. The database you specify will then stop being backed up, stop being optimized, and all relevant files will be safely and cleanly removed from your system. The database itself will remain untouched.

### Uninstall on Red Hat Enterprise Linux

If you wish to stop automatically backing up and optimizing a particular database, you can run `enterprise-linux-uninstall.sh`:

```
sudo sh enterprise-linux-uninstall.sh
```

The script will ask you what database you want to stop backing up and optimizing. The database you specify will then stop being backed up, stop being optimized, and all relevant files will be safely and cleanly removed from your system. The database itself will remain untouched.
