FROM centos:latest

## Environment variables
ENV VERSION 4.3.1
ENV PLUGINS_VERSION 2.1.4
ENV API_VERSION 1.0.1
ENV FPING_VERSION 3.10

ENV NAGIOS_USERNAME=nagiosadmin
ENV NAGIOS_PASSWORD=nagiosadmin

## Install Nagios dependencies
RUN yum -y update; yum clean all;
RUN yum -y install \
	java-1.8.0-openjdk \
	wget \
	tar \
	httpd \
	php \
	make \
	perl \
	gcc \
	glibc \
	glibc-common \
	gd \
	gd-devel \
	openssl \
	openssl-devel \
	openssh-clients \
	samba-client \
	net-snmp \
	net-snmp-utils \
	openssh \
	bind-utils \ 
	freeradius-devel \
	openldap-devel \
	libdbi-devel \
	postgresql-devel \
	mysql-devel \
	perl-CPAN;

## Install CPAN and Nagios dependencies
RUN perl -MCPAN -Mlocal::lib=~/perl5 -e 'my $c = "CPAN::HandleConfig"; $c->load(doit => 1, autoconfig => 1); $c->edit(prerequisites_policy => "follow"); $c->edit(build_requires_install_policy => "yes"); $c->commit'
RUN cpan install \
	Test::More \
	Digest::MD5 \
	Crypt::CBC \
	Net::SNMP

## Install fping (used by default Nagios plugin)
RUN mkdir /tmp/fping
RUN wget http://fping.org/dist/fping-$FPING_VERSION.tar.gz --output-document=/tmp/fping.tar.gz
RUN cd /tmp; tar -xaf /tmp/fping.tar.gz --strip-components=1 --directory=/tmp/fping/
RUN cd /tmp/fping; \
	./configure; \
	make all; \
	make install;

RUN chmod u+s /bin/ping

## Create Nagios specific users & groups
RUN /usr/sbin/useradd -m nagios; \
	/usr/sbin/groupadd nagcmd; \
	/usr/sbin/usermod -a -G nagcmd nagios; \
	/usr/sbin/usermod -a -G nagcmd apache;

## Download Nagios
RUN mkdir /tmp/nagios
RUN wget http://downloads.sourceforge.net/project/nagios/nagios-4.x/nagios-$VERSION/nagios-$VERSION.tar.gz --output-document=/tmp/nagios.tar.gz
RUN cd /tmp; tar -xaf /tmp/nagios.tar.gz --strip-components=1 --directory=/tmp/nagios/

## Compile Nagios
RUN cd /tmp/nagios; \
	./configure --with-command-group=nagcmd; \
	make all; \
	make install; \
	make install-init; \
	make install-config; \
	make install-commandmode; \
	make install-webconf;

## Download Nagios Plugins source
RUN mkdir /tmp/nagios-plugins
RUN wget http://www.nagios-plugins.org/download/nagios-plugins-$PLUGINS_VERSION.tar.gz --output-document=/tmp/nagios-plugins.tar.gz
RUN cd /tmp; tar -xaf /tmp/nagios-plugins.tar.gz --strip-components=1 --directory=/tmp/nagios-plugins/

## Compile Nagios plugins
RUN cd /tmp/nagios-plugins; \
	./configure --with-nagios-user=nagios --with-nagios-group=nagios; \
	make all; \
	make install;

## Download Nagios API
RUN wget https://bitbucket.org/collabsoft/mvn-repository/raw/882d7bffb03277c22bd5728fe224fee3e8422d4e/net/collabsoft/nagios-api/1.0.1/nagios-api-1.0.1-jar-with-dependencies.jar --output-document=/opt/nagios-api.jar

## Create htpasswd file for basic authentication and add Apache Httpd configuration
RUN	htpasswd -bc /usr/local/nagios/etc/htpasswd.users $NAGIOS_USERNAME $NAGIOS_PASSWORD; \
	echo "RedirectMatch ^/$ /nagios" > /etc/httpd/conf.d/redirect.conf; \
	echo "ProxyPass /api http://localhost:5000" > /etc/httpd/conf.d/nagios-api.conf; \
	echo "ProxyPassReverse /api http://localhost:5000" >> /etc/httpd/conf.d/nagios-api.conf; \
	echo "ProxyPass /rest http://localhost:5000/rest" >> /etc/httpd/conf.d/nagios-api.conf; \
	echo "ProxyPassReverse /rest http://localhost:5000/rest" >> /etc/httpd/conf.d/nagios-api.conf;

## Move the nagios configuration to /config for easy volume mapping
RUN mv /usr/local/nagios/etc /config
RUN ln -s /config /usr/local/nagios/etc

## Make sure that all required nagios directories are available
RUN mkdir -p /usr/local/nagios/var/spool/checkresults
RUN mv /usr/local/nagios/var /data
RUN ln -s /data /usr/local/nagios/var
RUN chown -R nagios:nagcmd /data

## Check if Nagios configuration is valid
RUN /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

## Copy startup script
COPY ./start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

## Expose ports and volumes
EXPOSE 80
EXPOSE 5000
VOLUME /config
VOLUME /data

## Run the start script
CMD /opt/start.sh