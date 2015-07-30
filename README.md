# docker-nginx-fpm-caches-wordpress
Docker file to create docker container with Nginx fronting php5-fpm running Wordpress with fastcgi-cache (+purge), opcache and APCu enabled.

Please note:
There is no Database server included.
The expected usage is to link another container running the database server.
The wp-content folder is expected to be on a Data Volume Container

