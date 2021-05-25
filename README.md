# darkwebserver

![GitHub last commit](https://img.shields.io/github/last-commit/thomasgruebl/darkwebserver?style=plastic) ![GitHub](https://img.shields.io/github/license/thomasgruebl/darkwebserver?style=plastic)

<a style="text-decoration: none" href="https://github.com/thomasgruebl/darkwebserver/releases">
<img src="https://img.shields.io/github/downloads/thomasgruebl/darkwebserver/total.svg?style=plastic" alt="Downloads">
</a>

<a style="text-decoration: none" href="https://github.com/thomasgruebl/darkwebserver/stargazers">
<img src="https://img.shields.io/github/stars/thomasgruebl/darkwebserver.svg?style=plastic" alt="Stars">
</a>

<a style="text-decoration: none" href="https://github.com/thomasgruebl/darkwebserver/fork">
<img src="https://img.shields.io/github/forks/thomasgruebl/darkwebserver.svg?style=plastic" alt="Forks">
</a>

<a style="text-decoration: none" href="https://github.com/thomasgruebl/darkwebserver/issues">
<img src="https://img.shields.io/github/issues/thomasgruebl/darkwebserver.svg?style=plastic" alt="Issues">
</a>

Turns your Ubuntu server into a darkwebserver. Tested on Ubuntu Server 21.04.

SHA256: 365b74b6b87d5d082ffe7a69b517c2cf278da957151ec0c04c719063a95d2dfc

<b>Note: You should always check scripts before executing.</b>

<b>If you are using an ssh port other than 22, you need to adjust the fail2ban config in the harden_server() function.</b>

Also consider changing your default ssh port in the file /etc/ssh/sshd_config and disabling SSH Root Login and using passwordless authentication (ssh-keygen).

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

<b>Also note that Wordpress is not the safest web framework out there and is notoriously known for using a lot of JavaScript, which in turn does not harmonise well with TOR. Hence, don't use it for any fancy applications where security is the main focus (such as payment platforms and alike). This script is just intended to help you moving your daily blog or whatever to a nice-looking .onion site.</b>

