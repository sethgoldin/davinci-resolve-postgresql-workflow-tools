#!/bin/bash

# Here's where the user is going to enter the Resolve database name, as it appears in the GUI:
read -p "Enter the name of your DaVinci Resolve PostgreSQL database: " dbname

# Let's allow the user to confirm that what they've typed in is correct:
echo "You entered: $dbname"
read -p "Is that correct? Enter y or n: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1 

# Now "$dbname" will work as a variable in subsequent paths.

# Let's prompt the user for the "backup directory," which is where the backups from pg_dump will go:
read -p "Into which directory should the database backups go? Use absolute paths! " backupDirectory

# Let's also allow the user to confirm that what they've typed in for the backup directory is correct:
echo "You entered: $backupDirectory"
read -p "Is that correct? Enter y or n: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Now $backupDirectory will be the folder loaded into the shell script where the backups are going to go.

# Let's allow the user to specify how often to backup the database.
# Let's also provide a link for more information on systemd time syntax.
echo "See https://www.freedesktop.org/software/systemd/man/systemd.time.html for time syntax."
echo "Suggestion: 1h"
read -p "How often would you like to backup the database? " backupFrequency

# Let's have the user confirm that they entered the right backup frequency:
read -p "You entered that you want to backup your database every "$backupFrequency". Is that correct? Enter y or n: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Let's allow the user to specify how often to optimize the database.
# Let's also provide another link to more information on systemd time syntax.
echo "See https://www.freedesktop.org/software/systemd/man/systemd.time.html for time syntax."
echo "Suggestion: 1d"
read -p "How often would you like to optimize the database? " optimizeFrequency

# Let's have the user confirm that they entered the correct optimizing frequency:
read -p "You entered that you want to optimize your database every "$optimizeFrequency". Is that correct? Enter y or n: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Let's check if a /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools folder exists, and if it doesn't, let's create one:
mkdir -p /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools

# Let's also check to see if there are separate directories for "backup" and "optimize" scripts, and if they don't exist, let's create them.
# We're making separate directories for the different kinds of scripts just to keep everything clean and organized.

mkdir -p /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup
mkdir -p /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize

# Let's also make a folder for log files
mkdir -p /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs

# Let's make sure a log file exists if it doesn't already
touch /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-$(date +%Y_%m).log

# We also need to make sure that these folders in which the scripts are living have the proper permissions to execute:
chmod -R 755 /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup
chmod -R 755 /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize
chmod -R 755 /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs

# With all these folders created, with the correct permissions, we can go ahead and create the two different shell scripts that will be executed by the launchd XML files.

# First, let's create the "backup" shell script:
touch /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh

# Now, let's fill it in:
cat << EOF > /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh
#!/bin/bash
# Let's perform the backup and log to the monthly log file if the backup is successful.
/usr/pgsql-9.5/bin/pg_dump --host localhost --username postgres $dbname --blobs --file $backupDirectory/${dbname}_\$(date "+%Y_%m_%d_%H_%M").backup --format=custom --verbose --no-password && \\
echo "${dbname} was backed up at \$(date "+%Y_%m_%d_%H_%M") into '$backupDirectory'." >> /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log
EOF

# To make sure that this backup script will run without a password, we need to add a .pgpass file to ~ if it doesn't already exist:
if [ ! -f /home/$USER/.pgpass ]; then
	touch /home/$USER/.pgpass
	echo "localhost:5432:*:postgres:DaVinci" > /home/$USER/.pgpass
# 	We also need to make sure that that .pgpass file has the correct permissions of 0600:
	chmod 0600 /home/$USER/.pgpass
fi

# Let's move onto the "optimize" script:
touch /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh
cat << EOF > /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh
#!/bin/bash
# Let's optimize the database and log to the monthly log file if the optimization is successful.
/usr/pgsql-9.5/bin/reindexdb --host localhost --username postgres $dbname --no-password --echo && \\
/usr/pgsql-9.5/bin/vacuumdb --analyze --host localhost --username postgres $dbname --verbose --no-password && \\
echo "${dbname} was optimized at \$(date "+%Y_%m_%d_%H_%M")." >> /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log
EOF

# Now each individual shell script needs to have their permissions set properly for systemd to read and execute the scripts, so let's use 755:
chmod 755 /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh
chmod 755 /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh

# With both shell scripts created with the proper permissions, we can create, load, and start the systemd services and timers.

# Let's create the "backup" service and timer first.
touch /etc/systemd/system/backup-"$dbname".service
cat << EOF > /etc/systemd/system/backup-"$dbname".service
[Unit]
Description=Backup of $dbname DaVinci Resolve PostgreSQL database

[Service]
Type=oneshot
ExecStart=/usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-$dbname.sh
EOF

touch /etc/systemd/system/backup-"$dbname".timer
cat << EOF > /etc/systemd/system/backup-"$dbname".timer
[Unit]
Description=Backup of $dbname DaVinci Resolve PostgreSQL database

[Timer]
OnUnitActiveSec=$backupFrequency
OnBootSec=60s
AccuracySec=1s
RandomizedDelaySec=180s

[Install]
WantedBy=timers.target
EOF

# Now let's create the "optimize" service and timer.
touch /etc/systemd/system/optimize-"$dbname".service
cat << EOF > /etc/systemd/system/optimize-"$dbname".service
[Unit]
Description=Optimize $dbname DaVinci Resolve PostgreSQL database

[Service]
Type=oneshot
ExecStart=/usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-$dbname.sh
EOF

touch /etc/systemd/system/optimize-"$dbname".timer
cat << EOF > /etc/systemd/system/optimize-"$dbname".timer
[Unit]
Description=Optimize $dbname DaVinci Resolve PostgreSQL database

[Timer]
OnUnitActiveSec=$optimizeFrequency
OnBootSec=60s
AccuracySec=1s
RandomizedDelaySec=180s

[Install]
WantedBy=timers.target
EOF

# These systemd files each need permissions of 755.
chmod 755 /etc/systemd/system/backup-"$dbname".service
chmod 755 /etc/systemd/system/backup-"$dbname".timer
chmod 755 /etc/systemd/system/optimize-"$dbname".service
chmod 755 /etc/systemd/system/optimize-"$dbname".timer

# Now, the "backup" and "optimize" scripts and systemd files are in place.
# All we need to do is unmask the units, reload systemd, and start the timers.

systemctl unmask backup-"$dbname".timer
systemctl unmask optimize-"$dbname".timer
systemctl daemon-reload
systemctl start backup-"$dbname".timer
systemctl start optimize-"$dbname".timer

echo "Congratulations, $dbname will be backed up every "$backupFrequency" and optimized every "$optimizeFrequency"."
echo "You can check to make sure that everything is being backed up and optimized properly by periodically looking at the log files in: /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs"
echo "Have a great day!"
