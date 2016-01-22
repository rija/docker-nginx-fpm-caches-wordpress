# docker-nginx-fpm-caches-wordpress
--


###Maintainer

Rija Ménagé

###Description

Docker file to create docker container with Nginx fronting php5-fpm running Wordpress with fastcgi-cache (+purge), opcache enabled. Encryption (TLS) support is included (using Letsencrypt.org's [ACME client](https://github.com/letsencrypt/letsencrypt)). Fastcgi-cache enables page caching while opcache enables caching of code execution.

```bash
$ docker run --name wordpress -d -e SERVER_NAME='example.com' --volumes-from wordpressfiles -v /etc/letsencrypt:/etc/letsencrypt -p 443:443 -p 80:80 --link mysqlserver:db rija/docker-nginx-fpm-caches-wordpress
```


**Notes:**
* There is no database server included:
The expected usage is to link another container running the database server.
* There is no mail server.
* Wordpress is installed from **'latest'** version
* Wordpress is installed as a single site deployment (no multisite support)
* Currently, the version of Nginx installed deployed to the built image is [1.8] (<https://www.nginx.com/blog/nginx-1-8-and-1-9-released/>)


### How to build

```bash
$ git clone https://github.com/rija/docker-nginx-fpm-caches-wordpress.git
$ cd docker-nginx-fpm-caches-wordpress
$ docker build -t="docker-nginx-fpm-caches-wordpress" .
```
You can choose whatever name you want for the image after the '-t=' parameter. 

Building an image is optional, you can also pull a pre-built image from  Docker Hub that tracks any changes made to that Git repository: 

```bash
docker pull rija/docker-nginx-fpm-caches-wordpress
```

That is optional as well. You can let Docker pull the image on-demand whenever you want to run the container. 


### How to run a Wordpress container

```bash
$ docker run --name wordpress -d -e SERVER_NAME='example.com' --volumes-from wordpressfiles -v /etc/letsencrypt:/etc/letsencrypt -p 443:443 -p 80:80 --link mysqlserver:db rija/docker-nginx-fpm-caches-wordpress
```

**Notes:**
 * that command assumes you already have a mysql container running with name 'mysqlserver'
 * you must replace example.com with your domain name
 * If you intend to use Docker Compose, make sure the name you choose for your container is only within [a-z][A-Z].

### How to enable Encryption (TLS)

It is advised to have read LetsEncrypt's [FAQ](https://community.letsencrypt.org/c/docs/) and [user guide](https://letsencrypt.readthedocs.org/en/latest/index.html)  beforehand.

after the Wordpress container has been started, run the following command and follow the on-screen instructions:

```bash
$ docker exec -it wordpress bash -c "cd /letsencrypt/ && ./letsencrypt-auto certonly"
```

After the command as returned with a successful message regarding acquisition of certificate, nginx needs to be restarted with encryption enabled and configured. This is done by running the following commands:

```bash
$ docker exec -it wordpress bash -c "cp /etc/nginx/ssl.conf /etc/nginx/ssl.example.com.conf"
$ docker exec -it wordpress bash -c "nginx -t"
$ docker exec -it wordpress bash -c "service nginx reload"
```

**Notes:**
 * There is no change required to nginx configuration for standard use cases
 * It is suggested to replace example.com by your domain name although any file name that match the pattern ssl.*.conf will be recognised
 * Navigating to the web site will throw a connection error until that step has been performed as encryption is enabled across the board and http connections are redirected to https. You must update nginx configuration files as needed to match your use case if that behaviour is not desirable.
 * Lets Encrypt's' ACME client configuration file is deployed to *'/etc/letsencrypt/cli.ini'*. Update that file to suit your use case regarding certificates.
 * Certificates are saved on the host server because this Dockerfile is intended for an architecture where a Docker container is considered stateless. If you want to keep everything in the container, drop the *'-v /etc/letsencrypt:/etc/letsencrypt'* argument from the *'docker run'* command
 
### Usage patterns

The typical pattern I've adopted is using a container each for Wordpress and Mysql and two data volume containers, one for each as well.

#### Deploying Mysql in a Docker container:

```bash
$ docker create --name mysqldata -v /var/lib/mysql mysql:5.5.45
$ docker run --name mysql --volumes-from mysqldata -e MYSQL_ROOT_PASSWORD=<root password> -e MYSQL_DATABASE=wordpress -e MYSQL_USER=<user name> -e MYSQL_PASSWORD=<user password> -d mysql:5.5.45
```

#### Deploying Wordpress in a Docker container:

######Create a data volume container for Wordpress files

```bash
$ docker create --name wwwdata -v /usr/share/nginx/www <name of your image>
```

######Run a wordpress container
```bash
docker run --name wordpress -d -e SERVER_NAME='example.com' --volumes-from wwwdata -v /etc/letsencrypt:/etc/letsencrypt -p 443:443 -p 80:80 --link mysqlserver:db rija/docker-nginx-fpm-caches-wordpress
```

Using data volume container for Wordpress and Mysql makes some operational task incredibly easy (backups, data migrations, cloning, developing with production data,...)

####Export a data volume container:

```bash
$ docker run --rm --volumes-from wwwdata -v $(pwd):/backup <name of your image> tar -cvz  -f /backup/wwwdata.tar.gz /usr/share/nginx/www

```
####Import into a data volume container:

```bash
$ docker run --rm --volumes-from wwwdata2 -v $(pwd):/new-data <name of your image> bash -c 'cd / && tar xzvf /new-data/wwwdata.tar.gz'
```

to verify the content:

```bash
$ docker run --rm --volumes-from wwwdata2 -v $(pwd):/new-data -it <name of your image> bash
```


####Import a sql database dump in Mysql running in a Docker container

```bash

$ <cd in the directory of the mysql dump file - which is assumed to be a *.sql.gz compressed file here >
$ docker run --rm  --link <name of the database server container>:db -v $(pwd):/dbbackup -it <name of your wordpress image> bash

/# cd /dbbackup/
/# zcat <sql dump compressed file> | mysql -h $DB_PORT_3306_TCP_ADDR -u $DB_ENV_MYSQL_USER -p$DB_ENV_MYSQL_PASSWORD $DB_ENV_MYSQL_DATABASE
/# exit
```

to verify the content:

```bash
$ docker run --rm  --link <name of the database server container>:db -it <name of your wordpress image> bash
$ mysql -h $DB_PORT_3306_TCP_ADDR -u $DB_ENV_MYSQL_USER -p$DB_ENV_MYSQL_PASSWORD $DB_ENV_MYSQL_DATABASE
```

#### Logs

The logs are exposed outside the container as a volume. 
So you can deploy your own services to process, analyse or aggregate the logs from the Wordpress installation.

The corresponding line in the Dockerfile is: 

```
VOLUME ["/var/log"]
```

you can mount this volume on another container with a command as shown below (assuming your Wordpress container is called 'wordpress'):

```bash
docker run --name MyLogAnalyser --volumes-from wordpress -d MyLogAnalyserImage
```


### Load-balancing with HAProxy

a sub-project, **docker-ssl-haproxy**, will provide a container running HAproxy for terminating encrypted connections and for load balancing multiple Wordpress containers (e.g: for scalability, availability, zero downtime deployment, A/B testing, etc...).
It's currently very much a work-in-progress (not really working).



### Future plan

* install supervisor as an Ubuntu package
* use nginx official Docker container as base image
* setup subprojects for:
	* a Mysql container with backup and import/export tools
	* a container with WebDAV access to the www data volume container
	* a container with tool to push logs to services like Splunk
* Test deployment on more cloud providers (so far only tested with Digital Ocean, aiming for AWS and Microsoft Azure)


