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

The Wordpress web application is cloned from Wordpress' official Github.org repository at build time.
Alternatively, it's also possible to clone a Wordpress-based web site from a different public or private repository
as long as they are hosted on Github.org, Gitlab.org or Bitbucket.com.

The container doesn't have a database server, but the supplied docker compose file allow instantiating a MariaDB 10.2 database server on the same network as the Wordpress container.


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



*Available Docker Hub tags:* **v1, v2-beta, latest**

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
	-e DB_HOSTNAME=dbserver \
	-e DB_USER=wp_user \
	-e DB_PASSWORD=wp_password \
	-e DB_DATABASE=wp_database \
	-v /etc/letsencrypt:/etc/letsencrypt \
	-v /${HOME}:/root/backups \
	-p 443:443 -p 80:80 \
	rija/docker-nginx-fpm-caches-wordpress

```


**Notes:**
The ``ADMIN_EMAIL`` variable is used by WP-CLI for the initial setup of the Wordpress install and by Let's Encrypt's Certbot for managing TLS certificates renewal

#### with Docker compose:

```bash
$ cd docker-nginx-fpm-caches-wordpress
$ ./make_env.sh
$ docker-compose up -d
```

One can adjust the values in the **.env** file updated (and created if non-existent) by ``./make_env.sh``

#### with Ansible playbook:

###### - create a new image based on vanilla Wordpress install and push it to a private registry

```bash
$ ansible-playbook --extra-vars="registry_url=registry.gitlab.com registry_user=foobar" ansible/press-site.yml
```

One can adjust the values in the **.env** file updated (and created if non-existent) by ``./make_env.sh``

In particular, replace the value for GIT_SSH_URL to use the codebase of an existing/under development Wordpress web site.

###### - deploy on a Digital Ocean droplet the image that has been previously pushed to a private registry

```bash
$ ansible-playbook -i digital_ocean.py  --extra-vars="registry_url=registry.gitlab.com registry_user=foobar docker_host_user=docker" ansible/deploy-site.yml
```

where digital_ocean.py is downloaded from https://github.com/ansible/ansible/blob/devel/contrib/inventory/digital_ocean.py

```bash
$ curl -O https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/digital_ocean.py
$ chmod u+x digital_ocean.py
```

if you don't deploy on Digital Ocean, you can find the relevant dynamic inventory for your cloud service on https://github.com/ansible/ansible/tree/devel/contrib/inventory



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

### How to login to Wordpress Dashboard

The user is ``admin`` and the initial password (which should be changed immediately) can be found in the container log:

```bash
docker logs a-wordpress-container | grep "Admin password:"
```

### How to build

 ```bash
 $ cd docker-nginx-fpm-caches-wordpress
 $ ./make_env.sh && docker-compose up --build -d
 ```

One should adjust the values in the **.env** file updated (and created if non-existent) by **./make_env.sh**
make_env.sh should be executed at every build so that the dynamic docker labels for build date and vcs ref are populated accurately.

Notably, the ``GIT_SSH_URL`` variable can be adjusted to point to a Wordpress-based website project hosted on a remote GIT repository.

The mounted volume /root/deploykeys must contains file necessary files to allow cloning from a GIT repostory:
* a file named **git_hosts**  with the ssh host keys for the remote git repository
* public/private ssh key pair to ssh-git clone/pull from the remote repository (whose name is specified with ENV variable ``GIT_DEPLOY_KEY``)

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
