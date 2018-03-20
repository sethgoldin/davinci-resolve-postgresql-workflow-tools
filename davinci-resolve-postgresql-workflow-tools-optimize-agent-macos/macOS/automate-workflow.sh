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

# Let's check if a ~/DaVinci\ Resolve\ PostgreSQL\ Workflow\ Tools/ folder exists, and if it doesn't, let's create one:
mkdir -p ~/DaVinci\ Resolve\ PostgreSQL\ Workflow\ Tools

# Let's also check to see if there are separate directories for "backup" and "optimize" scripts, and if they don't exist, let's create them.
# We're making separate directories for the different kinds of scripts just to keep everything straight.

cd ~/DaVinci\ Resolve\ PostgreSQL\ Workflow\ Tools
mkdir -p backup
mkdir -p optimize

# With those folders created, let's go ahead and create the two different shell scripts that will be referenced by the launchd XML plist files.

# First, let's create the "backup" shell script:

cd backup
touch backup-"$dbname".sh

# Now, let's fill it in:
echo "#!/bin/bash" >> backup-"$dbname".sh
echo "cd /Library/PostgreSQL/9.5/pgAdmin3.app/Contents/SharedSupport" >> backup-"$dbname".sh
echo "./pg_dump --host localhost --username postgres $dbname --blobs --file $backupDirectory/$dbname_\`date \"+%Y_%m_%d_%H_%M\"\`.backup --format=custom --verbose --no-password" >> backup-"$dbname".sh

# To make sure that this backup script will run without a password, we need to add a .pgpass file to ~ if it doesn't already exist:
cd ~
if [ ! -f ~/.pgpass ]; then
	touch ~/.pgpass
	echo "localhost:5432:*:postgres:DaVinci" > ~/.pgpass
fi

# Let's move onto the "optimize" script:
cd ~/DaVinci\ Resolve\ PostgreSQL\ Workflow\ Tools/optimize
touch optimize-"$dbname".sh
echo "#!/bin/bash" >> optimize-"$dbname".sh
echo "cd /Library/PostgreSQL/9.5/pgAdmin3.app/Contents/SharedSupport" >> optimize-"$dbname".sh
echo "./reindexdb --host localhost --username postgres $dbname --no-password --echo" >> optimize-"$dbname".sh
echo "./vacuumdb --analyze --host localhost --username postgres $dbname --verbose --no-password" >> optimize-"$dbname".sh

# With both shell scripts created, we can create, load, and start the two different launchd user agents.

# Let's create the "backup" agent first.
cd ~/Library/LaunchAgents
touch backup-"$dbname".plist

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> backup-"$dbname".plist
echo "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" >> backup-"$dbname".plist
echo "<plist version=\"1.0\">" >> backup-"$dbname".plist
echo "<dict>" >> backup-"$dbname".plist
echo "    <key>Label</key>" >> backup-"$dbname".plist
echo "    <string>com.resolve.backup.$dbname</string>" >> backup-"$dbname".plist
echo "    <key>ProgramArguments</key>" >> backup-"$dbname".plist
echo "    <array>" >> backup-"$dbname".plist
echo "        <string>bash</string>" >> backup-"$dbname".plist
echo "        <string>-c</string>" >> backup-"$dbname".plist
echo "        <string>~/DaVinci\ Resolve\ PostgreSQL\ Workflow\ Tools/backup/backup-$dbname.sh</string>" >> backup-"$dbname".plist
echo "    </array>" >> backup-"$dbname".plist
echo "    <key>StartInterval</key>" >> backup-"$dbname".plist
echo "    <integer>10800</integer>" >> backup-"$dbname".plist
echo "</dict>" >> backup-"$dbname".plist
echo "</plist>" >> backup-"$dbname".plist

# Now let's create the "optimize" agent.
cd ~/Library/LaunchAgents
touch optimize-"$dbname".plist
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> optimize-"$dbname".plist
echo "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" >> optimize-"$dbname".plist
echo "<plist version=\"1.0\">" >> optimize-"$dbname".plist
echo "<dict>" >> optimize-"$dbname".plist
echo "    <key>Label</key>" >> optimize-"$dbname".plist
echo "    <string>com.resolve.optimize.$dbname</string>" >> optimize-"$dbname".plist
echo "    <key>ProgramArguments</key>" >> optimize-"$dbname".plist
echo "    <array>" >> optimize-"$dbname".plist
echo "        <string>bash</string>" >> optimize-"$dbname".plist
echo "        <string>-c</string>" >> optimize-"$dbname".plist
echo "        <string>~/DaVinci\ Resolve\ PostgreSQL\ Workflow\ Tools/optimize/optimize-$dbname.sh</string>" >> optimize-"$dbname".plist
echo "    </array>" >> optimize-"$dbname".plist
echo "    <key>StartInterval</key>" >> optimize-"$dbname".plist
echo "    <integer>86400</integer>" >> optimize-"$dbname".plist
echo "</dict>" >> optimize-"$dbname".plist
echo "</plist>" >> optimize-"$dbname".plist


