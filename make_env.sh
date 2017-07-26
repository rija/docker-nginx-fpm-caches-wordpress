#!/bin/bash

set -ex

BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
VCS_REF=`git rev-parse --short HEAD`
VERSION=`cat VERSION`

if [ ! -f .env ];then
    {
		echo "SERVER_NAME=example.com";
		echo "COMPOSE_PROJECT_NAME=wordpress";
        echo "#The email will be used for registering to Lets Encrypt for the TLS certificate"
		echo "ADMIN_EMAIL=user@example.com";
		echo "WP_DB_USER=wordpress";
		echo "WP_DB_PASSWORD=wordpress";
		echo "WP_DB_NAME=wordpress";
		echo "MYSQL_ROOT_PASSWORD=wordpress";
        echo "#uncomment and subsitute placeholder text from below instead, keeping same connection format,  if clonning a wordpress web site from private repo"
		echo "#GIT_SSH_URL=git@github.com:user/project.git";
		echo "GIT_SSH_URL=https://github.com/WordPress/WordPress.git";
		echo "GIT_DEPLOY_KEY=git_deploy_key";
		echo "IMAGE_NAME=my-wordpress-dev";
		echo "BUILD_DATE=$BUILD_DATE";
		echo "VCS_REF=$VCS_REF";
		echo "VERSION=$VERSION";
	} > .env
    echo ".env created"
else
    sed -i.bak -e "s/BUILD_DATE\s*=\s*.*$/BUILD_DATE=$BUILD_DATE/
                s/VCS_REF\s*=\s*.*$/VCS_REF=$VCS_REF/
                s/VERSION\s*=\s*.*$/VERSION=$VERSION/" .env
    echo ".env updated"
fi
