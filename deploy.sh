#!/bin/sh

if [ "$DEPLOY_TYPE" = "build" ]; then
  echo "Building from local and deploying specified tag."
  rake docker:build_deploy
else
  echo "Deploying specified tag."
  rake docker:deploy
fi
