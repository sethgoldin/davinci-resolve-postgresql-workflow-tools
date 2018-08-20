# DaVinci Resolve PostgreSQL Workflow Tools
## Effortlessly set up automatic backups and automatic optimizations of DaVinci Resolve Studio's PostgreSQL databases

Here are some workflow tools designed for **Mac** or **Linux** systems that are running as PostgreSQL servers for DaVinci Resolve Studio.

This repository includes:
* For macOS:
	* A `bash` script that will let you effortlessly create, load, and start `launchd` user agents that will automatically backup and automatically optimize your PostgreSQL databases
	* A `bash` script to *uninstall* the above tools
* For CentOS Linux:
	* A `bash` script for CentOS Linux that will let you effortlessly create and start `systemd` units and timers that will automatically backup and automatically optimize your PostgreSQL databases
	* A `bash` script to *uninstall* the above tools

## How to use on macOS
1. Download the repository `davinci-resolve-postgresql-workflow-tools-master` to your `~/Downloads` folder.
2. In Terminal, execute the following command to run the script:
```
~/Downloads/davinci-resolve-postgresql-workflow-tools-master/macos-automate-workflow.sh
```
If you run into a permissions error, change the permissions on the file by running the following command first:
```
chmod 755 ~/Downloads/davinci-resolve-postgresql-workflow-tools-master/macos-automate-workflow.sh
```

The script will then:
1. Prompt you for the name of your PostgreSQL database;
2. Prompt you for the path of the folder where your backups will go;
3. Prompt you for how often you want to back the database up, in seconds; and
4. Prompt you for how often you want to optimize the database, in seconds.

Once you run through this script, you will be automatically backing up and optimizing your database according to whatever parameters you entered.

The script creates macOS `launchd` user agents, so these automatic backups and automatic database optimizations will continue on schedule, even after the system is rebooted. It's neither necessary nor desirable to run the script more than once per individual Resolve database.

To verify that everything is in working order, you can periodically check the log files located in `~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs`.

