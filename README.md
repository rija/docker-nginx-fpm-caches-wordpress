# docker-nginx-fpm-caches-wordpress
--

**Status: Work In Progress**

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
* It is recommended to mount the wp-content folder from a Data Volume Container

###SSL:

[TODO] The Dockerfile also generate self signed certificates and ssl is enabled by default using the generated self-signed certificates. 
Feel free to remove the SSL section from the '**nginx-site.conf**' file if SSL is not needed. 

### How to build

```bash
$ git clone git@github.com:rija/docker-nginx-fpm-caches-wordpress.git
$ cd docker-nginx-fpm-caches-wordpress
$ docker build -t="wordpress-nginx-caches-wordpress" .
```

**Tips:**
* If encountering problems with some package not installing, you can add the **'-no-cache'** option to **'docker build'** otherwise it will fetch package from cache. But to omit the option when you know there is no silent failure in order to accelerate build time.

### Examples of deployment patterns

[TODO]

--
 
> ###Disclaimer
> 
> Please, perform due diligence and research every line of the dockerfile.
> I don't guarantee that it will work for you.
> I don't guarantee it won't break your system.
> You use the artefacts of this project at your own risk.

--

*This project is inspired by the work of Eugene Ware on a Dockerfile for Wordpress deployment: <https://github.com/eugeneware/docker-wordpress-nginx>*