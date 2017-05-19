#!/bin/bash

set -e

BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
VCS_REF=`git rev-parse --short HEAD`
VERSION=`cat VERSION`

if [ ! - f .env ];then
    echo ".env doesn't exist, create it first"
else
    sed -i -e "s/BUILD_DATE\s*=\s*.*$/BUILD_DATE=$BUILD_DATE/" .env
    sed -i -e "s/VCS_REF\s*=\s*.*$/VCS_REF=$VCS_REF/" .env
    sed -i -e "s/VERSION\s*=\s*.*$/VERSION=$VERSION/" .env
fi

echo ".env updated"
