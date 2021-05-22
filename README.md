# darkwebserver

![GitHub last commit](https://img.shields.io/github/last-commit/thomasgruebl/darkwebserver?style=plastic) ![GitHub](https://img.shields.io/github/license/thomasgruebl/darkwebserver?style=plastic)

Turns your Ubuntu server into a darkwebserver. Tested on Ubuntu Server 21.04.

SHA256: b3165452d298699babb96352137cb6bbbfe3247a490f201b542b77c43e3acf5f  install_tor_nginx_wordpress.sh

Note: You should always check scripts before executing.

**Usage**
---

```
Make executable: chmod +x install_tor_nginx_wordpress.sh

Usage: sudo ./install_tor_nginx_wordpress.sh [OPTIONS]


Arguments:
  [1]	-s | --secure	Hardens Ubuntu Server (fail2ban, ufw, ...) before setting up the server.
  [2]	-p | --purge	Purges existing nginx, wordpress files (should be used if you've run the script multiple times and the wordpress site is not updating).
  [3]	-h | --help	Shows brief help.
```

**Description**
---

This script is intended to run on Ubuntu Server. You can either set up a VM running Ubuntu (e.g. as a AWS instance) or a dedicated webserver (such as your Raspberry Pi). You just need to run the script and follow the instructions and the darkwebserver should be fully functional right away. After the script is finished, you just need to paste the .onion address into the TOR browser (alternatively into Brave with TOR - although that's not recommended). Then carry on with the Wordpress configuration and your website should be running at this point.

This script comprises following features:

(1)	Sets up tor, an nginx server, a mariadb database and configures wordpress
(2)	Optionally hardens your Ubuntu server by setting up ufw, fail2ban, ...
(3)	Enforces secure password policy for mariadb.


In case the webserver stops working somehow and you need to rerun the script (or in case the same wordpress site keeps showing although you've created new ones in the meantime), then run the script with --purge (-p) or remove the following files and delete the mariadb databases:

* All files in /etc/nginx/conf.d
* All directories in /var/www/html
* All mariadb databases (sudo mysql -u root; SHOW DATABASES; DROP DATABASE ...;)
* Then reboot

**Background**
---

I didn't find a convenience script that automatically sets up a darkwebserver using nginx and mariadb with wordpress while also providing the basic hardening steps for Ubuntu Server 21.04.

