#!/bin/bash

# Here's where the user is going to enter the Resolve database name, as it appears in the GUI:
read -p "Enter the name of your DaVinci Resolve PostgreSQL database: " dbname

# Let's allow the user to confirm that what they've typed in is correct:
echo "You entered: $dbname"
read -p "Is that correct? Enter y or n: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1 

# Now "$dbname" will work as a variable in subsequent paths.

# Let's prompt the user for the "backup directory," which is where the backups from pg_dump will go:
read -e -p "Into which directory should the database backups go? You can drag-and-drop a folder from Finder into Terminal. " backupDirectory

# Let's also allow the user to confirm that what they've typed in for the backup directory is correct:
echo "You entered: $backupDirectory"
read -p "Is that correct? Enter y or n: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Now $backupDirectory will be the folder loaded into the shell script where the backups are going to go

# Let's allow the user to specify how often to backup the database.
# Let's also provide a handy list of suggested time intervals.
echo "Handy list of suggested time intervals:"
echo "     3600 seconds = 01 hour"
echo "    10800 seconds = 03 hours"
echo "    21600 seconds = 06 hours"
echo "    43200 seconds = 12 hours"
echo "    86400 seconds = 24 hours"
read -p "How often would you like to backup the database, in seconds? " backupFrequency

# Let's have the user confirm that they entered the right backup frequency:
read -p "You entered that you want to backup your database every $backupFrequency seconds. Is that correct? Enter y or n: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Let's allow the user to specify how often to optimize the database.
# Let's also provide a handy list of suggested time intervals.
echo "Handy list of suggested time intervals:"
echo "     3600 seconds = 01 hour"
echo "    10800 seconds = 03 hours"
echo "    21600 seconds = 06 hours"
echo "    43200 seconds = 12 hours"
echo "    86400 seconds = 24 hours"
read -p "How often would you like to optimize the database, in seconds? " optimizeFrequency

# Let's have the user confirm that they entered the correct optimizing frequency:
read -p "You entered that you want to optimize your database every $optimizeFrequency seconds. Is that correct? Enter y or n: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Let's check if a /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools folder exists, and if it doesn't, let's create one:
mkdir -p /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools

# Let's also check to see if there are separate directories for "backup" and "optimize" scripts, and if they don't exist, let's create them.
# We're making separate directories for the different kinds of scripts just to keep everything clean and organized.

mkdir -p /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup
mkdir -p /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize

# Let's also make a folder for log files
mkdir -p /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs

# We also need to make sure that these folders in which the scripts are living have the proper permissions to execute:
chmod -R 755 /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup
chmod -R 755 /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize
chmod -R 777 /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs

# With all these folders created, with the correct permissions, we can go ahead and create the two different shell scripts that will be executed by the launchd XML files.

# First, let's create the "backup" shell script:
touch /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh

# Now, let's fill it in:
cat << EOF > /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh
#!/bin/bash
# Check to make sure that the log file exists
touch /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log && \\

# Make sure that the file can be written to
chmod 777 /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log && \\ 

# Let's perform the backup and log to the monthly log file if the backup is successful.
/Library/PostgreSQL/13/bin/pg_dump --host localhost --username postgres $dbname --blobs --file "$backupDirectory"/${dbname}_\$(date "+%Y_%m_%d_%H_%M").backup --format=custom --verbose --no-password && \\

# Log to the log file
echo "${dbname} was backed up at \$(date "+%Y_%m_%d_%H_%M") into "$backupDirectory"." >> /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log
EOF

# To make sure that this backup script will run from the root account without a password, we need to add a .pgpass file to /var/root if it doesn't already exist:
if [ ! -f /var/root/.pgpass ]; then
	touch /var/root.pgpass
	echo "localhost:5432:*:postgres:DaVinci" > /var/root/.pgpass
# 	We also need to make sure that that .pgpass file has the correct permissions of 600:
	chmod 600 /var/root/.pgpass
fi

# Let's move onto the "optimize" script:
touch /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh
cat << EOF > /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh
#!/bin/bash
# Let's optimize the database and log to the monthly log file if the optimization is successful.

# Check to make sure that the log file exists
touch /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log && \\

# Make sure that the file can be written to
chmod 777 /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log && \\ 

# Perform the two "optimize" functions and log to the log file
/Library/PostgreSQL/13/bin/reindexdb --host localhost --username postgres $dbname --no-password --echo && \\
/Library/PostgreSQL/13/bin/vacuumdb --analyze --host localhost --username postgres $dbname --verbose --no-password && \\
echo "${dbname} was optimized at \$(date "+%Y_%m_%d_%H_%M")." >> /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log
EOF

# Now each individual shell script needs to have their permissions set properly for launchd to read and execute the scripts, so let's use 755:
chmod 755 /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh
chmod 755 /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh

# With both shell scripts created with the proper permissions, we can create, load, and start the two different launchd user daemons.

# Let's create the "backup" daemon first.
touch /Library/LaunchDaemons/backup-"$dbname".plist
cat << EOF > /Library/LaunchDaemons/backup-"$dbname".plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.resolve.backup.$dbname</string>
    <key>Program</key>
        <string>/Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-$dbname.sh</string>
    <key>StartInterval</key>
    <integer>$backupFrequency</integer>
</dict>
</plist>
EOF

# Now let's create the "optimize" daemon.
touch /Library/LaunchDaemons/optimize-"$dbname".plist
cat << EOF > /Library/LaunchDaemons/optimize-"$dbname".plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.resolve.optimize.$dbname</string>
    <key>Program</key>
        <string>/Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-$dbname.sh</string>
    <key>StartInterval</key>
    <integer>$optimizeFrequency</integer>
</dict>
</plist>
EOF

# These plist files inside /Library/LaunchDaemons each need permissions of 755.
chmod 755 /Library/LaunchDaemons/backup-"$dbname".plist
chmod 755 /Library/LaunchDaemons/optimize-"$dbname".plist

# Now, the "backup" and "optimize" scripts and daemons are in place.
# All we need to do is load these daemons into launchd and start them with launchctl.

# First, let's load and start the backup daemon.
launchctl load /Library/LaunchDaemons/backup-${dbname}.plist
launchctl start com.resolve.backup.${dbname}

# Lastly, let's load and start the optimize daemon.
launchctl load /Library/LaunchDaemons/optimize-${dbname}.plist
launchctl start com.resolve.optimize.${dbname}

echo "Congratulations, $dbname will be backed up every $backupFrequency seconds and optimized every $optimizeFrequency seconds."
echo "You can check to make sure that everything is being backed up and optimized properly by periodically looking at the log files in: /Users/Shared/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs"
echo "Have a great day!"
