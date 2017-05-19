# docker-nginx-fpm-caches-wordpress

[![](https://images.microbadger.com/badges/image/rija/docker-nginx-fpm-caches-wordpress.svg)](https://microbadger.com/images/rija/docker-nginx-fpm-caches-wordpress "Get your own image badge on microbadger.com")
[![Build Status](https://img.shields.io/badge/docker%20hub-automated%20build-ff69b4.svg)](https://hub.docker.com/r/rija/docker-nginx-fpm-caches-wordpress/)
[![Build Status](https://travis-ci.org/rija/docker-nginx-fpm-caches-wordpress.svg?branch=master)](https://travis-ci.org/rija/docker-nginx-fpm-caches-wordpress)


### Maintainer

Rija Ménagé

### Description

Dockerfile to create a container with Nginx and php5-fpm running Wordpress with fastcgi-cache and fastcgi\_cache\_purge. Opcache is also enabled (Fastcgi-cache enables page caching while Opcache enables caching of code execution). Encryption (TLS) is included and enabled by default (configured with Letsencrypt.org's [ACME client](https://github.com/letsencrypt/letsencrypt)). Cron is enabled.

*Available Docker tags:* **v1, stable, latest**

```bash
$ docker run -d \
	--name wordpress \
	--env SERVER_NAME=example.com \
	--env DB_HOSTNAME=4abbef615af7 \
	--env DB_USER=wpuser \
	--env DB_PASSWORD=changeme \
	--env DB_DATABASE=wordpress \
	-v /etc/letsencrypt:/etc/letsencrypt \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	-p 443:443 -p 80:80 \
	rija/docker-nginx-fpm-caches-wordpress
```


**Notes:**
* Database server is **not** included, but if you use ``docker-compose`` one will be deployed and linked to this container
* a MySQL database server must run on the same network as this container
* There is no mail server.
* The version of Wordpress installed is **'latest'** and is installed from Wordpress's official github mirror
* Wordpress is installed as a single site deployment (no multisite support)
* Currently, the version of Nginx deployed to the built image is [Nginx 1.13]
(<https://www.nginx.com/blog/nginx-1-8-and-1-9-released/>)
* The container talks to the Docker host to find the current IP address  of the database server whose hostname is passed to the docker run command


### How to build

```bash
$ git clone https://github.com/rija/docker-nginx-fpm-caches-wordpress.git
$ cd docker-nginx-fpm-caches-wordpress
$ docker build -t="docker-nginx-fpm-caches-wordpress" .
```

Building an image is optional, you can also pull a pre-built image from  Docker Hub that tracks any changes made to this Git repository:

```bash
docker pull rija/docker-nginx-fpm-caches-wordpress
```

That is optional as well but it is useful for updating the local image to a more recent version. You can let Docker pull the image on-demand whenever you want to run a new container.



### How to run a Wordpress container (Method 1)

```bash
$ docker run -d \
	--name wordpress \
	--env SERVER_NAME=example.com \
	--env DB_HOSTNAME=4abbef615af7 \
	--env DB_USER=wpuser \
	--env DB_PASSWORD=changeme \
	--env DB_DATABASE=wordpress \
	-v /etc/letsencrypt:/etc/letsencrypt \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	-p 443:443 -p 80:80 \
	rija/docker-nginx-fpm-caches-wordpress

```

**Notes:**
 * you must replace example.com with your domain name (without the www. prefix).
 * you can find the IP of the database server running on the default docker network with the command *'docker network inspect bridge'*.
 * if you don't want to use IP address and prefer using hostname, you should create your own Docker network to which the Wordpress container and the database server container are connected to.
 * If you intend to use Docker Compose, make sure the name you choose for your container is only within [a-z][A-Z].
 * This method keep database user and password in the shell history, unless the command is preceded by a space.


### How to run a Wordpress container (Method 2)

```bash
$ docker run -d \
	--name wordpress \
	--env-file /etc/wordpress_env_variables.txt \
	-v /etc/letsencrypt:/etc/letsencrypt \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	-p 443:443 -p 80:80 \
	rija/docker-nginx-fpm-caches-wordpress

```

**Notes:**
 * This method is similar to the previous one except all environment variables are stored in a text file. It's possible to mix --env and --env-file as well.
 * this method leaves database user and password on the host file system, unless the file is removed after the container is launched


### How to enable Encryption (TLS)

It is advised to have read Lets Encrypt's [FAQ](https://community.letsencrypt.org/c/docs/) and [user guide](https://letsencrypt.readthedocs.org/en/latest/index.html)  beforehand.

after the Wordpress container has been started, run the following command and follow the on-screen instructions:

```bash
$ docker exec -it wordpress bash -c "letsencrypt certonly"
```

After the command as returned with a successful message regarding acquisition of certificate, nginx needs to be restarted with encryption enabled and configured. This is done by running the following commands:

```bash
$ docker exec -it wordpress bash -c "cp /etc/nginx/ssl.conf /etc/nginx/ssl.example.com.conf"
$ docker exec -it wordpress bash -c "nginx -t && service nginx reload"
```

**Notes:**
 * There is no change required to nginx configuration for standard use cases
 * It is suggested to replace example.com in the file name by your domain name although any file name that match the pattern ssl.*.conf will be recognised
 * Navigating to the web site will throw a connection error until that step has been performed as encryption is enabled across the board and http connections are redirected to https. You must update nginx configuration files as needed to match your use case if that behaviour is not desirable.
 * Lets Encrypt's' ACME client configuration file is deployed to *'/etc/letsencrypt/cli.ini'*. Update that file to suit your use case regarding certificates.
 * the generated certificate is valid for domain.tld and www.domain.tld (SAN)
 * The certificate files are saved on the host server in /etc/letsencrypt

### Using Docker compose

commands in this section assume you have an .env file with the following environment variables:
```
SERVER_NAME=wp.local
COMPOSE_PROJECT_NAME=mywebapp
DB_USER=<database user>
DB_PASSWORD=<database password>
DB_DATABASE=<database name>
MYSQL_ROOT_PASSWORD=<password for the root user of the database server>

```

##### Instantiating a custom network, two containers: one with the project's image pulled from Docker Hub, one with a MariaDB server pulled from Docker Hub

```
docker-compose  -f docker-compose.yml up -d
```

##### Instantiating a custom network, two containers: one that will be built from local project files, one with MariaDB server pulled from Docker Hub

```
docker-compose up --build -d
```



### Usage Patterns and questions

* Please refers to the [Cookbook](https://github.com/rija/docker-nginx-fpm-caches-wordpress/blob/master/Cookbook.md) for tips and usage patterns.
* Check the [CHANGELOG](https://github.com/rija/docker-nginx-fpm-caches-wordpress/blob/master/CHANGELOG.md) for what's in each version
* Follow through the links in the [Credits](https://github.com/rija/docker-nginx-fpm-caches-wordpress#credits) and in the project's files
* Check out the [TODO](https://github.com/rija/docker-nginx-fpm-caches-wordpress/blob/master/TODO) for what things I want add or change next
* Raise an issue on Github

### License

MIT (see the [LICENSE](https://github.com/rija/docker-nginx-fpm-caches-wordpress/blob/master/LICENSE) file)

### Credits

* Eugene Ware for the original work on a [Nginx/Wordpress Dockerfile](https://github.com/eugeneware/docker-wordpress-nginx), whose ideas I've extended upon in this project
* [@renchap](https://community.letsencrypt.org/t/howto-easy-cert-generation-and-renewal-with-nginx/3491/5) and [@DrPain](https://community.letsencrypt.org/t/nginx-installation/3502/5) from [Let's Encrypt Community](https://community.letsencrypt.org/), whose ideas put me on the path of a working and elegant solution for Nginx/LetsEncrypt integration
* [Bjørn Johansen](https://bjornjohansen.no) for his blog articles on hardening a Wordpress installation that informed some of the choices I made
* Rahul Bansal of [EasyEngine](https://easyengine.io/wordpress-nginx/tutorials/) for his tutorials on Nginx/Wordpress integration that informed some of the choices I made
* All the contributors to the [Wordpress.org's Nginx support](http://codex.wordpress.org/Nginx) page
* Mozilla for their awesome [SSL configuration generator](https://mozilla.github.io/server-side-tls/ssl-config-generator/)
* All the the other people whose blog articles I've directly added in the comments in the relevant artefacts of this project
