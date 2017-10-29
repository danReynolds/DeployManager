#!/bin/sh

if [ "$DEPLOY_TYPE" = "build" ]
  rake docker:build_deploy
else
  rake docker:deploy
fi
