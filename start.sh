#!/bin/bash

# first backup any existing config file in case variables have been manually added to it
if [ -f /usr/share/nginx/www/wp-config.php ]; then
  cp /usr/share/nginx/www/wp-config.php /usr/share/nginx/www/wp-config.php.orig
fi


# Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
# configuring wp-config with DB connection details from linked container then generate random password for keys
sed -e "s/database_name_here/$DB_ENV_MYSQL_DATABASE/
s/localhost/$DB_PORT_3306_TCP_ADDR/
s/username_here/$DB_ENV_MYSQL_USER/
s/password_here/$DB_ENV_MYSQL_PASSWORD/
/'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php


chown www-data:www-data /usr/share/nginx/www/wp-config.php


# start all the services
/usr/local/bin/supervisord -n
