#! /usr/bin/env bash

set -ex

# -- env vars --

export DEBIAN_FRONTEND=noninteractive

# -- end env vars --

# dotnet dependencies

wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb

dpkg -i packages-microsoft-prod.deb

apt-get update && \
apt-get install -y apt-transport-https && \
apt-get update && \
apt-get install -y dotnet-sdk-3.1

# mysql dependencies

wget https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb

dpkg -i mysql-apt-config_0.8.15-1_all.deb

# set environment variables that are necessary for MySQL installation
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password lc-password"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password lc-password"

# install MySQL in a noninteractive way since the environment variables set the necessary information for setup
apt-get update && apt-get install mysql-server -y

### MySQL section START ###

# create a setup.sql file which will create our database, our user, and grant our user privileges to the database
cat >> setup.sql << EOF
CREATE DATABASE coding_events;
CREATE USER 'coding_events'@'localhost' IDENTIFIED BY 'launchcode';
GRANT ALL PRIVILEGES ON coding_events.* TO 'coding_events'@'localhost';
FLUSH PRIVILEGES;
EOF

# using the mysql CLI to run the setup.sql file as the root user in the mysql database
mysql -u root --password=lc-password mysql < setup.sql

# END CONFIGURE

systemctl disable mysql
service mysql stop