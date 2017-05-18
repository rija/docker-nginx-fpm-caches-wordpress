FROM bitnami/minideb:jessie
MAINTAINER Rija Menage <dockerfiles@rija.cinecinetique.com>

EXPOSE 80
EXPOSE 443

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# Basic Dependencies
RUN install_packages pwgen \
						ssh \
						curl \
						git \
						jq \
						iproute2 \
						cron \
						unzip

# install unattended upgrades, supervisor, mysql-client and fail2ban
RUN install_packages supervisor \
						unattended-upgrades \
						fail2ban \
						mysql-client

# php 7.1 installation

RUN install_packages apt-transport-https lsb-release ca-certificates
RUN curl  -o /etc/apt/trusted.gpg.d/php.gpg -fsSL https://packages.sury.org/php/apt.gpg \
	&& echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

RUN install_packages php7.1 \
						php7.1-fpm \
						php7.1-mysql \
						php7.1-gd \
						php7.1-intl \
						php7.1-imagick \
						php7.1-imap \
						php7.1-mcrypt \
						php7.1-pspell \
						php7.1-recode \
						php7.1-tidy \
						php7.1-xmlrpc \
						php7.1-xml \
						php7.1-json \
						php7.1-xsl \
						php7.1-opcache \
						php7.1-mbstring




# install nginx from source with ngx_http_v2_module, ngx_http_realip_module and ngx_cache_purge

ENV NGINX_VERSION 1.13.0

RUN install_packages build-essential zlib1g-dev libpcre3 libpcre3-dev libssl-dev libgeoip-dev
RUN install_packages nginx-common
RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
		&& cd /tmp \
		&& curl -O -fsSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
		&& curl -O -fsSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc \
		&& export GNUPGHOME="$(mktemp -d)" \
		&& found=''; \
		for server in \
			ha.pool.sks-keyservers.net \
			hkp://keyserver.ubuntu.com:80 \
			hkp://p80.pool.sks-keyservers.net:80 \
			pgp.mit.edu \
		; do \
			echo "Fetching GPG key $GPG_KEYS from $server"; \
			gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
		done; \
		test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
		gpg --batch --verify nginx-$NGINX_VERSION.tar.gz.asc nginx-$NGINX_VERSION.tar.gz \
		&& rm -r "$GNUPGHOME" nginx-$NGINX_VERSION.tar.gz.asc \
		&& tar xzvf nginx-$NGINX_VERSION.tar.gz \
		&& curl -o ngx_cache_purge-2.3.tar.gz -fsSL https://github.com/FRiCKLE/ngx_cache_purge/archive/2.3.tar.gz \
		&& tar xzvf ngx_cache_purge-2.3.tar.gz

RUN cd /tmp/nginx-$NGINX_VERSION \
		&& ./configure --prefix=/usr/share/nginx \
		--with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat \
		-Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' \
		--with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' \
		--conf-path=/etc/nginx/nginx.conf \
		--http-log-path=/var/log/nginx/access.log \
		--error-log-path=/var/log/nginx/error.log \
		--lock-path=/var/lock/nginx.lock \
		--pid-path=/run/nginx.pid \
		--http-client-body-temp-path=/var/lib/nginx/body \
		--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
		--http-proxy-temp-path=/var/lib/nginx/proxy  \
		--with-debug \
		--with-pcre-jit \
		--with-ipv6 \
		--with-http_ssl_module \
		--with-http_stub_status_module \
		--with-http_realip_module \
		--with-http_auth_request_module \
		--with-http_addition_module \
		--with-http_geoip_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_v2_module \
		--with-http_sub_module \
		--with-stream \
		--with-stream_ssl_module \
		--with-threads  \
		--add-module=/tmp/ngx_cache_purge-2.3 \
		&& make && make install \
		&& ln -fs /usr/share/nginx/sbin/nginx /usr/sbin/nginx


# Install LE's ACME client for domain validation and certificate generation and renewal

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" | tee /etc/apt/sources.list.d/php.list \
	&& apt-get update && apt-get -t jessie-backports install -y certbot \
	&& mkdir -p /tmp/le


