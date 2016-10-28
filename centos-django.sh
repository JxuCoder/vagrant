#!/usr/bin/env bash

base_dir=$1
vhost_dev=$2
djg_prj_name=$3

www_dir=$base_dir/www
html_dir=$www_dir/html
phtml_dir=$www_dir/$vhost_dev/public_html
djg_prj_dir=$www_dir/$vhost_dev/$djg_prj_name

echo "Install Django through pip"
yum install -y python-pip >> /tmp/provision-script.log 2>&1
pip install --upgrade pip >> /tmp/provision-script.log 2>&1
pip install django >> /tmp/provision-script.log 2>&1
echo "Django Version: " && django-admin --version

echo "Creating a Django Test Project"
cd $www_dir/$vhost_dev
django-admin startproject $djg_prj_name

echo "Create a new database"
mysql -u root -proot -e "CREATE DATABASE djangotestdb;"

echo "Create a new MySQL user with a password"
mysql -u root -proot -e "CREATE USER  'djangotestuser'@'localhost' IDENTIFIED BY 'password';"

echo "Grant the new MySQL user permissions to manipulate the database"
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'djangotestuer'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;"

echo "To set Virtual Host"
echo "
<VirtualHost *:80>
    ServerName django.${vhost_dev}
    DocumentRoot ${djg_prj_dir}
    WSGIScriptAlias / ${djg_prj_dir}/${djg_prj_name}/wsgi.py
</VirtualHost>

WSGIPythonPath ${djg_prj_dir}/

<Directory ${djg_prj_dir}/${djg_prj_name}/>
  <Files wsgi.py>
    Require all granted
  </Files>
</Directory>
" >> /etc/httpd/sites-available/$vhost_dev.conf

# echo "To enable the New Virtual Host Files"
# ln -s /etc/httpd/sites-available/$vhost_dev.conf /etc/httpd/sites-enabled/$vhost_dev.conf
apachectl restart