FROM centos:latest
MAINTAINER Riccardo Manuelli

# install http
# RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum -y install epel-release; yum clean all;

# install httpd
RUN yum -y install httpd vim-enhanced bash-completion unzip mariadb; yum clean all;

# install mysql
#RUN yum install -y mariadb mariadb-server; yum clean all;
#RUN echo "NETWORKING=yes" > /etc/sysconfig/network
# start mysqld to create initial tables
# RUN service mysqld start
# RUN systemctl start mysqld

RUN yum -y install --setopt=tsflags=nodocs epel-release && \ 
    yum -y install --setopt=tsflags=nodocs mariadb-server bind-utils pwgen psmisc hostname && \ 
    yum -y erase vim-minimal && \
    yum -y update && yum clean all


# Fix permissions to allow for running on openshift
COPY fix-permissions.sh ./
RUN ./fix-permissions.sh /var/lib/mysql/   && \
    ./fix-permissions.sh /var/log/mariadb/ && \
    ./fix-permissions.sh /var/run/

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

# Place VOLUME statement below all changes to /var/lib/mysql
VOLUME /var/lib/mysql

# By default will run as random user on openshift and the mysql user (27)
# everywhere else
USER 27

EXPOSE 3306
CMD ["mysqld_safe"]


# add repo to install php 5.5.X
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

# install php 5.5.X
RUN yum --enablerepo=remi,remi-php55 install -y php php-mysql php-devel php-gd php-pecl-memcache php-pspell php-snmp php-xmlrpc php-xml; yum clean all;

# install supervisord
RUN yum install -y python-pip && pip install "pip>=1.4,<1.5" --upgrade; yum clean all;
# RUN yum install -y python-pip; yum clean all;
RUN pip install supervisor

# install sshd
RUN yum install -y openssh-server openssh-clients passwd; yum clean all;

RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key 
RUN sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config && echo 'root:changeme' | chpasswd

VOLUME /var/www/html

ADD phpinfo.php /var/www/html/
ADD supervisord.conf /etc/
EXPOSE 22 80
EXPOSE 3306
CMD ["supervisord", "-n"]
