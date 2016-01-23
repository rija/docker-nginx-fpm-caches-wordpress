## Usage patterns

The typical pattern I've adopted for some use cases is using a container each for Wordpress and Mysql and two data volume containers, one for each as well. Both containers run within one bridge network on a single host.


#### Creating a bridge network for Wordpress

this will create a Docker network on a single host that will be used by the Wordpress container and the MySQL container to communicate with eachother

```bash
$ docker network create -d bridge my_bnet
```

#### Deploying Mysql in a Docker container:

```bash
$ docker create --name mysqldata -v /var/lib/mysql mysql:5.5.45
$ docker run --name mysqlserver --volumes-from mysqldata --net=my_bnet -e MYSQL_ROOT_PASSWORD=<root password> -e MYSQL_DATABASE=wordpress -e MYSQL_USER=<user name> -e MYSQL_PASSWORD=<user password> -d mysql:5.5.45
```

#### Deploying Wordpress in a Docker container:

###### Create a data volume container for Wordpress files

```bash
$ docker create --name wwwdata -v /usr/share/nginx/www <name of your image>
```

###### Run a wordpress container
```bash
docker run -d \
	--name wordpress \
	--net=my_bnet \
	--env SERVER_NAME=example.com \
	--env DB_HOSTNAME=mysqlserver \
	--env DB_USER=wpuser \
	--env DB_PASSWORD=changeme \
	--env DB_DATABASE=wordpress \
	--volumes-from wwwdata \
	-v /etc/letsencrypt:/etc/letsencrypt \
	-p 443:443 -p 80:80 \
	rija/docker-nginx-fpm-caches-wordpress
```

Using data volume container for Wordpress and Mysql makes some operational task incredibly easy (backups, data migrations, cloning, developing with production data,...)

#### Export a data volume container:

```bash
$ docker run --rm --volumes-from wwwdata -v $(pwd):/backup rija/docker-nginx-fpm-caches-wordpress tar -cvz  -f /backup/wwwdata.tar.gz /usr/share/nginx/www

```
#### Import into a data volume container:

```bash
$ docker run --rm --volumes-from wwwdata2 -v $(pwd):/new-data rija/docker-nginx-fpm-caches-wordpress bash -c 'cd / && tar xzvf /new-data/wwwdata.tar.gz'
```

to verify the content:

```bash
$ docker run --rm --volumes-from wwwdata2 -v $(pwd):/new-data -it rija/docker-nginx-fpm-caches-wordpress bash
```


#### Import a sql database dump in Mysql running in a Docker container

```bash

$ <cd in the directory of the mysql dump file - which is assumed to be a *.sql.gz compressed file here >
$ docker run --rm  --link mysqlserver:db -v $(pwd):/dbbackup -it rija/docker-nginx-fpm-caches-wordpress bash

/# cd /dbbackup/
/# zcat <sql dump compressed file> | mysql -h $DB_HOSTNAME -u $DB_USER -p$DB_PASSWORD $DB_DATABASE
/# exit
```

to verify the content:

```bash
$ docker run --rm  --link mysqlserver:db -it rija/docker-nginx-fpm-caches-wordpress bash
$ mysql -h $DB_HOSTNAME -u $DB_USER -p$DB_PASSWORD $DB_DATABASE
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

