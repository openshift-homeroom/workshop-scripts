fail()
{
    echo "Error:" $* 1>&2
    exit 1
}

warn()
{
    echo "Warning:" $* 1>&2
}

SCRIPTS_DIR=`dirname $0`
WORKSHOP_DIR=`dirname $SCRIPTS_DIR`
SOURCE_DIR=`dirname $WORKSHOP_DIR`

REPOSITORY_NAME=`basename $SOURCE_DIR`

if [ `basename $WORKSHOP_DIR` != ".workshop" ]; then
    fail "Failed to find workshop directory."
    exit 1
fi

echo "### Reading the default configuation."

. $SCRIPTS_DIR/default-settings.sh

echo "### Reading the workshop configuation."

if [ ! -f $WORKSHOP_DIR/settings.sh ]; then
    warn "Cannot find any workshop settings."
else
    . $WORKSHOP_DIR/settings.sh
fi

echo "### Setting the workshop application."

WORKSHOP_NAME=${WORKSHOP_NAME:-$REPOSITORY_NAME}

SPAWNER_APPLICATION=${SPAWNER_APPLICATION:-$WORKSHOP_NAME}
DASHBOARD_APPLICATION=${DASHBOARD_APPLICATION:-$WORKSHOP_NAME}

WORKSHOP_IMAGE=${WORKSHOP_IMAGE:-$DASHBOARD_IMAGE}

VERSION_INFO=`oc get --raw /version 2>/dev/null`

if [ x"$CONSOLE_VERSION" == x"" ]; then
    if [ `echo $VERSION_INFO | grep '"minor": "13+"'` ]; then
        CONSOLE_VERSION=4.1
    fi
fi

CONSOLE_VERSION=${CONSOLE_VERSION:-4.1}

PROJECT_NAME=`oc project --short 2>/dev/null`

if [ x"$PROJECT_NAME" == x"" ]; then
    fail "Cannot determine name of project."
    exit 1
fi
