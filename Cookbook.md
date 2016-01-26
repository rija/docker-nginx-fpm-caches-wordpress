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
$ docker run -d --name mysqlserver \
--volumes-from mysqldata \
--net=my_bnet \
--env MYSQL_ROOT_PASSWORD=<root password> \
--env MYSQL_DATABASE=wordpress \
--env MYSQL_USER=<user name> \
--env MYSQL_PASSWORD=<user password> mysql:5.5.45
```

#### Deploying Wordpress in a Docker container:

###### Create a data volume container for Wordpress files

```bash
$ docker create --name wwwdata -v /usr/share/nginx/www rija/docker-nginx-fpm-caches-wordpress
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

A quick way of extracting database connection information from the previously instanciated Mysql container is by running the following command:

```bash
docker exec -it mysqlserver bash -c "env" | grep -v ROOT | grep -v HOME | grep -v PWD | grep -v SHLVL | grep -v PATH | grep -v _=| sed "s/^/DB_/"
```

###### Enabling Encryption (TLS)

It is advised to have read Lets Encrypt's [FAQ](https://community.letsencrypt.org/c/docs/) and [user guide](https://letsencrypt.readthedocs.org/en/latest/index.html)  beforehand.

after the Wordpress container has been started, run the following command and follow the on-screen instructions:

```bash
$ docker exec -it wordpress bash -c "cd /letsencrypt/ && ./letsencrypt-auto certonly"
```

After the command as returned with a successful message regarding acquisition of certificate, nginx needs to be restarted with encryption enabled and configured. This is done by running the following commands:

```bash
$ docker exec -it wordpress bash -c "cp /etc/nginx/ssl.conf /etc/nginx/ssl.example.com.conf"
$ docker exec -it wordpress bash -c "nginx -t && service nginx reload"
```
It's the same command to run in order to renew the certificate, to duplicate them or to add sub-domains. The above read the content of *'/etc/letsencrypt/cli.ini'*. Most customisation of the certificate would involve changing that configuration file.

**Notes:**
 * There is no change required to nginx configuration for standard use cases
 * It is suggested to replace example.com in the file name by your domain name although any file name that match the pattern ssl.*.conf will be recognised
 * Navigating to the web site will throw a connection error until that step has been performed as encryption is enabled across the board and http connections are redirected to https. You must update nginx configuration files as needed to match your use case if that behaviour is not desirable.
 * Lets Encrypt's' ACME client configuration file is deployed to *'/etc/letsencrypt/cli.ini'*. Update that file to suit your use case regarding certificates.
 * the generated certificate is valid for domain.tld and www.domain.tld (SAN)
 * The certificate files are saved on the host server in /etc/letsencrypt and they have a 3 months lifespan before they need to be renewed


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

