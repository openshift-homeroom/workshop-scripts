#!/bin/bash

SCRIPTS_DIR=`dirname $0`

. $SCRIPTS_DIR/setup-environment.sh

echo
echo "### Delete project resources."
echo

APPLICATION_LABELS="app=$SPAWNER_APPLICATION-$SPAWNER_NAMESPACE,spawner=$SPAWNER_MODE"

PROJECT_RESOURCES="services,routes,deploymentconfigs,imagestreams,secrets,configmaps,serviceaccounts,rolebindings,serviceaccounts,rolebindings,persistentvolumeclaims,pods"

echo
echo "### Delete global resources."
echo

oc delete "$PROJECT_RESOURCES" --selector "$APPLICATION_LABELS"

CLUSTER_RESOURCES="clusterrolebindings,clusterroles"

oc delete "$CLUSTER_RESOURCES" --selector "$APPLICATION_LABELS"
