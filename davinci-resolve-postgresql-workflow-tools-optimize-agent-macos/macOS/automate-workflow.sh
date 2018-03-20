#!/bin/bash

# Here's where the user is going to enter the Resolve database name, as it appears in the GUI:
read -p "Enter the name of your DaVinci Resolve PostgreSQL database: " dbname

# Let's allow the user to confirm that what they've typed in is correct:
read -p "Did you type the name of the database correctly? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1 

# Now "$dbname" will work as a variable in subsequent paths

# Let's check if a ~/DaVinci\ Resolve\ PostgreSQL\ Workflow\ Tools/ folder exists, and if it doesn't, let's create one:
mkdir -p ~/DaVinci\ Resolve\ PostgreSQL\ Workflow\ Tools

# Let's also check to see if there are separate directories for where "backup" and "optimize" scripts, and if they don't exist, let's create them.
# We're making separate directories just to keep everything straight.

cd ~/DaVinci Resolve\ PostgreSQL\ Workflow\ Tools
mkdir -p backup
mkdir -p optimize

# With those folders created, let's go ahead and create the two different shell scripts that will be referenced by the launchd XML plist files.

# First, let's create the "backup" shell script:

cd backup
touch backup-"$dbname".sh

# Now, let's fill it in:
echo "#!/bin/bash" >> backup-"$dbname".sh
echo "cd /Library/PostgreSQL/9.5/pgAdmin3.app/Contents/SharedSupport" >> backup-"$dbname".sh
echo './pg_dump --host localhost --username postgres' + "$dbname" + "--blobs --file $backupPath/$dbname_`date "+%y_%m_%d_%H_%M"`.backup --format=custom --verbose --no-password" >> backup-"$dbname".sh
