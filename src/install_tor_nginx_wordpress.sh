#!/bin/bash

###################################
#########IMPORTANT NOTICE##########
###################################

# If you are using an ssh port other than 22, you need to adjust the fail2ban config below


# also consider changing your default ssh port in the file /etc/ssh/sshd_config
# and disabling SSH Root Login and using a passwordless authentication (ssh-keygen)

{ set +x; } 2>/dev/null
secure_flag=
purge_flag=
while test $# -gt 0; do
	case "$1" in
		-h|--help)
			echo "\ninstall_tor_nginx_wordpress.sh [options]"
			echo 
			echo "Options:"
			echo "-h, --help			Show brief help."
			echo "-s, --secure			Harden the Ubuntu Server (ufw, fail2ban, ...) before installing the server."
			echo "-p, --purge			Purge all existing nginx, wordpress, database files."
			exit 0
			;;
			
		-s|--secure)
			secure_flag=1
			shift
			;;
			
		-p|--purge)
			purge_flag=1
			shift
			;;
			
		*)
			break
			;;
	esac
done
set -x;


# install and configure fail2ban, ufw
harden_server() {
	sudo apt-get install -y ufw
	sudo ufw allow ssh
	sudo ufw allow http
	sudo ufw allow https
	sudo ufw enable
	
	sudo apt-get install -y fail2ban
	sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
	sudo printf "\n[sshd]\nenabled = true\nport = 22\nfilter = sshd\nlogpath = /var/log/auth.log\nmaxretry = 5\n" >> /etc/fail2ban/fail2ban.local
	sudo service fail2ban restart
}

# purges all existing nginx, wordpress, database files
purge_existing_sites() {
	cd /etc/nginx/conf.d
	sudo rm *
	
	cd /var/www/html
	FILES="/var/www/html/*"
	for f in $FILES; do
		if [[ "$f" != "/var/www/html/index.html" ]] && [[ "$f" != "/var/www/html/index.nginx-debian.html" ]]; then
			sudo rm -r $f
		fi
	done
	
	cd
	echo "Purged all website configs."
}

# check password strength
check_pw() {
	local pw="$1"
	local pw_name="$2"
	
	# check pw length and if pw is set
	if [[ -z "${pw}" ]]; then
 		>&2 printf "\nPassword must be set.\n"
 		exit 1
	elif [[ "${#pw}" -le  7 ]]; then
		>&2 printf "\nPassword must be 8 or more characters.\n"
		exit 1
	fi
	
	# check pw structure
	numeric='^[0-9]+$'
	upper_case='^[A-Z]+$'
	lower_case='^[a-z]+$'
	for (( i=0; i<${#pw}; i++ )); do
		if [[ "${pw:$i:1}" =~ $numeric ]]; then
			numeric_bool=true
		elif [[ "${pw:$i:1}" =~ $upper_case ]]; then
			uppercase_bool=true
		elif [[ "${pw:$i:1}" =~ $lower_case ]]; then
			lowercase_bool=true
		else
			special_bool=true
		fi
	done
	
	# generate secure password if needed
	if [[ -z "$numeric_bool" ]] || [[ -z "$uppercase_bool" ]] || [[ -z "$lowercase_bool" ]] || [[ -z "$special_bool" ]] ; then
		printf "$pw_name must contain at least one lower, upper case, numeric and special character.\n"
		read -p "Do you want me to provide a secure password for you? (y/n)" yn
		case $yn in
			[Yy]* ) 
				printf "\n\n"
				echo -n "$(cat /dev/urandom | tr -dc "[:alnum:]" | fold -w 20 | head -n 1)!"
				printf "\n\nCopy the password above into the terminal when asked for the root password. Then rerun the script.\n"
				exit 1
			;;
			[Nn]* ) 
				exit 1
			;;
			* ) 
				echo "Please answer yes or no."
				exit 1
			;;
	    	esac
	fi	
}

{ set +x; } 2>/dev/null
# query database and wordpress passwords and save to env variable
if [[ -z ${MYSQL_ROOT_ENV} ]]; then
	read -s -p "MYSQL_ROOT Password: " MYSQL_ROOT
	printf "\n"
	read -s -p "Retype MYSQL_ROOT Password: " check_mysql_root
	printf "\n"
	if [[ "${MYSQL_ROOT}" == "${check_mysql_root}" ]]; then
		check_pw "${MYSQL_ROOT}" "MYSQL_ROOT_ENV"
		export MYSQL_ROOT_ENV=${MYSQL_ROOT}
		# echo ${MYSQL_ROOT_ENV}
	else
		printf "\nPassword didn't match.\n"
		exit 1
	fi
else
	echo "MYSQL_ROOT_ENV is set"
fi

# query database username
if [[ -z ${MYSQL_USER_ENV} ]]; then
	read -s -p "MYSQL_USER Username: " MYSQL_USER
	printf "\n"
	read -s -p "Retype MYSQL_USER Username: " check_mysql_user
	printf "\n"
	if [[ "${MYSQL_USER}" == "${check_mysql_user}" ]]; then
		export MYSQL_USER_ENV=${MYSQL_USER}
		echo ${MYSQL_USER_ENV}
	else
		printf "\nUsernames didn't match.\n"
		exit 1
	fi
fi

# query database and website name
if [[ -z ${MYSQL_DB_ENV} ]]; then
	while [[ -z "$MYSQL_DB" ]]; do
		read -s -p "MYSQL_DB Database and Website name: " MYSQL_DB
		printf "\n"
		echo "Database and Website name cannot be empty!"
	done
	export MYSQL_DB_ENV=${MYSQL_DB}
	echo ${MYSQL_DB_ENV}
fi


