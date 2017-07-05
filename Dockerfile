FROM centos:latest
MAINTAINER Riccardo Manuelli

# install http
# RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum -y install epel-release; yum clean all;

# install httpd
RUN yum -y install httpd vim-enhanced bash-completion unzip; yum clean all;

# install mysql
#RUN yum install -y mariadb mariadb-server; yum clean all;
#RUN echo "NETWORKING=yes" > /etc/sysconfig/network
# start mysqld to create initial tables
# RUN service mysqld start
# RUN systemctl start mysqld



# Install MariaDB.
RUN \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0xcbcb082a1bb943db && \
  echo "deb http://mariadb.mirror.iweb.com/repo/10.0/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/mariadb.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server && \
  rm -rf /var/lib/apt/lists/* && \
  sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
  echo "mysqld_safe &" > /tmp/config && \
  echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
  echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config && \
  bash /tmp/config && \
  rm -f /tmp/config

# Define mountable directories.
VOLUME ["/etc/mysql", "/var/lib/mysql"]

# Define working directory.
WORKDIR /data

# Define default command.
CMD ["mysqld_safe"]

# Expose ports.
EXPOSE 3306

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
