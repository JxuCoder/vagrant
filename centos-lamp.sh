#!/bin/bash

base_dir=$1
vhost_dev=$2

main() {
	echo "Install Linux, Apache, MySQL, PHP (LAMP) stack On CentOS 7"
	install_apache
	install_mysql
	install_php
	setup_tstpg
	echo "Processing of LAMP is completed!"
}

install_apache() {
	echo "Install Apache and start the web service"
	yum install -y httpd >& /tmp/centos-lamp.log 
	systemctl start httpd.service >& /tmp/centos-lamp.log 
	systemctl enable httpd.service >& /tmp/centos-lamp.log 
}

install_mysql() {
	echo "Install MySQL (MariaDB) and start the database service"
	yum install -y mariadb-server mariadb >& /tmp/centos-lamp.log 
	systemctl start mariadb.service >& /tmp/centos-lamp.log 
	systemctl enable mariadb.service >& /tmp/centos-lamp.log 

# 	mysql_secure_installation <<EOF
# 
# y
# db2016
# db2016
# y
# y
# y
# y
# EOF

	mysql -sfu root -e "UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root';
	DELETE FROM mysql.user WHERE User='';
	DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
	DROP DATABASE IF EXISTS test;
	DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
	FLUSH PRIVILEGES;"
}

install_php() {
	echo "Install PHP"
	yum install -y php php-pear php-mysql phpMyAdmin >& /tmp/centos-lamp.log 
	systemctl restart httpd.service >& /tmp/centos-lamp.log 
}

setup_tstpg() {
	www_dir=$base_dir/www
	html_dir=$www_dir/html
	phtml_dir=$www_dir/$vhost_dev/public_html
	php_dir=$www_dir/$vhost_dev/php

	echo "To create the directory for web server"
	mkdir -p $html_dir
	chmod -R 755 $www_dir

	echo "To create the HTML directory for $vhost"
	mkdir -p $phtml_dir
	mkdir -p $php_dir

	echo "Grant Permissions accordingly"
	chown -R $USER:$USER $phtml_dir
	chown -R $USER:$USER $php_dir

	echo "To create a demo of HTML page"
	echo "Welcome to test page" > $phtml_dir/index.html

	echo "To create PHP info test page; please remove it after test"
	echo "<?php phpinfo(); ?>" > $php_dir/index.php

	echo "To modify /etc/httpd/conf/httpd.conf"
	cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.old
	sed -e 's#\"/var/www\"#\"'"$www_dir"'\"#' \
		-e 's#\"/var/www/html\"#\"'$html_dir'\"#' /etc/httpd/conf/httpd.conf

	echo "To create directories for sites configration"
	mkdir /etc/httpd/sites-available
	mkdir /etc/httpd/sites-enabled

	echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf

	echo "To set Virtual Host"
	echo "
	<VirtualHost *:80>
	    ServerName www.${vhost_dev}
	    ServerAlias ${vhost_dev}
	    DocumentRoot ${phtml_dir}
	</VirtualHost>
	" > /etc/httpd/sites-available/$vhost_dev.conf

	echo "
	<VirtualHost *:80>
		ServerName php.${vhost_dev}
		DocumentRoot ${php_dir}
	</VirtualHost>
	" >> /etc/httpd/sites-available/$vhost_dev.conf

	echo "To enable the New Virtual Host Files"
	ln -s /etc/httpd/sites-available/$vhost_dev.conf /etc/httpd/sites-enabled/$vhost_dev.conf
	apachectl restart
}

main
exit 0