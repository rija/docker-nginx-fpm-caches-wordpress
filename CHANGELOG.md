CHANGELOG


## v2 (upcoming)

* Supervisord 3.0 is PID 1 and properly manages all the processes in the container
* Uses PHP 7.1
* TLS encryption with Let's Encrypt and automated certificate renewal, configured using Mozilla intermediary profile for server side TLS
* Use Nginx 1.13.0 with real_ip,  HTTP/2 and TLSv1.3 configured
* FastCGI page caching and cache purge compiled in Nginx
* docker-compose is now the preferred way to use this Dockerfile
* The deployment now relies on git and on retrieving the Wordpress web application from online repositories,
wether we are instantiating a vanilla Wordpress codebase or a custom Wordpress development
* Security has been improved on many layers:
  * Setup of Fail2ban for black-listing ip addresses of attackers and abusers at firewall level
  * Tightening of file permissions and configuration of server processess and bootstrapping scripts
  * Security headers in Nginx responses
  * Pre-installed WP Plugins for using Fail2Ban, reducing XML-RPC attack surface, and enabling Content Security Policy
  * PGP signature verification of downloaded package through APT or CURL
* The Docker image size has been significantly reduced (from 599MB/46layers to 192.4MB/37layers)
* uses WP-CLI

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
