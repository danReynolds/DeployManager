#!/bin/sh

if [ "$DEPLOY_TYPE" = "deploy" ]; then
  echo "Deploying version $DEPLOY_TAG."
  rake docker:deploy
else
  echo "Building new version $DEPLOY_TAG and deploying."
  rake docker:build_deploy
fi
