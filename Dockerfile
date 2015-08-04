FROM ubuntu:14.04
MAINTAINER Rija Menage <dockerfile@rijam.sent.as>

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive


RUN apt-get update
RUN apt-get -y upgrade

# Basic Dependencies
RUN apt-get -y install mysql-client php5-fpm php5-mysql pwgen python-setuptools curl git unzip



# to fix 'add-apt-repository: not found' in Ubuntu 14.04 LTS
RUN apt-get install software-properties-common python-software-properties -y

# Where to find  Nginx compiled with fastcgi_cache and fastcgi_cache_purge
RUN add-apt-repository ppa:rtcamp/nginx
RUN apt-get update
RUN apt-get -y install nginx-custom

# Dependencies for APCu
RUN apt-get -y install php5-dev libpcre3-dev

# Installing  Php-APCu
RUN yes "" | pecl install APCu-beta

# Configuring APCu
RUN echo "extension=apcu.so" >> /etc/php5/mods-available/apcu.ini
RUN cd /etc/php5/fpm/conf.d/ && ln -s ../../mods-available/apcu.ini 20-apcu.ini


# Wordpress Requirements
RUN apt-get -y install php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl


# Opcode config
RUN sed -i -e"s/^;opcache.enable=0/opcache.enable=1/" /etc/php5/fpm/php.ini
RUN sed -i -e"s/^;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/" /etc/php5/fpm/php.ini


# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf


# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf
RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# site specific nginx conf
ADD ./nginx-site.conf /etc/nginx/sites-available/default

# Supervisor Config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

# Install Wordpress 
RUN cd /usr/share/nginx/ \
    && curl -SLO https://wordpress.org/latest.tar.gz \
    && tar -xvf latest.tar.gz \
    && rm latest.tar.gz    
RUN mv /usr/share/nginx/wordpress /usr/share/nginx/www
RUN chown -R www-data:www-data /usr/share/nginx/www


# Wordpress Initialization and Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

# private port exposed
EXPOSE 80


CMD ["/bin/bash", "/start.sh"]
