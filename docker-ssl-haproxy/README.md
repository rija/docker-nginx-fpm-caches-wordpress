# docker-ssl-haproxy

###Maintainer

Rija Ménagé

###Description

This container run HAProxy with SSL (TLS) termination and forward traffic to two docker containers running on same docker host.

This is effectively a load balancer with SSL termination. It was designed to be used in conjunction with docker-nginx-fpm-caches-wordpress container. 

The aim is three-fold: 
 1. provide SSL termination to the LEMP/Wordpress stack provided by docker-nginx-fpm-caches-wordpress
 1. allow for zero downtime deployment of the LEMP/Wordpress stack provided by docker-nginx-fpm-caches-wordpress
 1. provide high availability of the application
 

### How to build an image

```bash

$ docker build -t="docker-ssl-haproxy" .

```
### How to run

```bash
$ docker run -d \
    --name proxy \
    -e SERVER_NAME=www.example.com \
    -e HA_STATS_CREDENTIALS=<username>:<password> \
    -v <path to ssl cert on docker host>:/etc/ssl/private \
    -p 443:443 \
    -p 80:80 \
    --link <LEMPWordpress1>:live \
    --link <LEMPWordpress2>:backup \
    docker-ssl-haproxy
```

Explanation of each line:
 1. run the container as a deamon
 1. name of container
 1. server name that should match name of certificate and name of web site
 1. http basic auth credentials for HAproxy stats web page
 1. certs have to be on docker host and mounted as a volume in container
 1. port for https traffic (port on docker host: port in container)
 1. port for http traffic (port on docker host: port in container)
 1. link to a docker-nginx-fpm-caches-wordpress container
 1. link to a backup docker-nginx-fpm-caches-wordpress container
 1. name of the image that has been build
 
**Notes:**

1. The two containers running the web stack should be connected to the same Database server container and mount the same Data Volume Container for web directory (/usr/share/nginx/www). That way the web stack is stateless.


### High Availability, Zero Downtime Deployment, A/B Testing

All of these are possible with the setup above. 
If one of the stack crashes, the web site is still available as the traffic will be directed to the running stack.

If ones wants to introduce a software change, one can update each stack at a time, avoiding the need for the site to be unavailable

If one wants to test how visitors behave with a particular feature in comparison another feature or the current feature set, one can enable the feature on one web stack and compare statistics for each web stack. It's better for this to modify haproxy configuration to add weighting to routing


### Caveats and current issues

1. Currently, if the web stacks are restarted or recreated,  haproxy has no way of knowing the new IP addresses and won't be able to connect to them.
This could be solved either by using a service discovery mechanism (etcd or consul) or by generating dynamically the config for haproxy.





