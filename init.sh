#!/usr/bin/sudo /bin/bash
cd $(dirname $(readlink -f $0))
source ./tools/init_header.sh
echo '### nginx ###'
update_if_differ nginx /home/isucon/isucon11q///etc/nginx/sites-enabled/isuumo.conf /etc/nginx/sites-enabled/isuumo.conf
update_if_differ nginx /home/isucon/isucon11q///etc/nginx/mime.types /etc/nginx/mime.types
update_if_differ nginx /home/isucon/isucon11q///etc/nginx/nginx.conf /etc/nginx/nginx.conf
ensure_nginx_syntax
restart_service_if_updated nginx

echo '### mysql ###'
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/mysql.conf.d/mysqld_safe_syslog.cnf /etc/mysql/mysql.conf.d/mysqld_safe_syslog.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/conf.d/my.cnf /etc/mysql/conf.d/my.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/conf.d/mysqldump.cnf /etc/mysql/conf.d/mysqldump.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/conf.d/mysql.cnf /etc/mysql/conf.d/mysql.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/my.cnf /etc/mysql/my.cnf
ensure_mysql_syntax
restart_service_if_updated mysql

echo '### isuumo.go.service ###'
su isucon -c 'make -C ./go/'
update_if_differ isuumo.go.service ./go/ /home/isucon/isuumo/webapp/go
update_if_differ isuumo.go.service /home/isucon/isucon11q///etc/systemd/system/isuumo.go.service /etc/systemd/system/isuumo.go.service
restart_service_if_updated isuumo.go.service

