#!/bin/bash


# setting up default for environment variables
SERVER_NAME=${SERVER_NAME:-example.com}
DB_HOSTNAME=${DB_HOSTNAME:-$DB_PORT_3306_TCP_ADDR}
DB_USER=${DB_USER:-$DB_ENV_MYSQL_USER}
DB_PASSWORD=${DB_PASSWORD:-$DB_ENV_MYSQL_PASSWORD}
DB_DATABASE=${DB_DATABASE:-$DB_ENV_MYSQL_DATABASE}


# first backup any existing config file in case variables have been manually added to it
if [ -f /usr/share/nginx/www/wp-config.php ]; then
  cp /usr/share/nginx/www/wp-config.php /usr/share/nginx/www/wp-config.php.orig
fi


# Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
# configuring wp-config with DB connection details from linked container then generate random password for keys
sed -e "s/database_name_here/$DB_DATABASE/
s/localhost/$DB_HOSTNAME/
s/username_here/$DB_USER/
s/password_here/$DB_PASSWORD/
/'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php


chown www-data:www-data /usr/share/nginx/www/wp-config.php



# replace the placeholder in nginx config files for server name and cert domain name
sed -i -e "s/server_fqdn/$SERVER_NAME/" /etc/nginx/sites-available/default
sed -i -e "s/server_fqdn/$SERVER_NAME/" /etc/nginx/ssl.conf

# create a config file for letsencrypt
sed -e "s/server_fqdn/$SERVER_NAME/g" /etc/nginx/le.ini > /etc/letsencrypt/cli.ini


# add server name to /etc/hosts to avoid timeout when code make http call to public url
EXT_IP=`ip route get 8.8.8.8 | awk '{print $NF; exit}'`
echo "$EXT_IP	$SERVER_NAME" >> /etc/hosts

# we want to be able to curl the web site from the localhost using https (for purging the cache, and for the cron)
echo "127.0.0.1	$SERVER_NAME" >> /etc/hosts


# retrieve the IP address of the database server
NETWORK=$(curl --silent --unix-socket /var/run/docker.sock http:/containers/$HOSTNAME/json | jq .NetworkSettings.Networks | jq keys | jq .[0] | sed -e 's/\"/*/g' | cut -s -f2 -d "*")
DB_IP=$(curl --silent --unix-socket /var/run/docker.sock http:/containers/$DB_HOSTNAME/json | jq .NetworkSettings.Networks.$NETWORK.IPAddress | sed -e 's/\"/*/g' | cut -s -f2 -d "*")
echo "$DB_IP	$DB_HOSTNAME" >> /etc/hosts


# start all the services
/usr/local/bin/supervisord -n
