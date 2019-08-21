FROM centos:centos7

LABEL maintainer="Unicon, Inc."

#Workaround since OpenSUSE's provo-mirror is not working properly
#COPY security:shibboleth.repo /etc/yum.repos.d/security:shibboleth.repo

RUN yum -y update \
  && yum -y install wget \
  && rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm \
  && yum -y install epel-release \
  && yum -y update \
  && wget http://download.opensuse.org/repositories/security://shibboleth/CentOS_7/security:shibboleth.repo -P /etc/yum.repos.d \
  && yum -y install httpd shibboleth-3.0.4-3.2 mod_ssl php70w \
  && yum -y clean all

COPY httpd.conf /etc/httpd/conf/httpd.conf
COPY --chown=shibd:0 httpd-shibd-foreground /usr/local/bin/
COPY --chown=shibd:0 shibboleth/ /etc/shibboleth/

RUN test -d /var/run/lock || mkdir -p /var/run/lock \
  && test -d /var/lock/subsys/ || mkdir -p /var/lock/subsys/ \
  && chmod +x /etc/shibboleth/shibd-redhat \
  && chown shibd:0 /etc/shibboleth/shibd-redhat /var/cache/shibboleth \
  && echo $'export LD_LIBRARY_PATH=/opt/shibboleth/lib64:$LD_LIBRARY_PATH\n'\
  > /etc/sysconfig/shibd \
  && chmod +x /etc/sysconfig/shibd /etc/shibboleth/shibd-redhat /usr/local/bin/httpd-shibd-foreground \
  && chown -R shibd:0 /etc/sysconfig/shibd /usr/local/bin/httpd-shibd-foreground \
  && sed -i 's/ErrorLog "logs\/error_log"/ErrorLog \/dev\/stdout/g' /etc/httpd/conf/httpd.conf \
  && echo -e "\nErrorLogFormat \"httpd-error [%{u}t] [%-m:%l] [pid %P:tid %T] %7F: %E: [client\ %a] %M% ,\ referer\ %{Referer}i\"" >> /etc/httpd/conf/httpd.conf \
  && sed -i 's/CustomLog "logs\/access_log" combined/CustomLog \/dev\/stdout \"httpd-combined %h %l %u %t \\\"%r\\\" %>s %b \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\"\"/g' /etc/httpd/conf/httpd.conf \
  && sed -i 's/ErrorLog logs\/ssl_error_log/ErrorLog \/dev\/stdout/g' /etc/httpd/conf.d/ssl.conf \
  && sed -i 's/<\/VirtualHost>/ErrorLogFormat \"httpd-ssl-error [%{u}t] [%-m:%l] [pid %P:tid %T] %7F: %E: [client\\ %a] %M% ,\\ referer\\ %{Referer}i\"\n<\/VirtualHost>/g' /etc/httpd/conf.d/ssl.conf \
  && sed -i 's/CustomLog logs\/ssl_request_log/CustomLog \/dev\/stdout/g' /etc/httpd/conf.d/ssl.conf \
  && sed -i 's/TransferLog logs\/ssl_access_log/TransferLog \/dev\/stdout/g' /etc/httpd/conf.d/ssl.conf

EXPOSE 8080

RUN rm -rf /run/httpd && mkdir /run/httpd && chmod -R a+rwx /run/httpd && chmod -R a+rwx /var/run/shibboleth && rm /etc/httpd/conf.d/ssl.conf

USER shibd

CMD ["httpd-shibd-foreground"]
