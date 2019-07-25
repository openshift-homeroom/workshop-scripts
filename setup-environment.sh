#!/bin/bash

fail()
{
    echo "Error: " $* 1>&2
    exit 1
}

warn()
{
    echo "Warning: " $* 1>&2
}

echo "### Reading the workshop configuation."

SCRIPTS_DIR=`dirname $0`
WORKSHOP_DIR=`dirname $SCRIPTS_DIR`

if [ `basename $WORKSHOP_DIR` != ".workshop" ]; then
    fail "Failed to find workshop directory."
    exit 1
fi

if [ ! -f $WORKSHOP_DIR/settings.sh ]; then
    warn "Cannot find any workshop settings."
fi

echo "### Setting defaults for spawner application."

SPAWNER_REPO=${SPAWNER_REPO:-openshift-labs/workshop-spawner}
SPAWNER_VERSION=${SPAWNER_VERSION:-4.3.0}
SPAWNER_MODE=${SPAWNER_MODE:-learning-portal}
SPAWNER_VARIANT=${SPAWNER_VARIANT:-production}
SPAWNER_APPLICATION=${SPAWNER_APPLICATION:-$WORKSHOP_NAME}
SPAWNER_NAMESPACE=`oc project --short 2>/dev/null`

TEMPLATE_REPO=https://raw.githubusercontent.com/$SPAWNER_REPO
TEMPLATE_FILE=$SPAWNER_MODE-$SPAWNER_VARIANT.json
TEMPLATE_PATH=$SPAWNER_REPO/$SPAWNER_VERSION/templates/$TEMPLATE_FILE

WORKSHOP_NAME=${WORKSHOP_NAME:-$SPAWNER_MODE}
WORKSHOP_IMAGE=${WORKSHOP_IMAGE:-quay.io/openshiftlabs/workshop-dashboard:3.6.2}

IDLE_TIMEOUT=${IDLE_TIMEOUT:-300}
MAX_SESSION_AGE=${MAX_SESSION_AGE:-3600}
CONSOLE_VERSION=${CONSOLE_VERSION:-4.2.0}
RESOURCE_BUDGET=${RESOURCE_BUDGET:-medium}
LETS_ENCRYPT=${LETS_ENCRYPT:-false}

if [ x"$SPAWNER_NAMESPACE" == x"" ]; then
    fail "Cannot determine name of project."
    exit 1
fi
