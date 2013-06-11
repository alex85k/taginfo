#!/bin/sh
#------------------------------------------------------------------------------
#
#  Taginfo
#
#  update_all.sh DIR
#
#  Call this to update your Taginfo databases. All data will be store in the
#  directory DIR. Create an empty directory before starting for the first time!
#
#  In this directory you will find:
#  log      - directory with log files from running the update script
#  download - directory with bzipped databases for download
#  ...      - a directory for each source with database and possible some
#             temporary files
#
#------------------------------------------------------------------------------

EXEC_RUBY="$TAGINFO_RUBY"
if [ "x$EXEC_RUBY" = "x" ]; then
    EXEC_RUBY=ruby
fi
echo "Running with ruby set as '${EXEC_RUBY}'"


# These sources will be downloaded from http://taginfo.openstreetmap.org/download/
# Note that this will NOT work for the "db" source! Well, you can download it,
# but it will fail later, because the database is changed by the master.sql
# scripts.
SOURCES_DOWNLOAD=`$EXEC_RUBY ../bin/taginfo-config.rb sources.download`

# These sources will be created from the actual sources
SOURCES_CREATE=`$EXEC_RUBY ../bin/taginfo-config.rb sources.create`

#------------------------------------------------------------------------------

set -e

DATECMD='date +%Y-%m-%dT%H:%M:%S'

DIR=$1

if [ "x" = "x$DIR" ]; then
    echo "Usage: update_all.sh DIR"
    exit 1
fi

LOGFILE=`date +%Y%m%dT%H%M`

echo "`$DATECMD` Start update_all... $DIR/log"

mkdir -p $DIR/log
exec >$DIR/log/$LOGFILE.log 2>&1
mkdir -p $DIR/download

for source in $SOURCES_DOWNLOAD; do
    echo "====================================="
    echo "Downloading $source..."
    mkdir -p $DIR/$source
    curl --silent --output $DIR/download/taginfo-$source.db.bz2 http://taginfo.openstreetmap.org/download/taginfo-$source.db.bz2
    bzcat $DIR/download/taginfo-$source.db.bz2 >$DIR/$source/taginfo-$source.db
    echo "Done."
done

for source in $SOURCES_CREATE; do
    echo "====================================="
    echo "Running $source/update.sh..."
    mkdir -p $DIR/$source
    cd $source
    sh ./update.sh $DIR/$source
    cd ..
    echo "Done."
done

echo "====================================="
echo "Running master/update.sh..."
cd master
sh ./update.sh $DIR
cd ..

for source in $SOURCES_CREATE; do
    echo "====================================="
    echo "Running bzip2 on $source..."
    bzip2 -9 -c $DIR/$source/taginfo-$source.db >$DIR/download/taginfo-$source.db.bz2
    echo "Done."
done

echo "Running bzip2..."
bzip2 -9 -c $DIR/taginfo-master.db >$DIR/download/taginfo-master.db.bz2
bzip2 -9 -c $DIR/taginfo-search.db >$DIR/download/taginfo-search.db.bz2
echo "Done."

echo "====================================="
echo "`$DATECMD` Done update_all."


#-- THE END -------------------------------------------------------------------
