### Usage patterns

The typical pattern I've adopted is using a container each for Wordpress and Mysql and two data volume containers, one for each as well.

#### Deploying Mysql in a Docker container:

```bash
$ docker create --name mysqldata -v /var/lib/mysql mysql:5.5.45
$ docker run --name mysql --volumes-from mysqldata -e MYSQL_ROOT_PASSWORD=<root password> -e MYSQL_DATABASE=wordpress -e MYSQL_USER=<user name> -e MYSQL_PASSWORD=<user password> -d mysql:5.5.45
```

#### Deploying Wordpress in a Docker container:

###### Create a data volume container for Wordpress files

```bash
$ docker create --name wwwdata -v /usr/share/nginx/www <name of your image>
```

###### Run a wordpress container
```bash
docker run --name wordpress -d -e SERVER_NAME='example.com' --volumes-from wwwdata -v /etc/letsencrypt:/etc/letsencrypt -p 443:443 -p 80:80 --link mysqlserver:db rija/docker-nginx-fpm-caches-wordpress
```

Using data volume container for Wordpress and Mysql makes some operational task incredibly easy (backups, data migrations, cloning, developing with production data,...)

#### Export a data volume container:

```bash
$ docker run --rm --volumes-from wwwdata -v $(pwd):/backup <name of your image> tar -cvz  -f /backup/wwwdata.tar.gz /usr/share/nginx/www

```
#### Import into a data volume container:

```bash
$ docker run --rm --volumes-from wwwdata2 -v $(pwd):/new-data <name of your image> bash -c 'cd / && tar xzvf /new-data/wwwdata.tar.gz'
```

to verify the content:

```bash
$ docker run --rm --volumes-from wwwdata2 -v $(pwd):/new-data -it <name of your image> bash
```


#### Import a sql database dump in Mysql running in a Docker container

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

