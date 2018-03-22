#!/bin/bash

# Here's where the user is going to enter the Resolve database name, as it appears in the GUI:
read -p "Enter the name of your DaVinci Resolve PostgreSQL database: " dbname

# Let's allow the user to confirm that what they've typed in is correct:
read -p "Did you enter the name of the database correctly? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1 

# Now "$dbname" will work as a variable in subsequent paths

# Let's prompt the user for the "backup directory," which is where the backups from pg_dump will go:
read -p "Into which directory should the database backups go? " backupDirectory

# Let's also allow the user to confirm that what they've typed in for the backup directory is correct:
read -p "Did you enter the path of the backup directory correctly? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# Now $backupDirectory will be the folder loaded into the shell script where the backups are going to go

# Let's check if a ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools folder exists, and if it doesn't, let's create one:
mkdir -p ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools

# Let's also check to see if there are separate directories for "backup" and "optimize" scripts, and if they don't exist, let's create them.
# We're making separate directories for the different kinds of scripts just to keep everything straight.

mkdir -p ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup
mkdir -p ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize

# Let's also make a folder for log files
mkdir -p ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs

# We also need to make sure that these folders in which the scripts are living have the proper permissions to execute:
chmod -R 755 ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup
chmod -R 755 ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize
chmod -R 755 ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs

# With those folders created with the correct permissions, let's go ahead and create the two different shell scripts that will be referenced by the launchd XML plist files.

# First, let's create the "backup" shell script:
touch ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh

# Now, let's fill it in:
cat << EOF > ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh
#!/bin/bash
# Let's check to make sure that the monthly log file exists, and create it if it doesn't
if [ ! -f ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log ]; then
	touch ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log
fi
# Let's do the backup and log to the monthly backup if the backup is successful.
/Library/PostgreSQL/9.5/pgAdmin3.app/Contents/SharedSupport/pg_dump --host localhost --username postgres $dbname --blobs --file $backupDirectory/${dbname}_\$(date "+%Y_%m_%d_%H_%M").backup --format=custom --verbose --no-password && \
echo "${dbname} was backed up at \$(date "+%Y_%m_%d_%H_%M")." >> ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log
EOF

# To make sure that this backup script will run without a password, we need to add a .pgpass file to ~ if it doesn't already exist:
if [ ! -f ~/.pgpass ]; then
	touch ~/.pgpass
	echo "localhost:5432:*:postgres:DaVinci" > ~/.pgpass
# 	We also need to make sure that that .pgpass file has the correct permissions of 600:
	chmod 600 ~/.pgpass
fi

# Let's move onto the "optimize" script:
touch ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh
cat << EOF > ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh
#!/bin/bash
# Let's check to make sure that the monthly log file exists, and create it if it doesn't
if [ ! -f ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log ]; then
	touch ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log
fi
# Let's optimize the database and log to the monthly backup if the backup is successful.
/Library/PostgreSQL/9.5/pgAdmin3.app/Contents/SharedSupport/reindexdb --host localhost --username postgres $dbname --no-password --echo && \
/Library/PostgreSQL/9.5/pgAdmin3.app/Contents/SharedSupport/vacuumdb --analyze --host localhost --username postgres $dbname --verbose --no-password && \
echo "${dbname} was optimized at \$(date "+%Y_%m_%d_%H_%M")." >> ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-\$(date "+%Y_%m").log
EOF

# Each individual shell script needs to have the permissions set properly for launchd to read and execute, so let's use 755:
chmod 755 ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh
chmod 755 ~/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh

# With both shell scripts created with the proper permissions, we can create, load, and start the two different launchd user agents.

# Let's create the "backup" agent first.
touch ~/Library/LaunchAgents/backup-"$dbname".plist
cat << EOF > ~/Library/LaunchAgents/backup-"$dbname".plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.resolve.backup.$dbname</string>
    <key>ProgramArguments</key>
    <array>
        <string>Users/$USER/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-$dbname.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>60</integer>
</dict>
</plist>
EOF

# Now let's create the "optimize" agent.
touch ~/Library/LaunchAgents/optimize-"$dbname".plist
cat << EOF > ~/Library/LaunchAgents/optimize-"$dbname".plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.resolve.optimize.$dbname</string>
    <key>ProgramArguments</key>
    <array>
        <string>Users/$USER/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-$dbname.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>180</integer>
</dict>
</plist>
EOF

# These plist files inside ~/Library/LaunchAgents each need permissions of 755.
chmod 755 ~/Library/LaunchAgents/backup-"$dbname".plist
chmod 755 ~/Library/LaunchAgents/optimize-"$dbname".plist

# Now, the "backup" and "optimize" scripts and agents are in place.
# All we need to do is load these agents into launchd and start them with launchctl.

# First, let's load and start the backup agent.
launchctl load ~/Library/LaunchAgents/backup-${dbname}.plist
launchctl start com.backup.resolve.${dbname}

# Lastly, let's load and start the optimize agent.
launchctl load ~/Library/LaunchAgents/optimize-${dbname}.plist
launchctl start com.resolve.optimize.${dbname}
