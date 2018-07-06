# DaVinci Resolve PostgreSQL Workflow Tools
## Effortlessly set up automatic backups and automatic optimizations of DaVinci Resolve 14 Studio's PostgreSQL databases

This is a `bash` script that is designed to be run on a **Mac** or **Linux** system that's running as a PostgreSQL server for DaVinci Resolve 14 Studio.

On macOS, the script will let you effortlessly create, load, and start `launchd` user agents that will automatically backup and automatically optimize your PostgreSQL databases. On CentOS Linux, the script creates and starts `systemd` units and timers.

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

### macOS

* **macOS Sierra 10.12.6** (16G1036 or 16G1212) or **macOS High Sierra 10.13.4** (17E199)

* PostgreSQL 9.5.4 or later (as provided by the DaVinci Resolve Studio installer)
* pgAdmin III (as provided by the DaVinci Resolve Studio installer)

### CentOS

* CentOS 7.4
* PostgreSQL 9.5.12
	
## Background

Jathavan Sriram wrote [a great article back in 2014](http://jathavansriram.github.io/2014/04/20/davinci-resolve-how-to-backup-optimize/) about how to use pgAdmin III tools in `bash`, instead of having to use the `psql` shell.

The core insights from his 2014 article still apply, but several crucial changes need to be made for modern systems:
1. Apple [deprecated `cron` in favor of `launchd`](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html). 
2. Starting with DaVinci Resolve 12.5.4 on macOS, DaVinci Resolve has been using PostgreSQL 9.5.
3. The locations of `reindexdb` and `vacuumdb` in PostgreSQL 9.5.4 have changed from what they were in PostgreSQL 8.4.

## What this script does

On macOS, this script creates and installs all the files necessary to have `launchd` regularly and automatically backup and optimize the PostgreSQL databases that DaVinci Resolve Studio uses. [`launchd`](https://en.wikipedia.org/wiki/Launchd) is a a unified service-management framework that starts, stops, and manages daemons, applications, processes, and scripts in macOS.

On CentOS Linux, this script creates and installs all the files necessary to have [`systemd`](https://en.wikipedia.org/wiki/Systemd) regularly and automatically backup and optimize the PostgreSQL databases that DaVinci Resolve Studio uses. After a reboot, each `systemd` timer will be delayed by a random number of seconds, up to 180 seconds, so as to stagger the database utilities for optimal performance.

## Configuration

### macOS

The `.pgpass` file that the script creates assumes that the password for your PostgreSQL database is `DaVinci` as per the recommendation from the Resolve 14 manual.

Make sure that you create the directory where your backups are going to go *before* running the script.

If you have any spaces in the full path of the directory where your backups are going, be sure to escape them with `\` when you run the script.

The `pg_hba.conf` file should be configured so that that these three lines use the `trust` method of authentication:
```
local    all    all    trust
host    all    all    127.0.0.1/32    trust
host    all    all    ::1/128    trust
```

The script is designed to be run from a regular user account with admin privileges. It's neither necessary nor desirable to run this script from within either the `root` or `postgres` user accounts.

Because the script generates `launchd` user agents, the backups and optimizations will only occur while logged into the same account from which the script was run. Stay logged into the same account.

### CentOS

The `.pgpass` file that the script creates assumes that the password for your PostgreSQL database is `DaVinci` as per the recommendation from the Resolve 14 manual.

Make sure that you create the directory where your backups are going to go *before* running the script.

Be sure to use the absolute path for the directory into which the backups will go.

The `pg_hba.conf` file should be configured so that the line for `local` uses`trust` authentication:
```
local    all    all        trust
```

The script is designed to be run from a regular user account with admin privileges. It's neither necessary nor desirable to run this script from within either the `root` or `postgres` user accounts.

## Restoring from backup

The `pg_dump` command used in this `bash` script is the equivalent of pressing the "Backup" button in the Resolve GUI's database manager window. The `*.backup` files that this script generates can be restored into a new, totally blank PostgreSQL database in the event of a disk failure. These `*.backup` files are also handy even just to migrate entire databases from one PostgreSQL server to another.

In the event of a disk failure hosting the PostgreSQL database, the procedure to restore from these `*.backup` files to a new PostgreSQL server is as follows:
1. Set up a new, totally fresh PostgreSQL server
2. From a connected client, create a fresh PostgreSQL database on the server, naming your database whatever you want it to be named
3. From a normal user acccount on the PostgreSQL server [not `root` or `postgres`], run the command:

```pg_restore --host localhost --username postgres --single-transaction --clean --if-exists --dbname=<dbname> <full path to your backup file>```

You might see some error messages when you run the `pg_restore` command, but they are harmless, [according to the PostgreSQL documentation](https://www.postgresql.org/docs/9.5/static/app-pgrestore.html).

You need to create the database ahead of time, because the `pg_dump` command will fill the data from the backup file into the fresh, blank database.

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
