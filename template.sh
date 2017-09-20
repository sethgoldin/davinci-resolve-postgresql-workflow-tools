#!/bin/bash
cd /Library/PostgreSQL/9.5/pgAdmin3.app/Contents/SharedSupport

# In this shell script:
# Leave `--host localhost` intact
# Leave `--username postgres` intact, assuming that the service user you set up for your PostgreSQL is named `postgres`
# Put in the name of the individual PostgreSQL database from Resolve's GUI
# `--blobs` stays the same
# After `--file`, specify the name of the output files as the individual PostgreSQL database from Resolve's GUI. The backup files will be placed in whatever directory you specify with a full path name, and the built-in date function will append `_YY_MM_DD_HH_MM` into the filename.
# The `--no-password` flag is necessary for this script to be automated, and requires a `.pgpass` file in ~ with the line: `localhost:5432:*:postgres:DaVinci`, presuming that you did set up your password as `DaVinci`, as per the Resolve manual.

./pg_dump --host localhost --username postgres yourdbname --blobs --file /full/directory/path/to/wherever/you/want/your/backups/to/go/yourdbname_`date "+%y_%m_%d_%H_%M"`.backup --format=custom --verbose --no-password
