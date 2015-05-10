#!/bin/bash -e
#
# written by Dr. Abhishek Ghosh
# under GNU GPL 3.0
clear
echo " "
echo "This Script Will Deploy WordPress on OpenStack Nova Instance. Proceed?"
read -p "Hit Y or N " -n 1 -r
echo " "
echo "+++++"
echo "This Script is intended to run on Linux, OS X, HP-UX and Other unix or unix like OS."
echo "We Will Ask Some Questions, Write Them on a Text Editor and Save it."
echo "++++++"
echo " "
echo "Is everything is fine?"
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo " "
sudo su
fi
echo " "
echo "Supply the MySQL password below:"
read password
echo " "
echo "Supply the MySQL database below:"
read wordpress
echo " "
echo "Supply the domain name below:"
read domain

MYSQLPASS="$password"
MYSQLDATABASE="$wordpress"
SERVERNAMEORIP="$domain"

apt update -y
apt-get -y install nginx
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQLPASS}"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQLPASS}"
sudo apt-get -y install mysql-server mysql-client

apt-get install -y php5-mysql php5-fpm php5-gd php5-cli
echo "Configuring PHP5-FPM..."
echo " "
sed -i "s/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
sed -i "s/^;listen.owner = www-data/listen.owner = www-data/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/^;listen.group = www-data/listen.group = www-data/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/^;listen.mode = 0660/listen.mode = 0660/" /etc/php5/fpm/pool.d/www.conf
sed -i "s/^\tworker_connections 768;/\tworker_connections 1536;/" /etc/nginx/nginx.conf
sed -i "s/^\t#passenger_ruby \/usr\/bin\/ruby;/\t#passenger_ruby \/usr\/bin\/ruby;\n\n\tfastcgi_cache_path \/usr\/share\/nginx\/cache\/fcgi levels=1:2 keys_zone=microcache:10m max_size=1024m inactive=1h;/" /etc/nginx/nginx.conf
sed -i "s/^\tindex index.html index.htm;/\tindex index.php index.html index.htm;/" /etc/nginx/sites-available/default
sed -i "s/^\tserver_name localhost;/\tserver_name $SERVERNAMEORIP;\n\n\n\t\tset \$no_cache 0;\n\t\tif (\$request_method = POST){set \$no_cache 1;}\n\t\tif (\$query_string != \"\"){set \$no_cache 1;}\n\t\tif (\$http_cookie = \"PHPSESSID\"){set \$no_cache 1;}\n\t\tif (\$request_uri ~* \"\/wp-admin\/|\/xmlrpc.php|wp-.*.php|\/feed\/|index.php|sitemap(_index)?.xml\") {set \$no_cache 1;}\n\t\tif (\$http_cookie ~* \"comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in\"){set \$no_cache 1;}\n/" /etc/nginx/sites-available/default
sed -i "s/^\tlocation \/ {/\n\tlocation ~ \\\.php$ {\n\t\ttry_files \$uri =404;\n\t\tfastcgi_split_path_info ^(.+\\\.php)(\/.+)\$;\n\t\tfastcgi_cache  microcache;\n\t\tfastcgi_cache_key \$scheme\$host\$request_uri\$request_method;\n\t\tfastcgi_cache_valid 200 301 302 30s;\n\t\tfastcgi_cache_use_stale updating error timeout invalid_header http_500;\n\t\tfastcgi_pass_header Set-Cookie;\n\t\tfastcgi_no_cache \$no_cache;\n\t\tfastcgi_cache_bypass \$no_cache;\n\t\tfastcgi_pass_header Cookie;\n\t\tfastcgi_ignore_headers Cache-Control Expires Set-Cookie;\n\t\tfastcgi_pass unix:\/var\/run\/php5-fpm.sock;\n\t\tfastcgi_index index.php;\n\t\tinclude fastcgi_params;\n\t}\n\tlocation \/ {/" /etc/nginx/sites-available/default
echo "See your default nginx file..."
cat -n /etc/nginx/sites-available/default
echo "Restarting the services..."
service nginx restart
service mysql restart
service php5-fpm restart
echo " "
echo "Configuring the database..."
mysql -uroot -p$MYSQLPASS -e "create database ${MYSQLDATABASE}"
cd /usr/share/nginx/html
wget http://wordpress.org/latest.tar.gz && tar -xvzf latest.tar.gz
mv /usr/share/nginx/html/wordpress/* /usr/share/nginx/html/
sudo chown root:www-data /usr/share/nginx/html/
rm -rf wordpress latest.tar.gz
echo "Manually configure wp-config.php file..."
echo "Exiting the proce"
# Terminate our shell script with success message
exit 0
