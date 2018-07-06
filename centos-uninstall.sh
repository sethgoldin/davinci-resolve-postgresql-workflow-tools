#!/bin/bash

# prompt user for the name of the database
read -p "What is the name of the database for which you'd like to stop automatically backing up and optimizing? " dbname

# confirm that the name of the database is correct
echo "You entered: $dbname"
read -p "Is that correct? Enter y or no: " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

# stop backup systemd timer
systemctl stop backup-"$dbname".timer

# stop backup systemd service
systemctl stop backup-"$dbname".service

# stop optimize systemd timer
systemctl stop optimize-"$dbname".timer

# stop optimize systemd service
systemctl stop optimize-"$dbname."service

# disable backup systemd timer
systemctl disable backup-"$dbname".timer

# disable backup systemd service
systemctl disable backup-"$dbname".service

# disable optimize systemd timer
systemctl disable optimize-"$dbname".timer

# disable optimize systemd service
systemctl disable optimize-"$dbname".service

# remove backup systemd timer file
rm /etc/systemd/system/backup-"$dbname".timer

# remove backup systemd service file
rm /etc/systemd/system/backup-"$dbname".service

# remove optimize systemd timer file
rm /etc/systemd/system/optimize-"$dbname".timer

# remove optimize systemd service file
rm /etc/systemd/system/optimize-"$dbname".service

# remove backup shell script
rm /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/backup/backup-"$dbname".sh

# remove optimize shell script
rm /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/optimize/optimize-"$dbname".sh

# log to monthly log file that $dbname has been uninstalled. $dbname will no longer be backed up or optimized
echo "Backup and optimize tools for $dbname were uninstalled at $(date "+%Y_%m_%d_%H_%M"). $dbname will no longer be backed up or optimized." >> /usr/local/DaVinci-Resolve-PostgreSQL-Workflow-Tools/logs/logs-$(date "+%Y_%m").log

# send message to user in command-line program to inform them of the same
echo "Backup and optimize tools for ${dbname} were uninstalled. Have a great day!"
