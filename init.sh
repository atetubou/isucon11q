#!/usr/bin/sudo /bin/bash
cd $(dirname $(readlink -f $0))
source ./tools/init_header.sh
echo '### nginx ###'
update_if_differ nginx /home/isucon/isucon11q///etc/nginx/sites-enabled/isucondition.conf /etc/nginx/sites-enabled/isucondition.conf
update_if_differ nginx /home/isucon/isucon11q///etc/nginx/mime.types /etc/nginx/mime.types
update_if_differ nginx /home/isucon/isucon11q///etc/nginx/nginx.conf /etc/nginx/nginx.conf
ensure_nginx_syntax
restart_service_if_updated nginx

echo '### mysql ###'
update_if_differ mysql env.sh /home/isucon/env.sh
update_if_differ mysql ./sql /home/isucon/webapp/sql
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/mariadb.conf.d/50-client.cnf /etc/mysql/mariadb.conf.d/50-client.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/mariadb.conf.d/50-mysql-clients.cnf /etc/mysql/mariadb.conf.d/50-mysql-clients.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/mariadb.conf.d/50-mysqld_safe.cnf /etc/mysql/mariadb.conf.d/50-mysqld_safe.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/conf.d/mysql.cnf /etc/mysql/conf.d/mysql.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/conf.d/mysqldump.cnf /etc/mysql/conf.d/mysqldump.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/conf.d/my.cnf /etc/mysql/conf.d/my.cnf
update_if_differ mysql /home/isucon/isucon11q///etc/mysql/my.cnf /etc/mysql/my.cnf
ensure_mysql_syntax
restart_service_if_updated mysql

echo '### isucondition.go.service ###'
su isucon -c 'make -C ./go/'
update_if_differ isucondition.go.service ./go/ /home/isucon/webapp/go
update_if_differ isucondition.go.service /home/isucon/isucon11q///etc/systemd/system/isucondition.go.service /etc/systemd/system/isucondition.go.service
restart_service_if_updated isucondition.go.service

