#!/bin/bash

fail()
{
    echo "Error:" $* 1>&2
    exit 1
}

warn()
{
    echo "Warning:" $* 1>&2
}

echo "### Reading the workshop configuation."

SCRIPTS_DIR=`dirname $0`
WORKSHOP_DIR=`dirname $SCRIPTS_DIR`
SOURCE_DIR=`dirname $WORKSHOP_DIR`

REPOSITORY_NAME=`basename $SOURCE_DIR`

if [ `basename $WORKSHOP_DIR` != ".workshop" ]; then
    fail "Failed to find workshop directory."
    exit 1
fi

if [ ! -f $WORKSHOP_DIR/settings.sh ]; then
    warn "Cannot find any workshop settings."
else
    . $WORKSHOP_DIR/settings.sh
fi

echo "### Setting defaults for spawner application."

WORKSHOP_NAME=${WORKSHOP_NAME:-$REPOSITORY_NAME}

SPAWNER_APPLICATION=${SPAWNER_APPLICATION:-$WORKSHOP_NAME}
DASHBOARD_APPLICATION=${DASHBOARD_APPLICATION:-$WORKSHOP_NAME}

SPAWNER_REPO=${SPAWNER_REPO:-openshift-labs/workshop-spawner}
SPAWNER_VERSION=${SPAWNER_VERSION:-4.3.0}
SPAWNER_MODE=${SPAWNER_MODE:-learning-portal}
SPAWNER_VARIANT=${SPAWNER_VARIANT:-production}

DASHBOARD_REPO=${SPAWNER_REPO:-openshift-labs/workshop-dashboard}
DASHBOARD_VERSION=3.6.2
DASHBOARD_IMAGE=quay.io/openshiftlabs/workshop-dashboard:$DASHBOARD_VERSION
DASHBOARD_VARIANT=${DASHBOARD_VARIANT:-production}

WORKSHOP_IMAGE=${WORKSHOP_IMAGE:-$DASHBOARD_IMAGE}

RESOURCE_BUDGET=${RESOURCE_BUDGET:-medium}
MAX_SESSION_AGE=${MAX_SESSION_AGE:-3600}
IDLE_TIMEOUT=${IDLE_TIMEOUT:-300}
LETS_ENCRYPT=${LETS_ENCRYPT:-false}

VERSION_INFO=`oc get --raw /version 2>/dev/null`

if [ x"$CONSOLE_VERSION" == x"" ]; then
    if [ `echo $VERSION_INFO | grep '"minor": "13+"'` ]; then
        CONSOLE_VERSION=4.1
    fi
fi

CONSOLE_VERSION=${CONSOLE_VERSION:-4.1}

SPAWNER_NAMESPACE=`oc project --short 2>/dev/null`

if [ x"$SPAWNER_NAMESPACE" == x"" ]; then
    fail "Cannot determine name of project."
    exit 1
fi
