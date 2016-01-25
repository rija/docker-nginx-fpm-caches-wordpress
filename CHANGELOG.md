CHANGELOG

## v1: Initial Release

* Initial release of a Dockerfile to create a Docker container running Wordpress on Nginx with Encryption (TLS) enabled.
* Page caching and cache purging with FastCGI is enabled, so is Opcode for object caching.
* Cron is enabled. Processes are managed by Supervisord.
* Php-fpm is the application server listening on a TCP port.
* In this release, versions are 1.8 for Nginx, 5.5.* for php-fpm.
* The base OS for the image is Ubuntu 14.04.
* A TLS certificate can be created and renewed with one bash command using the included Let’s Encrypt ACME client with no need for configuring Nginx for standard use case.
* Standard use case for this Dockerfile is running the latest version of single site Wordpress with one domain name domain.tld, also aliased as www.domain.tld and with TLS encryption enabled for the whole web site.
* No database server is included in the container, this is a feature.
* No mail server is included in the container, this is a feature.
* An automated build for this Dockerfile can be pulled from Docker Hub.