## How to use on CentOS
1. From an admin user account [neither `root` nor `postgres`], download the repository `davinci-resolve-postgresql-workflow-tools-master` to your `~/Downloads` folder.
2. In Terminal, from within your `~/Downloads/davinci-resolve-postgresql-workflow-tools-master` folder, make the script executable:
```
chmod 755 centos-automate-workflow.sh
```
3. Then, execute the script:
```
sudo ./centos-automate-workflow.sh
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

This script has been tested and works for PostgreSQL servers for either DaVinci Resolve Studio 14 or DaVinci Resolve Studio 15.

### macOS

* macOS Sierra 10.12.6 or later
* PostgreSQL 9.5.4 or later (as provided by the DaVinci Resolve Studio installer)
* pgAdmin III (as provided by the DaVinci Resolve Studio installer)

### CentOS

* CentOS 7.3 or later
* PostgreSQL 9.5.4 or later

## Background

Jathavan Sriram [wrote a great article back in 2014](http://jathavansriram.github.io/2014/04/20/davinci-resolve-how-to-backup-optimize/) about how to use pgAdmin III tools in `bash`, instead of having to use the `psql` shell.

The core insights from his 2014 article still apply, but several crucial changes need to be made for modern systems:
1. Apple [deprecated `cron` in favor of `launchd`](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html). 
2. Starting with DaVinci Resolve 12.5.4 on macOS, DaVinci Resolve has been using PostgreSQL 9.5.
3. The locations of `reindexdb` and `vacuumdb` in PostgreSQL 9.5.4 have changed from what they were in PostgreSQL 8.4.

## What this script does

On macOS, this script creates and installs `bash` scripts and `launchd` agents that, together, regularly and automatically backup and optimize the PostgreSQL databases that DaVinci Resolve Studio uses.

On CentOS Linux, this script creates and installs `bash` scripts, `systemd` units, and `systemd` timers that, together, regularly and automatically backup and optimize the PostgreSQL databases that DaVinci Resolve Studio uses. After a reboot, each `systemd` timer will be delayed by a random number of seconds, up to 180 seconds, so as to stagger the database utilities for optimal performance.

## Configuration

### macOS

The `.pgpass` file that the script creates assumes that the password for your PostgreSQL database is `DaVinci`, which is a convention from Blackmagic Design.

Make sure that you create the directory where your backups are going to go *before* running the script.

If you have any spaces in the full path of the directory where your backups are going, be sure to escape them with `\` when you run the script.

The `pg_hba.conf` file should be configured so that that these three lines use the `trust` method of authentication:
```
local    all    all    trust
host    all    all    127.0.0.1/32    trust
host    all    all    ::1/128    trust
```

N.B. Running the GUI app **DaVinci Resolve Project Server** somehow seems to change the authentication method back to `md5`. The scripts might continue to run, but because they'll be throwing errors, the logging won't be accurate. As a workaround, *don't open this GUI app,* or you'll have to go back to the `pg_hba.conf` file and manually change these lines back to `trust` again.

The script should be run from a regular user account with admin privileges. Do not run this script from either the `root` or `postgres` user accounts.

Because the script generates `launchd` user agents, the backups and optimizations will only occur while logged into the same account from which the script was run. Stay logged into the same account.

### CentOS

The `.pgpass` file that the script creates assumes that the password for your PostgreSQL database is `DaVinci`, which is a convention from Blackmagic Design.

Make sure that you create the directory where your backups are going to go *before* running the script.

Be sure to use the absolute path for the directory into which the backups will go.

The `pg_hba.conf` file should be configured so that the line for `local` uses `trust` authentication:
```
local    all    all        trust
```

The script should be run from a regular user account with admin privileges. Do not run this script from either the `root` or `postgres` user accounts.

## Restoring from backup

The `*.backup` files that this script generates can be restored into a new, totally blank PostgreSQL database in the event of a disk failure. These `*.backup` files are also handy even just to migrate entire databases from one PostgreSQL server to another.

In the event of a disk failure hosting the PostgreSQL database, the procedure to restore from these `*.backup` files to a new PostgreSQL server is as follows:
1. Set up a new, totally fresh PostgreSQL server
2. Create a fresh PostgreSQL database on the server, naming your database whatever you want it to be named
	1. If the version of Resolve you're using is the same version you were using when the `*.backup` file was created, you can just connect your client workstation and create a new blank database via the GUI;
	2. But if your `*.backup` file was created for some earlier version of Resolve, you'll need to hop into the `postgres` superuser account and create a _completely blank_ database:
		```
		sudo su - postgres
		createdb <newdatabasename>
		```
3. From a normal user acccount on the PostgreSQL server [not `root` or `postgres`], run the command:
	```
	pg_restore --host localhost --username postgres --single-transaction --clean --if-exists --dbname=<dbname> <full path to your backup file>
	```
	You might see some error messages when you run the `pg_restore` command, but they are harmless, [according to the PostgreSQL documentation](https://www.postgresql.org/docs/9.5/static/app-pgrestore.html).

4. If the version of Resolve you're using is the same version you were using when the `*.backup` file was created, you should be good to go, but if your `*.backup` file was created for some earlier version of Resolve, you should now be able to connect the the database via the GUI on the client and then upgrade it for your current version.

## Uninstall

### Uninstall on macOS

If you wish to stop automatically backing up and optimizing a particular database, you can run `macos-uninstall.sh`:

```
chmod 755 macos-uninstall.sh
sudo ./macos-uninstall.sh
```

The script will ask you what database you want to stop backing up and optimizing. The database you specify will then stop being backed up, stop being optimized, and all relevant files will be safely and cleanly removed from your system. The database itself will remain untouched.

### Uninstall on CentOS

If you wish to stop automatically backing up and optimizing a particular database, you can run `centos-uninstall.sh`:

```
chmod 755 centos-uninstall.sh
sudo ./centos-uninstall.sh
```

The script will ask you what database you want to stop backing up and optimizing. The database you specify will then stop being backed up, stop being optimized, and all relevant files will be safely and cleanly removed from your system. The database itself will remain untouched.
