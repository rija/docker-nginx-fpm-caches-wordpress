# docker-nginx-fpm-caches-wordpress
--

**Status: Works for me**

###Maintainer

Rija Ménagé

###Description

Docker file to create docker container with Nginx fronting php5-fpm running Wordpress with fastcgi-cache (+purge), opcache and APCu enabled.

fastcgi-cache enables page caching (like static page caching), opcache enables caching of code execution, and APCu provides a data cache (like Memcached but much faster and much less scalable).

**No Wordpress plugins is provided** with the Dockerfile, but the following plugins are recommended to be installed through Wordpress's Admin panel to make the most out of the caching mechanisms installed:
* Nginx Helper: <https://wordpress.org/plugins/nginx-helper/>
* APCu Object Cache Backend: <https://wordpress.org/plugins/apcu/>

The first one allow control of facgi cache (i.e: purging). 
The second one enables Wordpress to use the APCu userland data caching


[TODO] A visual interface to Opcode is installed under restricted access (default login/password: ocview/ocview2015) to allow for analysis and purge of Opcode caching [/oc/]


**Please note:**
* There is no database server included:
The expected usage is to link another container running the database server.
* There is no mail server.
* Wordpress is installed from **'latest'** version
* Wordpress is installed as a single site deployment (no multisite support)
* Currently, the version of Nginx installed deployed to the built image is 1.8 (<https://www.nginx.com/blog/nginx-1-8-and-1-9-released/>)


### How to build

```bash
$ git clone git@github.com:rija/docker-nginx-fpm-caches-wordpress.git
$ cd docker-nginx-fpm-caches-wordpress
$ docker build -t="wordpress-nginx-caches-wordpress" .
```
You can choose whatever name you want for the image after the '-t=' parameter. 

**Tips:**
* If encountering problems with some package not installing, you can add the **'-no-cache'** option to **'docker build'** otherwise it will fetch package from cache. But to omit the option when you know there is no silent failure in order to accelerate build time.


### How to deploy

upload the image in a repository, private or public, and on the target Docker enabled system, type: 

```bash
$ docker run --name <name you want for your container> -d -p 80:80 --link <name of a database container>:db <name of the image you've built>
```

You can also build and deploy on the target machine as well. The command stays the same.
If you intend to use Docker Compose, make sure the name you choose for your container is only within [a-z][A-Z].


### Examples of deployment patterns

The typical pattern I've adopted is using a container each for Wordpress and Mysql and two data volume containers, one for each as well.

For mysql:

```bash
$ docker create --name mysqldata -v /var/lib/mysql mysql:5.5.42
$ docker run --name mysql --volumes-from mysqldata -e MYSQL_ROOT_PASSWORD=<root password> -e MYSQL_DATABASE=wordpress -e MYSQL_USER=<user name> -e MYSQL_PASSWORD=<user password> -d mysql:5.5.42
```

For wordpress:
```
$ docker create --name wwwdata -v /usr/share/nginx/www <name of your image>
$ docker run --name wordpress --volumes-from wwwdata -d -p 80:80 --link mysql-server:db <name of your image>
```

Using data volume container for Wordpress and Mysql makes some operational task incredibly easy (backups, data migrations, cloning, developing with production data,...)


### Future plan

I'm in the process of refactoring this project completely to use baseimage-docker as base image. That also means that I will drop Supervisor in favor of RunIt. 



--
 
> ###Disclaimer
> 
> Please, perform due diligence and research every line of the dockerfile.
> I don't guarantee that it will work for you.
> I don't guarantee it won't break your system.
> You use the artefacts of this project at your own risk.

--

*This project is inspired by the work of Eugene Ware on a Dockerfile for Wordpress deployment: <https://github.com/eugeneware/docker-wordpress-nginx>*