# nginx config
RUN adduser --system --no-create-home --shell /bin/false --group --disabled-login www-front
COPY  nginx.conf /etc/nginx/nginx.conf
COPY  restrictions.conf /etc/nginx/restrictions.conf
COPY  ssl.conf /etc/nginx/ssl.conf
COPY  security_headers.conf /etc/nginx/security_headers.conf
COPY  le.ini /etc/nginx/le.ini
COPY  acme.challenge.le.conf /etc/nginx/acme.challenge.le.conf
COPY  nginx-site.conf /etc/nginx/sites-available/default
RUN openssl dhparam -out /etc/nginx/dhparam.pem 2048


# php-fpm config: Opcode cache config
RUN sed -i -e"s/^;opcache.enable=0/opcache.enable=1/" /etc/php/7.1/fpm/php.ini
RUN sed -i -e"s/^;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/" /etc/php/7.1/fpm/php.ini


# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.1/fpm/php.ini
RUN sed -i -e "s/expose_php = On/expose_php = Off/g" /etc/php/7.1/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.1/fpm/php.ini
RUN sed -i -e "s/;session.cookie_secure\s*=\s*/session.cookie_secure = True/g" /etc/php/7.1/fpm/php.ini
RUN sed -i -e "s/session.cookie_httponly\s*=\s*/session.cookie_httponly = True/g" /etc/php/7.1/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.1/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.1/fpm/pool.d/www.conf
RUN sed -i -e "s/listen\s*=\s*\/run\/php\/php7.1-fpm.sock/listen = 127.0.0.1:9000/g" /etc/php/7.1/fpm/pool.d/www.conf
RUN sed -i -e "s/;listen.allowed_clients\s*=\s*127.0.0.1/listen.allowed_clients = 127.0.0.1/g" /etc/php/7.1/fpm/pool.d/www.conf
RUN sed -i -e "s/;access.log\s*=\s*log\/\$pool.access.log/access.log = \/var\/log\/\$pool.access.log/g" /etc/php/7.1/fpm/pool.d/www.conf

# create the pid and sock file for php-fpm
RUN service php7.1-fpm start
RUN touch /var/log/php7.1-fpm.log && chown www-data:www-data /var/log/php7.1-fpm.log

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN GPG_KEYS=B42F6819007F00F88E364FD4036A9C25BF357DD4 \
               && curl -o /usr/local/bin/gosu -fsSL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
               && curl -o /usr/local/bin/gosu.asc -fsSL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
               && export GNUPGHOME="$(mktemp -d)" \
               && found=''; \
               for server in \
                       ha.pool.sks-keyservers.net \
                       hkp://keyserver.ubuntu.com:80 \
                       hkp://p80.pool.sks-keyservers.net:80 \
                       pgp.mit.edu \
               ; do \
                       echo "Fetching GPG key $GPG_KEYS from $server"; \
                       gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
               done; \
               test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
               gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
               && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
               && chmod +x /usr/local/bin/gosu \
               && gosu nobody true

# Supervisor Config
RUN /usr/bin/easy_install supervisor-stdout
RUN mkdir -p /var/log/supervisor && mkdir -p /var/run/supervisor
COPY  ./supervisord.conf /etc/supervisor/supervisord.conf
RUN chmod 700 /etc/supervisor/supervisord.conf

# Install Wordpress

ARG GIT_SSH_URL
ENV GIT_SSH_URL ${GIT_SSH_URL:-"https://github.com/WordPress/WordPress.git"}

COPY install_wordpress /install_wordpress
COPY ssh_config /root/.ssh/config
RUN chmod 700 /root/.ssh/config && chmod 700 /install_wordpress

# Bootstrap logs
RUN mkdir -p /var/log/nginx \
		&& touch /var/log/nginx/error.log \
		&& touch /var/log/nginx/access.log

RUN chown -R www-front:www-front /var/log/nginx \
		&& chown www-front:www-front /var/log/nginx/error.log \
		&& chown www-front:www-front /var/log/nginx/access.log

RUN touch /var/log/certs.log

# Setting up cronjob
COPY crontab /etc/wordpress.cron
RUN crontab /etc/wordpress.cron

# unattended upgrade configuration
COPY 02periodic /etc/apt/apt.conf.d/02periodic

# Wordpress Initialization and Startup Script
COPY  ./bootstrap.sh /bootstrap.sh
RUN chmod 700 /bootstrap.sh
