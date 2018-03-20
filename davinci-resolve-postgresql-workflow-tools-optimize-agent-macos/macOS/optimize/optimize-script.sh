#!/bin/bash

# These functions aren't installed to the OS path by default, so we must change our working directory to the following folder:
cd /Library/PostgreSQL/9.5/pgAdmin3.app/Contents/SharedSupport

# In this shell script:
# There are two different commands that will execute, `reindexdb` followed by `vacuumdb`.
# Running these two commands in this order is the equivalent of pressing the "Optimize" button in DaVinci Resolve's GUI.

./reindexdb --host localhost --username postgres yourdbname --no-password --echo

./vacuumdb --analyze --host localhost --username postgres yourdbname --verbose --no-password
