FROM ubuntu:14.04
MAINTAINER Rija Menage <dockerfile@rijam.sent.as>

EXPOSE 80
EXPOSE 443

CMD ["/bin/bash", "/start.sh"]

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive


# Basic Dependencies
RUN apt-get update && apt-get install -y mysql-client \
						php5-fpm \
						php5-mysql \
						pwgen \
						python-setuptools \
						curl \
						git \
						unzip




# Dependencies for APCu
#RUN apt-get install -y php5-dev libpcre3-dev

# Wordpress Requirements
RUN apt-get install -y php5-curl \
						php5-gd \
						php5-intl \
						php-pear \
						php5-imagick \
						php5-imap \
						php5-mcrypt \
						php5-memcache \
						php5-ming \
						php5-ps \
						php5-pspell \
						php5-recode \
						php5-sqlite \
						php5-tidy \
						php5-xmlrpc \
						php5-xsl

# to fix 'add-apt-repository: not found' in Ubuntu 14.04 LTS
RUN apt-get -y install software-properties-common \
						python-software-properties

# Where to find  Nginx compiled with fastcgi_cache and fastcgi_cache_purge
RUN add-apt-repository ppa:rtcamp/nginx
RUN apt-get update && apt-get install -y nginx-custom

# Install LE's ACME client for domain validation and certificate generation and renewal
RUN git clone https://github.com/letsencrypt/letsencrypt
RUN mkdir -p /tmp/le

# Installing  Php-APCu
#RUN yes "" | pecl install APCu-beta

# Configuring APCu
#RUN echo "extension=apcu.so" >> /etc/php5/mods-available/apcu.ini
#RUN cd /etc/php5/fpm/conf.d/ && ln -s ../../mods-available/apcu.ini 20-apcu.ini



# Opcode config
RUN sed -i -e"s/^;opcache.enable=0/opcache.enable=1/" /etc/php5/fpm/php.ini
RUN sed -i -e"s/^;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/" /etc/php5/fpm/php.ini

# nginx config
RUN adduser --system --no-create-home --shell /bin/false --group --disabled-login www-front
COPY  nginx.conf /etc/nginx/nginx.conf
COPY  restrictions.conf /etc/nginx/restrictions.conf
COPY  ssl.conf /etc/nginx/ssl.conf
COPY  le.ini /etc/nginx/le.ini
COPY  acme.challenge.le.conf /etc/nginx/acme.challenge.le.conf
COPY  nginx-site.conf /etc/nginx/sites-available/default
RUN openssl dhparam -out /etc/nginx/dhparam.pem 2048


# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/expose_php = On/expose_php = Off/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf
RUN sed -i -e "s/listen\s*=\s*\/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g" /etc/php5/fpm/pool.d/www.conf
RUN sed -i -e "s/;listen.allowed_clients\s*=\s*127.0.0.1/listen.allowed_clients = 127.0.0.1/g" /etc/php5/fpm/pool.d/www.conf



# Supervisor Config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
COPY  ./supervisord.conf /etc/supervisord.conf

# Install Wordpress
ENV WP_URL https://wordpress.org/latest.tar.gz
RUN cd /usr/share/nginx/ \
    && curl -o wp.tar.gz $WP_URL \
    && tar -xvf wp.tar.gz   
RUN mv /usr/share/nginx/wordpress /usr/share/nginx/www
RUN chown -R www-data:www-data /usr/share/nginx/www


# Wordpress Initialization and Startup Script
COPY  ./start.sh /start.sh
RUN chmod 755 /start.sh

VOLUME ["/var/log"]


