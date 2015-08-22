FROM ubuntu:14.04
MAINTAINER Rija Menage <dockerfile@rijam.sent.as>

EXPOSE 80
EXPOSE 443

CMD ["/usr/bin/supervisord"]

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive


# Install software
RUN apt-get update && apt-get install -y curl supervisor

# to fix 'add-apt-repository: not found' in Ubuntu 14.04 LTS
RUN apt-get -y install software-properties-common \
						python-software-properties

RUN add-apt-repository ppa:vbernat/haproxy-1.5
RUN apt-get update && apt-get install -y haproxy

# HAProxy config
COPY haproxy.cfg /etc/haproxy/haproxy.cfg

# RSYSLOG config
COPY rsyslog.conf /etc/rsyslog.conf

# Supervisor Config
COPY supervisord.conf /etc/supervisord.conf
COPY haproxy-supervisord.conf /etc/supervisor/conf.d/haproxy-supervisord.conf
COPY rsyslog-supervisord.conf /etc/supervisor/conf.d/rsyslog-supervisord.conf

# Install launcher
COPY launch.sh /usr/local/sbin/
RUN chmod a+x /usr/local/sbin/launch.sh

CMD ["bash","/usr/local/sbin/launch.sh"]

VOLUME ["/var/log"]