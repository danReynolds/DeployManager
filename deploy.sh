#!/bin/sh

if [ "$DEPLOY_TYPE" = "deploy" ]; then
  echo "Deploying version $DEPLOY_TAG."
  rake docker:deploy
elif [ "$DEPLOY_TYPE" = "build" ]; then
  echo "Building version $DEPLOY_TAG."
  rake docker:build
else
  echo "Building new version $DEPLOY_TAG and deploying."
  rake docker:build_deploy
fi
