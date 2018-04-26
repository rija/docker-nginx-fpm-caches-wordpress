# docker-nginx-fpm-caches-wordpress

[![](https://images.microbadger.com/badges/image/rija/docker-nginx-fpm-caches-wordpress.svg)](https://microbadger.com/images/rija/docker-nginx-fpm-caches-wordpress "Get your own image badge on microbadger.com")
[![Build Status](https://img.shields.io/badge/docker%20hub-automated%20build-ff69b4.svg)](https://hub.docker.com/r/rija/docker-nginx-fpm-caches-wordpress/)
[![Build Status](https://travis-ci.org/rija/docker-nginx-fpm-caches-wordpress.svg?branch=master)](https://travis-ci.org/rija/docker-nginx-fpm-caches-wordpress)


### Maintainer

Rija Ménagé

### Description

Dockerfile to create a container with Nginx and php-fpm running a Wordpress web application.
TLS encryption is provided (and automatically renewed) using free certificates provided by Let's Encrypt.
Page caching (using Nginx's FastCGI cache) and Opcode caching with Zend Opcache are enabled and configured.

The container can be deployed with either a vanilla installation of Wordpress or an existing Wordpress-based codebase.

The container doesn't have a database server, but the supplied docker compose file allow instantiating a MariaDB 10.2 database server on the same network as the Wordpress container.

When choosing to use an existing Wordpress-based web site, the codebase is baked into the image when the image is built, so that the deployed container is immutable, making it play nicely in a versioned deployment pipelines.

When choosing to use a vanilla installation of Wordpress, the latest wordpress software is baked at build time, and additional security and caching related plugins are installed during deployment of the container.


**Headline features:**
* Nginx 1.13.0
* HTTP/2 and TLS encryption configured
* TLS configured using Mozilla Server-side TLS Intermediate profile + TLSv1.3
* PHP 7.1 installed with CLI, PHP-FPM and bare essential extensions
* FastCGI Caching+Cache Purge and Zend Opcode enabled
* RealIP Nginx module installed for when running behind a reverse-proxy
* Latest version of Wordpress is installed at container startup
* Can clone a Wordpress-based site from GIT repositories
* WP-CLI to manage a Wordpress install from command line
* OS-level security updates performed automatically
* TLS certificate automatically renewed
* Daily backup of database to volume sharable with Docker host
* Supervisord 3.0 as init script to manage processes' life-cycle
* Small-footprint Docker image using Bitnami/minideb as BASE image



*Available Docker Hub tags:* **v1, v2, latest**

### How to run


#### with docker run:

```bash

$ docker run --name a-mariadb-server \
	-e MYSQL_ROOT_PASSWORD=my-secret-pw \
	-e MYSQL_USER=wp_user \
	-e MYSQL_PASSWORD=wp_password \
	-e MYSQL_DATABASE=wp_database \
	-d mariadb:10.2

$ docker run -d \
	--link a-mariadb-server:dbserver \
	--name a-wordpress-container \
	-e SERVER_NAME=example.com \
	-e ADMIN_EMAIL=helloworld@example.com \
	-e ADMIN_PASSWORD=changemenow \
	-e DB_HOSTNAME=dbserver \
	-e DB_USER=wp_user \
	-e DB_PASSWORD=wp_password \
	-e DB_DATABASE=wp_database \
	-v /etc/letsencrypt:/etc/letsencrypt \
	-v /${HOME}:/root/sql \
	-p 443:443 -p 80:80 \
	rija/docker-nginx-fpm-caches-wordpress

```


**Notes:**
The ``ADMIN_EMAIL`` variable is used by WP-CLI for the initial setup of the Wordpress install and by Let's Encrypt's Certbot for managing TLS certificates renewal. It is also supplied alongside ``ADMIN_PASSWORD`` to the Wordpress install associated with the admin user.

#### with Docker compose:

```bash
$ cd docker-nginx-fpm-caches-wordpress
$ ./make_env
$ docker-compose up -d
```

One can adjust the values in the **.env** file updated (and created if non-existent) by ``./make_env``

#### with Ansible playbook:

###### - New image based on vanilla Wordpress pushed to a private registry

```bash
$ ansible-playbook --extra-vars="registry_url=registry.gitlab.com registry_user=foobar force_build=yes download_wp=yes" ansible/press-site.yml
```

One can adjust the values in the **.env** file updated (and created if non-existent) by ``./make_env``


###### - Deploy the previously baked image to a Digital Ocean droplet

```bash
$ ansible-playbook -i digital_ocean.py  --extra-vars="registry_url=registry.gitlab.com registry_user=foobar docker_host_user=docker" ansible/deploy-site.yml
```

where digital_ocean.py is downloaded from https://github.com/ansible/ansible/blob/devel/contrib/inventory/digital_ocean.py

```bash
$ curl -O https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/digital_ocean.py
$ chmod u+x digital_ocean.py
```

if you don't deploy on Digital Ocean, you can find the relevant dynamic inventory for your cloud service on https://github.com/ansible/ansible/tree/devel/contrib/inventory


###### - Workflow for an existing web site

make sure you have the web site in a directory called ``wordpress`` inside the ``website`` directory. Then ensure the database dump to be imported is there as well under the name ``wordpress.sql``:

```
website/
├── README.md
├── wordpress
├── VERSION
└── wordpress.sql
```

Then ensure you have an ``.env`` file with [appropriate variables](docs/env-sample):

```bash
$ ./make_env

```

The script above will also keep the build specific variables up-to-date.

Now, you can bake an image and upload it to a registry

```bash
$ ansible-playbook --extra-vars="registry_url=registry.gitlab.com registry_user=foobar force_build=yes" ansible/press-site.yml
```


to deploy, use:

```bash
$ ansible-playbook -vvv   -i digital_ocean.py  --extra-vars="registry_url=registry.gitlab.com registry_user=foobar docker_host_user=someuser update_image=yes" ansible/deploy-site.yml
```

### How to enable Encryption (TLS)

**This step is not necessary if you used the ansible playbook above.**

It is advised to have read Lets Encrypt's [FAQ](https://community.letsencrypt.org/c/docs/) and [user guide](https://letsencrypt.readthedocs.org/en/latest/index.html)  beforehand.

after the Wordpress container has been started, run the following command on the host and follow the on-screen instructions:

```bash
$ docker exec -it a-wordpress-container bash -c "/setup_web_cert"
```

After the command as returned with a successful message regarding acquisition of certificate, nginx will be reloaded with encryption enabled and configured.

**Notes:**
 * There is no change needed to nginx configuration for standard use cases
 * Navigating to the web site will throw a connection error until that step has been performed as encryption is enabled across the board and http connections are redirected to https. You should update nginx configuration files as needed to match your use case if that behaviour is not desirable.
 * Lets Encrypt's' Certbot client configuration file is deployed to ``/etc/letsencrypt/cli.ini``. Review and amend that file according to needs.
 * the generated certificate is valid for domain.tld and www.domain.tld (SAN)
 * **The certificate files are accessible on the Docker host server** in ``/etc/letsencrypt``


### How to build

First, make sure there is a Wordpress codebase under the ``website/`` directory.
Check the [website/README.md](website/README.md) for more details.

 ```bash
 $ cd docker-nginx-fpm-caches-wordpress
 $ ./make_env && docker-compose up --build -d
 ```

One should adjust the values in the **.env** file updated (and created if non-existent) by **./make_env**
make_env should be executed at every build so that the dynamic docker labels for build date and vcs ref are populated accurately.

### How to login to Wordpress Dashboard

The user is ``admin`` and the initial password can be supplied as ``ADMIN_PASSWORD`` in the **.env** file generated by  **./make_env**


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