read -p "Type y if you want to start the installation now (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	exit 1
fi

echo "Starting installation..."
set -x;

# exit on error and trace commands
logger --priority
set -o errexit
set -o nounset
set -o xtrace
set -o pipefail

sudo apt-get update -y
sudo apt-get upgrade -y

if [[ ! -z "$secure_flag" ]]; then
	harden_server
fi

if [[ ! -z "$purge_flag" ]]; then
	purge_existing_sites
fi


# install nginx
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# install php and mariadb
sudo apt-get install -y php \
php-mysql \
php-fpm \
php-curl \
php-gd \
php-intl \
php-mbstring \
php-soap \
php-xml \
php-xmlrpc \
php-zip \
mariadb-server \
mariadb-client

# save php version to variable
PHP_VERSION="$(php --version | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)"
PHP_SERVICE="php${PHP_VERSION}-fpm"

# start mariadb and php
sudo systemctl start mariadb
sudo systemctl start ${PHP_SERVICE}
sudo systemctl enable ${PHP_SERVICE}

# pull wordpress and copy to appropriate directories
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
sudo cp -R wordpress/ /var/www/html/${MYSQL_DB_ENV}.com 2>/dev/null
sudo chown -R www-data /var/www/html/${MYSQL_DB_ENV}.com 2>/dev/null
sudo chmod -R 775 /var/www/html/${MYSQL_DB_ENV}.com 2>/dev/null

# install tor and change tor config
sudo apt-get install tor -y
sudo sed -i -e "s+#HiddenServiceDir /var/lib/tor/hidden_service/+HiddenServiceDir /var/lib/tor/hidden_service/+" /etc/tor/torrc
sudo sed -i -e "s+#HiddenServicePort 80 127.0.0.1:80+HiddenServicePort 80 127.0.0.1:80+" /etc/tor/torrc
sudo service tor restart

# harden nginx config
sudo sed -i -e "s+# server_tokens off;+server_tokens off;+" /etc/nginx/nginx.conf
sudo sed -i -e "s+# server_name_in_redirect off;+server_name_in_redirect off;\n\tport_in_redirect off;fastcgi_hide_header X-Powered-By;proxy_hide_header X-Powered-By;+" /etc/nginx/nginx.conf
sudo service nginx restart

# set database connection settings
wp_config_sample=/var/www/html/${MYSQL_DB_ENV}.com/wp-config-sample.php 2>/dev/null 
if [[ -f "$wp_config_sample" ]]; then
	sudo mv /var/www/html/${MYSQL_DB_ENV}.com/wp-config-sample.php /var/www/html/${MYSQL_DB_ENV}.com/wp-config.php
fi

sudo sed -i -e "s+database_name_here+${MYSQL_DB_ENV}+" /var/www/html/${MYSQL_DB_ENV}.com/wp-config.php
sudo sed -i -e "s+username_here+${MYSQL_USER_ENV}+" /var/www/html/${MYSQL_DB_ENV}.com/wp-config.php
sudo sed -i -e "s+password_here+${MYSQL_ROOT_ENV}+" /var/www/html/${MYSQL_DB_ENV}.com/wp-config.php

# automates sudo mysql_secure_installation

{ set +x; } 2>/dev/null

sudo mysql -u root -e \
"SET PASSWORD FOR 'root'@localhost = PASSWORD('${MYSQL_ROOT_ENV}');
DROP USER IF EXISTS '';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;"

# create the wordpress database
sudo mysql -u root -e \
"CREATE DATABASE IF NOT EXISTS ${MYSQL_DB_ENV};
GRANT ALL PRIVILEGES ON ${MYSQL_DB_ENV}.* TO '${MYSQL_USER_ENV}'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_ENV}';
FLUSH PRIVILEGES;"

set -x;

# save nginx config for wordpress site
sudo cat > /etc/nginx/conf.d/${MYSQL_DB_ENV}.com.conf << EOM
server {
        listen 80;
        listen [::]:80;
        root /var/www/html/${MYSQL_DB_ENV}.com;
        index  index.php index.html index.htm;
        server_name ${MYSQL_DB_ENV}.com www.${MYSQL_DB_ENV}.com;
        
        error_log /var/log/nginx/${MYSQL_DB_ENV}.com_error.log;
        access_log /var/log/nginx/${MYSQL_DB_ENV}.com_access.log;
        
        client_max_body_size 100M;
        location / {
                try_files \$uri \$uri/ /index.php?\$args;
        }
        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
                fastcgi_param   SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }
        location ~* /xmlrpc.php$ {
    		allow 172.0.0.1;
    		deny all;
	}
}
EOM

# remove default sites
default_enabled=/etc/nginx/sites-enabled/default 2>/dev/null
default_available=/etc/nginx/sites-available/default 2>/dev/null
if [[ -f "$default_enabled" ]]; then
	sudo rm /etc/nginx/sites-enabled/default
fi

if [[ -f "$default_available" ]]; then
	sudo rm /etc/nginx/sites-available/default
fi

sudo systemctl restart nginx

# unset all env variables
unset MYSQL_ROOT
unset MYSQL_ROOT_ENV
unset MYSQL_USER
unset MYSQL_USER_ENV
unset MYSQL_DB
unset MYSQL_DB_ENV

{ set +x; } 2>/dev/null

# prints .onion web address
printf "\n\n\n\n\n"
printf "################################################################################################"
printf "\n\n\n\n"
printf "Your .onion address is: \n\n\n"
sudo cat /var/lib/tor/hidden_service/hostname
printf "\n\nPut it into your TOR browser and you should see the Wordpress starting page!"
printf "\nAt this point, your darkwebsite is already reachable!\n\n"

set -x;

