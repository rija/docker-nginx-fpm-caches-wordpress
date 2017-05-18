# TODO

## SECURITY:

* ~~deroot cron~~
* ~~deroot supervisord~~ _see http://stackoverflow.com/questions/13905861/supervisor-as-non-root-user_
* ~~replace cron by an supervisord event listener listening on TICK_* events (see http://stackoverflow.com/questions/27341846/using-supervisor-as-cron)~~
* reverse start.sh/supervisord relationship so that supervisord is the init process and start.sh is under its control **[DONE]** _(Edit: start.sh is now bootstrap.sh)_
* create an apparmor profile for the project
* add a wordpress user on the container's host
* strict file ownership (uploads is only dir writable, all files owned by wordpress user and restricted)
* obfuscate Wordpress URL structure and headers
* disable Wordpress UI for theme update
* disable Wordpress UI for plugin update
* disable Wordpress UI for template code editing
* verify PGP signature of the downloaded nginx source code **[DONE]**
* add support for Fail2ban **[IN PROGRESS]**
* find a secure, easily configurable way to allow access to xmlrpc.php for staff who can't be tied to one specific IP

## ARCHITECTURE:

* ~~create a Dockerfile for a nginx proxy with fair balancer, streaming, page caching and TLS termination~~
* ~~include a Docker compose file for instantiating an nginx proxy,  a web server and database server on a new network~~
* reduce size of the image of this project **[DONE]** _(Edit: used bitnamit/minideb)_
* reduce size of the image of the dependent projects: mariadb
* container independence for Wordpress static files
* add a postfix container as a dependent project

## OPERATIONS:

* make Ansible playbooks for setting up container host **[IN PROGRESS]**
* automated daily backup of the database
* add restart policies in docker compose file

## ANALYTICS:

* send all logs to syslog and send them to splunk on the cloud
* put google analytic agent away from the application (maybe in nginx using ngx_pagespeed)
* integrate with NewRelics for system monitoring

## WORDPRESS & DEVELOPMENT:
* enable wp-cron
* add wp-cli to the container **[DONE]**
* if installing a custom Wordpress project, allow loading of in-repository database dump
* if installing a custom Wordpress project, allow loading of database dump from host

## MISC:

* Docker Hub images automated build that tracks Github tags (v#) **[DONE]**
* upgrade to PHP7 **[DONE]** (Edit: upgraded to 7.1)
* add support for APCu in-memory, in-process key/value userland object caching
* add GUI for opcode status
* enable /status and /ping for php-fpm
* look into Kubernetes on GCE
* install ACME client from OS package **[DONE]**
* review packages installed in Dockerfile, drop the unecessary ones **[DONE]**
* add support for HTTP/2 **[DONE]**
* customise download endpoint for Wordpress package. **[DONE]** _(Edit: flexibility based on GIT)_
* ~~checksum verification of Wordpress package when downloading specific version~~
