FROM php:7.3-apache

LABEL maintainer="thomaskrasowski@hotmail.com"

ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
  && apt-get install -y iputils-ping net-tools nano vim git wget openssh-server \
        libapache2-mod-rpaf \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libc-client-dev \
        libkrb5-dev \
        postgresql-client \
	libpq-dev
#        && rm -r /var/lib/apt/lists/*
RUN pecl install redis


RUN docker-php-ext-install -j$(nproc) iconv mysqli calendar shmop sysvmsg sysvsem sysvshm \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && docker-php-ext-enable redis \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql

RUN a2enmod rewrite
RUN a2enmod ssl

#copy the code
COPY . /var/www/html/



#variable to change the document root folder
ENV APACHE_DOCUMENT_ROOT /var/www/html
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
#RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
ENV APACHE_LOG_DIR /var/log/apache2/

#some configs
RUN sed -i 's/Require\ local/Allow\ from\ all/' /etc/apache2/mods-enabled/status.conf \
 && echo 'export HISTSIZE=10000' >> /root/.bashrc \
 && echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> /root/.bashrc \
 && echo 'export HISTCONTROL=ignorespace' >> /root/.bashrc

#allow fs-web readonly access to recording files
RUN usermod -aG root www-data

EXPOSE 80
EXPOSE 443
