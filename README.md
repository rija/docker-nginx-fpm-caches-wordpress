# docker-nginx-fpm-caches-wordpress
--


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
$ git clone https://github.com/rija/docker-nginx-fpm-caches-wordpress.git
$ cd docker-nginx-fpm-caches-wordpress
$ docker build -t="wordpress-nginx-caches-wordpress" .
```
You can choose whatever name you want for the image after the '-t=' parameter. 

**Tips:**
* If encountering problems with some package not installing, you can add the **'-no-cache'** option to **'docker build'** otherwise it will fetch package from cache. But to omit the option when you know there is no silent failure in order to accelerate build time.


### How to deploy

upload the image in a repository, private or public, and on the target Docker enabled system, type: 

```bash
$ docker run --name <name you want for your container> -d -e SERVER_NAME=<FQDN of the web site> -p 80:80 --link <name of a database container>:db <name of the image you've built>
```

You can also build and deploy on the target machine as well. The command stays the same.
If you intend to use Docker Compose, make sure the name you choose for your container is only within [a-z][A-Z].

### Logs

The logs are exposed outside the container as a volume. 
So you can deploy your own services to process, analyse or aggregate the logs from the Wordpress installation.

The corresponding line in the Dockerfile is: 

```
VOLUME ["/var/log"]
```

you can mount this volume on another container with a command that looks as below (assuming your Wordpress container is called 'WordpressApp'):

```bash

docker run --name MyLogAnalyser --volumes-from WordpressApp -d MyLogAnalyserImage

```

### Usage patterns

The typical pattern I've adopted is using a container each for Wordpress and Mysql and two data volume containers, one for each as well.

#### Deploying Mysql in a Docker container:

```bash
$ docker create --name mysqldata -v /var/lib/mysql mysql:5.5.42
$ docker run --name mysql --volumes-from mysqldata -e MYSQL_ROOT_PASSWORD=<root password> -e MYSQL_DATABASE=wordpress -e MYSQL_USER=<user name> -e MYSQL_PASSWORD=<user password> -d mysql:5.5.42
```

#### Deploying Wordpress in a Docker container:

######Create a data volume container for the data files

```bash
$ docker create --name wwwdata -v /usr/share/nginx/www <name of your image>
```

######Instantiate Nginx, PHP4-FPM & Wordpress in a docker container
```bash
$ docker run --name wordpress --volumes-from wwwdata -d -p 80:80 --link mysql-server:db <name of your image>
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


####Migrating a Wordpress installation between environments:

For example to push the web site from Test to Production, or to build a Live-like version of the web site on your development machine.

Starting point: Working Wordpress install with real content deployed as shown in "Deploying Wordpress in a Docker container" and "Deploying Mysql in a Docker container".

On Test:
 1. export Database using a Wordpress Plugin like [WP Migrate DB](https://wordpress.org/plugins/wp-migrate-db/)
 1. export data files from the data volume container used by Wordpress container as described above
 1. export themes options if it applies
 1. export widgets using a Wordpress plugin like [Widgets Settings Importer/Exporter](https://wordpress.org/plugins/widget-settings-importexport/)

On Production:
 1. Instantiate a database server container as described above
 1. Import the mysql dump as shown in "Import a sql database dump in Mysql running in a Docker container"
 1. Create a data volume container for Wordpress as shown in first part of "Deploy Wordpress in a Docker container"
 1. Import data files as shown in "Import into a data volume container"
 1. verify that all files have been copied over. Remove the 'wp-config.php' file.
 1. Instantiate a wordpress server container as described in second part of "Deploy Wordpress in a Docker container"

**Notes:**
* When exporting data files, you can either backup the whole /usr/share/nginx/www or just /usr/share/nginx/www/wp-content
* When exporting data files, you may want to exclude large files from the uploads directory. E.g: You can pass '--exclude "*.mp3" to the tar command to exclude all mp3
* if you have exported /usr/share/nginx/www, Wordpress software is included which is most of the time what you want to do when migrating from Test to Production, but is rarely what you want if you were using these steps to get production data from Live installation into a newer version of the web site being developed. In that case export only wp-content
* the last note results from the fact that a mount point from a data volume container supersedes the identically named mount point from the instantiated container. More info at [Docker Docs](http://docs.docker.com/userguide/dockervolumes/).


### SSL & Zero Downtime Deployment

a child project, **docker-ssl-haproxy**, will provide a container running HAproxy for terminating SSL (TLS) connections and allow for zero downtime deployment.
It's currently a work-in-progress.



### Future plan

* install supervisor from Ubuntu package and with one config file per service
* have two optional subprojects (own directories/Dockerfile) for:
	* a Mysql container with backup tools
	* a container with WebDAV access to the www data volume container
	* a container with tool to push logs to services like Splunk
	* a container for a frontend Nginx server for SSL/WAF/Proxy
* Test deployment on more cloud providers (so far only tested with Digital Ocean, aiming for AWS and Microsoft Azure)
* make trusted builds


### Current Issues

######[FIXED] Only the home page is page-cached by fastcgi-cache

Whenever I load a page that is not the home page, the page is served from the server instead of the cache, always.
The response header contains:
```
X-Cache-Status:BYPASS
```

Update: 
after enabling the log at debug level:
```
error_log    /var/log/nginx/error.log debug;
```
I could see this:
```
2015/08/05 07:05:11 [debug] 115#0: *371 http script var: "q=/en/my-page/&"
2015/08/05 07:05:11 [debug] 115#0: *371 http script value: ""
2015/08/05 07:05:11 [debug] 115#0: *371 http script not equal
2015/08/05 07:05:11 [debug] 115#0: *371 http script if
2015/08/05 07:05:11 [debug] 115#0: *371 http script value: "1"
2015/08/05 07:05:11 [debug] 115#0: *371 http script set $skip_cache

```

which is the exectution of  this block of the site specific config:
```
    if ($query_string != "") {
            set $skip_cache 1;
    }
```

which led me to look at this line of the site specific config:
```
	try_files $uri $uri/ /index.php?q=$uri&$args
```

that was the problem. it should be:
```
	try_files $uri $uri/ /index.php?$args;
```

--
 
> ###Disclaimer
> 
> Please, perform due diligence and research every line of the dockerfile.
> I don't guarantee that it will work for you.
> I don't guarantee it won't break your system.
> You use the artefacts of this project at your own risk.

--

*This project is inspired by the work of Eugene Ware on a Dockerfile for Wordpress deployment: <https://github.com/eugeneware/docker-wordpress-nginx>*