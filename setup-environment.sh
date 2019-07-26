fail()
{
    echo "Error:" $* 1>&2
    exit 1
}

warn()
{
    echo "Warning:" $* 1>&2
}

trim()
{
    local trimmed="$1"

    # Strip leading space.
    trimmed="${trimmed## }"
    # Strip trailing space.
    trimmed="${trimmed%% }"

    echo "$trimmed"
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

DEFAULT_WORKSHOP_IMAGE=$WORKSHOP_IMAGE

echo "### Reading the workshop configuation."

if [ ! -f $WORKSHOP_DIR/settings.sh ]; then
    warn "Cannot find any workshop settings."
else
    . $WORKSHOP_DIR/settings.sh
fi

if [ x"$WORKSHOP_IMAGE" == x"" ]; then
    WORKSHOP_IMAGE=$DEFAULT_WORKSHOP_IMAGE
fi

if [ -f "$WORKSHOP_DIR/jupyterhub_config.py" ]; then
    JUPYTERHUB_CONFIG=`cat $WORKSHOP_DIR/jupyterhub_config.py`
fi

if [ -f "$WORKSHOP_DIR/terminal.sh" ]; then
    TERMINAL_ENVVARS=`cat $WORKSHOP_DIR/terminal.sh`
fi

if [ -f "$WORKSHOP_DIR/workshop.sh" ]; then
    WORKSHOP_ENVVARS=`cat $WORKSHOP_DIR/workshop.sh`
fi

if [ -f "$WORKSHOP_DIR/gateway.sh" ]; then
    GATEWAY_ENVVARS=`cat $WORKSHOP_DIR/gateway.sh`
fi

echo "### Setting the workshop application."

WORKSHOP_NAME=${WORKSHOP_NAME:-$REPOSITORY_NAME}

SPAWNER_APPLICATION=${SPAWNER_APPLICATION:-$WORKSHOP_NAME}
DASHBOARD_APPLICATION=${DASHBOARD_APPLICATION:-$WORKSHOP_NAME}

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
