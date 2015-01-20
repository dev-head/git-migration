#!/bin/bash 


############
#
# ./gitMig.sh -f http://host_A:7990/path/to/repo.git -t http://host_B:7990/path/to/repo.git
#
###############

read -r -d '' MESSAGE <<- EOM

__________________________________________
### GIT MIGRATION ### 

Used to migrate from one git repo to another. 
This is a clone, so all remote branches and commit history is copied over to the new repo.

Usage: $0 [-f <from url>] [-t <to url>]
OPTIONS: (*required)
   -f * Git repo to copy FROM
   -t * Git repot to copy TO
   -h * Show this message
   -s Silent / no output except errors.

@AUTHOR: devhead
@VERSION: 0.0.1
@DATE: 2015/01/08
__________________________________________
__________________________________________

EOM

usage() { echo "$MESSAGE" 1>&2; exit 1; }

#
# Handles the cleanup processing
#
cleanup ()
{
    if [ -d "$WORKING_DIR/from_repo" ]; then
        log "Removing::[$WORKING_DIR/from_repo]"
        rm -Rf $WORKING_DIR/from_repo
    fi
}

#
# Used to output a message to stdout if the verbose flag is set to true
#
log() {
    if [ "$s" != 'true' ]; then
        while [ "$1" != "" ]; do
            echo "[==>>][MESSAGE]::${1}"
            shift;
        done;
    fi
}

#
# Used to log a warning message to stdout, verbosity is ignored.
#
error() {
    while [ "$1" != "" ]; do
        echo "[==>>][ERROR]::${1}"
        shift;
    done;
}

while getopts f:t:s: OPTION; do

    case "$OPTION" in
        f) f=$OPTARG ;;
        t) t=$OPTARG ;;
        s) s=$OPTARG ;;
        [?]) usage ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$f" ] || [ -z "$t" ] ; then
    usage
fi

WORKING_DIR="/tmp"

log "Staring migration from: [$f] to: [$t]"

# Ensure we don't have some existing working directory.
cleanup

cd "$WORKING_DIR"
git clone --bare "$f" from_repo || (error "[FATAL]::could not clone::[$f]" && cleanup && exit)

if [ -d "$WORKING_DIR/from_repo" ]; then
    log "Clone worked, moving into::[$WORKING_DIR/from_repo]"
    cd "$WORKING_DIR/from_repo"

    git remote add to_repo "$t"  || (error "[FATAL]::could add remote" && cleanup && exit)
    log "Remote Added"

    git push --mirror to_repo  || (error "[FATAL]::could not push to remote" && cleanup && exit)
    log "Pushed to remote"
    
    git remote rm to_repo || (error "[FATAL]::could not remove remote" && cleanup && exit)
    log "Removed local remote"
    cleanup
fi

log "To use the new remote: cd into your existing project and execute: "
log "cd /path/to/local/clone"
log "git remote set-url origin $t"
log "git fetch"
log "Completed migration from: [$f] to: [$t]"
