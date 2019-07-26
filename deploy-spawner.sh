#!/bin/bash

SCRIPTS_DIR=`dirname $0`

. $SCRIPTS_DIR/setup-environment.sh

TEMPLATE_REPO=https://raw.githubusercontent.com/$SPAWNER_REPO
TEMPLATE_FILE=$SPAWNER_MODE-$SPAWNER_VARIANT.json
TEMPLATE_PATH=$TEMPLATE_REPO/$SPAWNER_VERSION/templates/$TEMPLATE_FILE

echo "### Checking spawner configuration."

if [[ "$SPAWNER_MODE" =~ ^(hosted-workshop|terminal-server)$ ]]; then
    if [ x"$CLUSTER_SUBDOMAIN" == x"" ]; then
        read -p "CLUSTER_SUBDOMAIN: " CLUSTER_SUBDOMAIN

        CLUSTER_SUBDOMAIN=$(trim $CLUSTER_SUBDOMAIN)

        if [ x"$CLUSTER_SUBDOMAIN" == x"" ]; then
            fail "Must provide valid CLUSTER_SUBDOMAIN."
        fi
    fi
fi

echo "### Creating spawner application."

TEMPLATE_ARGS=""

TEMPLATE_ARGS="$TEMPLATE_ARGS --param PROJECT_NAME=$PROJECT_NAME"
TEMPLATE_ARGS="$TEMPLATE_ARGS --param APPLICATION_NAME=$SPAWNER_APPLICATION"
TEMPLATE_ARGS="$TEMPLATE_ARGS --param GATEWAY_ENVVARS=$GATEWAY_ENVVARS"
TEMPLATE_ARGS="$TEMPLATE_ARGS --param TERMINAL_ENVVARS=$TERMINAL_ENVVARS"
TEMPLATE_ARGS="$TEMPLATE_ARGS --param WORKSHOP_ENVVARS=$WORKSHOP_ENVVARS"
TEMPLATE_ARGS="$TEMPLATE_ARGS --param IDLE_TIMEOUT=$IDLE_TIMEOUT"
TEMPLATE_ARGS="$TEMPLATE_ARGS --param JUPYTERHUB_CONFIG=$JUPYTERHUB_CONFIG"
TEMPLATE_ARGS="$TEMPLATE_ARGS --param LETS_ENCRYPT=$LETS_ENCRYPT"

if [ x"$SPAWNER_MODE" == x"learning-portal" ]; then
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param RESOURCE_BUDGET=$RESOURCE_BUDGET"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param HOMEROOM_LINK=$HOMEROOM_LINK"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CONSOLE_VERSION=$CONSOLE_VERSION"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param MAX_SESSION_AGE=$MAX_SESSION_AGE"
fi

if [ x"$SPAWNER_MODE" == x"user-workspace" ]; then
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param RESOURCE_BUDGET=$RESOURCE_BUDGET"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param HOMEROOM_LINK=$HOMEROOM_LINK"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CONSOLE_VERSION=$CONSOLE_VERSION"
fi

if [ x"$SPAWNER_MODE" == x"hosted-workshop" ]; then
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CLUSTER_SUBDOMAIN=$CLUSTER_SUBDOMAIN"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CONSOLE_VERSION=$CONSOLE_VERSION"
fi

if [ x"$SPAWNER_MODE" == x"terminal-server" ]; then
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CLUSTER_SUBDOMAIN=$CLUSTER_SUBDOMAIN"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CONSOLE_VERSION=$CONSOLE_VERSION"
fi

if [ x"$SPAWNER_MODE" == x"jumpbox-server" ]; then
    true
fi

oc process -f $TEMPLATE_PATH $TEMPLATE_ARGS | oc apply -f -

if [ "$?" != "0" ]; then
    fail "Failed to create deployment for spawner."
    exit 1
fi

echo "### Waiting for the spawner to deploy."

oc rollout status dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Deployment of spawner failed to complete."
    exit 1
fi

echo "### Install static resource definitions."

if [ -d $WORKSHOP_DIR/resources/ ]; then
    oc apply -f $WORKSHOP_DIR/resources/ --recursive

    if [ "$?" != "0" ]; then
        fail "Failed to create static resource definitions."
        exit 1
    fi
fi

echo "### Update spawner configuration for workshop."

if [ -f $WORKSHOP_DIR/templates/clusterroles-session-rules.yaml ]; then
    oc process -f $WORKSHOP_DIR/templates/clusterroles-session-rules.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$PROJECT_NAME" | oc apply -f -

    if [ "$?" != "0" ]; then
        fail "Failed to update session rules for workshop."
        exit 1
    fi
fi

if [ -f $WORKSHOP_DIR/templates/clusterroles-spawner-rules.yaml ]; then
    oc process -f $WORKSHOP_DIR/templates/clusterroles-spawner-rules.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$PROJECT_NAME" | oc apply -f -

    if [ "$?" != "0" ]; then
        fail "Failed to update spawner rules for workshop."
        exit 1
    fi
fi

if [ -f $WORKSHOP_DIR/templates/configmap-extra-resources.yaml ]; then
    oc process -f $WORKSHOP_DIR/templates/configmap-extra-resources.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$PROJECT_NAME" | oc apply -f -

    if [ "$?" != "0" ]; then
        fail "Failed to update extra resources for workshop."
        exit 1
    fi
fi

echo "### Restart the spawner with new configuration."

oc rollout latest dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Failed to restart the spawner."
    exit 1
fi

oc rollout status dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Deployment of spawner failed to complete."
    exit 1
fi

echo "### Updating spawner to use image for workshop."

oc tag "$WORKSHOP_IMAGE" "${SPAWNER_APPLICATION}-app:latest"

if [ "$?" != "0" ]; then
    fail "Failed to update spawner to use workshop image."
    exit 1
fi

echo "### Route details for the spawner are as follows."

oc get route "${SPAWNER_APPLICATION}"
