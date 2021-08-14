#!/bin/bash

#set -eu
set -u
cd $(dirname $(readlink -f $0))
source ./tools/util.sh

CONF_DIR=$(pwd)/
INIT_SH=$(pwd)/init.sh
LOG_DIR=$(pwd)/log


### utility functions for init.sh ###
update_conf() {
	diff -qr "$1" "$2" >/dev/null 2>&1
	ret=$?
	if [ $ret -ne 0 ]; then
		echo "Updating $2"
		if [ -d "$2" ]
		then
			rsync -Cva $1/ $2/
		else
			cp $1 $2
		fi
		return 0
	else
		# echo "Skipping $2"
		return 1
	fi
}
#####################################

# check the existence of a command
ensure_command() {
	if ! which $1 >/dev/null 2>&1
	then
		echo "Could not find '$1' command." >&2
		exit 1
	fi
}

check_command() {
	if ! which $1 >/dev/null 2>&1
	then
		echo "Could not find '$1' command." >&2
		return 1
	fi
	return 0
}


# resolve dir name (remove redundant slash, etc)
resolve_dirname() {
	( # open subshell
		if ! cd "$(dirname "$1")" 2>/dev/null
		then
			return 1
		fi

		echo $(pwd)/$(basename "$1") # ok
	)
}

append_init_sh() {
	# append_init_sh SERVICE CONTENT
	if diff -q <(sed -e "s@^\\(echo '### $1 ###'\\)\$@\\1\nDUMMY@" $INIT_SH) $INIT_SH >/dev/null
	then
		error "Could not find service '$1' in init.sh"
	fi
	sed -i -e "s@^\\(echo '### $1 ###'\\)\$@\\1\n$2@" $INIT_SH
}

# cp SRC LOCAL_DIR COMMENT
copy() {
	mkdir -p "$(dirname "$2")"
	echo "[$3] cp $1 $2" >&2
	if [ -d $1 ]
	then
		cp --no-target-directory --preserve=all -r "$1" "$2" # -r option will copy symlink, which is not good for single file
	else
		cp --no-target-directory --preserve=all "$1" "$2"
	fi
	append_init_sh "$3" "update_if_differ $3 $2 $1"
}
copy_conf() {
#	case "$2" in
#		"mysql" ) # whwn a syntax checker is available, use it
#			echo "ensure_${2}_syntax $CONF_DIR/$1" >>$INIT_SH;;
#	esac

	copy "$1" "$CONF_DIR/$1" "$2"
}

append_nginx_log_format() {
	LOGNAME=/var/log/nginx/detailed.log
	sudo touch $LOGNAME
	sudo chown www-data:www-data $LOGNAME
	awk -i inplace '{print}  /access_log/ && !n { print "	log_format ltsv \"time:$time_local\thost:$remote_addr\tforwardedfor:$http_x_forwarded_for\treq:$request\tstatus:$status\tmethod:$request_method\turi:$request_uri\tsize:$body_bytes_sent\treferer:$http_referer\tua:$http_user_agent\treqtime:$request_time\tcache:$upstream_http_x_cache\truntime:$upstream_http_x_runtime\tapptime:$upstream_response_time\tvhost:$host\";\n	'"access_log $LOGNAME ltsv;"'\n"; n++}' $1
}
append_mysql_slow_query() {
	LOGNAME=/var/log/mysql/mysql-slow.log
	sudo touch $LOGNAME
	sudo chown mysql:mysql $LOGNAME
	awk -i inplace '{print}  /\[mysqld\]/ && !n { print "slow_query_log = 1"; print "slow_query_log_file = '"$LOGNAME"'"; print "long_query_time = 0"; n++}' $1
}

ask() {
	echo -n $1 >&2
	shift
	read answer
	if [ "$answer" = "y" ]
	then
		$@
	fi
}

# a new version of ask.  Instead of executing, it returns true or false
yes_or_no() {
	while true
	do
		read -p "$1 (y/n)> " yn
		case $yn in
			[Yy]* ) return 0;;
			[Nn]* ) return 1;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}



# recursively process nginx conf
process_nginx_conf() {
	(
		copy_conf "$1" "nginx"
		# check if whether access_log format can be modified
		if grep -q 'access_log' "$CONF_DIR/$1"
		then
			ask "Found 'access_log' in nginx conf '$1'.  Do you want to append our log format? (y/N)> " append_nginx_log_format "$CONF_DIR/$1"
		fi
		# ignore error and include
		nextconf=$(find "" $(sed -ne 's/include\s\s*\(.*\);/\1/p' "$1") 2>/dev/null || true)
		for i in $nextconf
		do
			process_nginx_conf "$i"
		done
	)
}

setup_nginx() {
	echo "checking nginx" >&2
	check_command nginx || return 0

	echo "echo '### nginx ###'" >>$INIT_SH
	NGINX_CONF=$(nginx -V 2>&1 | tr ' ' '\n' | sed -n -e 's/--conf-path=//p')
	process_nginx_conf $NGINX_CONF
	echo "ensure_nginx_syntax" >>$INIT_SH
	echo "restart_service_if_updated nginx" >>$INIT_SH
	echo >>$INIT_SH
}

process_mysql_conf() {
	(
		copy_conf "$1" "mysql"
		# check if whether slow log option can be injected
		if grep -q '\[mysqld\]' "$CONF_DIR/$1"
		then
			ask "Found '[mysqld]' in mysql conf '$1'.  Do you want to enable slow log? (y/N)> " append_mysql_slow_query "$CONF_DIR/$1"
		fi
		includefiles=$(sed -ne 's/!include\s\s*\(.*\)/\1/p' $1)
		includedir=$(sed -ne 's/!includedir\s\s*\(.*\)/\1/p' $1)
		if [ "$includedir" != "" ]
		then
			includedirfiles=$(find $includedir -name '*.cnf')
			includefiles="$includefiles $includedirfiles"
		fi
		for i in $includefiles
		do
			process_mysql_conf "$i"
		done
	)
}

setup_mysql() {
	echo "checking mysql" >&2
	check_command mysql || return 0

	echo "echo '### mysql ###'" >>$INIT_SH
	CONFIGS=$(mysql --help | grep "Default options are read from the following files in the given order:" -A 1 | tail -1)
	for config in $CONFIGS
	do
		if [ -f $config ]
		then
			process_mysql_conf $config
		fi
	done
	echo "ensure_mysql_syntax" >>$INIT_SH
	echo "restart_service_if_updated mysql" >>$INIT_SH
	echo >>$INIT_SH
}

setup_systemd() {
	echo "checking systemd" >&2
	check_command systemctl || return 0

	TARGET_SERVICE=""

	PS3="Select an isucon service: "
	SERVICES=$(systemctl list-unit-files --type=service | awk '/isu/ {print $1}')
	if [ $(wc -w <<<$SERVICES) -gt 0 ]
	then
		select opt in $SERVICES
		do
			TARGET_SERVICE=$opt
			break
		done
	fi
	if [ "$TARGET_SERVICE" = "" ]
	then
		echo "Could not detect golang service!"
		echo -n "Enter service name (e.g. isubata.go.service)>" >&2
		read answer
		TARGET_SERVICE=$answer
	fi
	echo "echo '### $TARGET_SERVICE ###'" >>$INIT_SH
	UNITFILE=$(systemctl cat $TARGET_SERVICE | head -1 | cut -b 3-)
	copy_conf "$UNITFILE" "$TARGET_SERVICE"

#	RUNNING=$(systemctl --type=service | awk '/isu/ {print $1}') # currently running service
#	for units in $RUNNING
#	do
#		[ "$units" != "$TARGET_SERVICE" ] && echo "systemctl --quiet is-enabled $units && ( set -x; systemctl --now disable $units )" >>$INIT_SH
#	done
#	echo "systemctl --quiet is-enabled $TARGET_SERVICE || ( set -x; systemctl --now enable $TARGET_SERVICE )" >>$INIT_SH

	WORKING_DIR=$(systemctl cat $TARGET_SERVICE | sed -ne "s/WorkingDirectory\s*=\s*\(.*\)/\1/p" | head -1)
	if [ "$WORKING_DIR" = "" ]
	then
		echo "Could not find working directory"
		return 0
	fi
	mkdir -p "./$(basename "$WORKING_DIR")/"
	
	copy "$WORKING_DIR" "./$(basename "$WORKING_DIR")/" "$TARGET_SERVICE"
	append_init_sh $TARGET_SERVICE "su isucon -c 'make -C ./$(basename "$WORKING_DIR")/'"
	echo "restart_service_if_updated $TARGET_SERVICE" >>$INIT_SH
	echo >>$INIT_SH

	if yes_or_no "Shall I copy logger.go to ./$(basename "$WORKING_DIR")?"
	then
		ln -sr ./tools/logger.go ./$(basename "$WORKING_DIR")
	fi
}

init_main() {
	if [ -f $INIT_SH ]
	then
		echo "There is already $INIT_SH.  Remove?" >&2
		rm -i $INIT_SH
		if [ -f $INIT_SH ]
		then
			echo "terminated because $INIT_SH was not removed."
			exit 1
		fi
	fi
	touch $INIT_SH
	chmod 755 $INIT_SH
	cat << 'EOF' >> $INIT_SH
#!/usr/bin/sudo /bin/bash
cd $(dirname $(readlink -f $0))
source ./tools/init_header.sh
EOF


	setup_nginx
	setup_mysql
	setup_systemd
	echo "Generated $INIT_SH."

	if yes_or_no "Shall I copy init.sh, isucon.sh, and logger.sh to /usr/bin?"
	then
		sudo ln -sr ./tools/logger.sh /usr/bin
		sudo ln -sr ./isucon.sh /usr/bin
		sudo ln -sr ./init.sh /usr/bin
	fi
}

add_main() {
	SERVICE="$1"
	FROM="$2"
	TO="$3"
	if ! [ -f $INIT_SH ]
	then
		error "init.sh was not found: $INIT_SH"
	fi
	copy "$FROM" "$TO" "$SERVICE"
}

mysql_main() {
	(
		DB=$(mysql -N <<<'SELECT DATABASE();')
		TARGET="schema.sql"
		if [ "$DB" = "NULL" ]
		then
			echo "Choose database:"
			mysql <<<'show databases' --skip-column-names;
			echo -n "> "
			read DB
		fi
		echo "Writing to $TARGET" >&2
		truncate -s 0 $TARGET
		echo "-- DB: $DB" | tee -a $TARGET
		mysql <<<"SELECT table_name, engine, table_rows AS num_rows,  avg_row_length,  round((data_length+index_length)/1024/1024,3) AS size_mb, round((data_length)/1024/1024,3) AS data_mb, round((index_length)/1024/1024,3) AS index_mb FROM information_schema.tables WHERE table_schema='$DB' ORDER BY size_mb DESC" | column -s $'\t' -t | awk '{print "-- " $0}' | tee -a $TARGET
		mysqldump --no-data $DB --compact | sed 's/^\/\*\!.*$//' | tee -a $TARGET
	)
}

show_help_and_exit() {
	echo "Usage: $0 init                   generate init.sh" >&2
	echo "       $0 add SERVICE FROM TO    copy TARGET to pwd and append update script to init.sh" >&2
	echo "                                 associated with SERVICE" >&2
	echo "       $0 mysql                  show mysql information" >&2
	echo "Example:" >&2
	echo "$0 init " >&2
	echo "$0 add isubata.golang.service /home/isucon/isubata/webapp/public ./public " >&2
	exit ${1:-0}
}

main() {
	# precheck requirements
	ensure_command awk
	ensure_command sed

	if [ $# -ge 1 ]
	then
		subcommand="$1"
		shift
	else
		subcommand=help
	fi

	case $subcommand in
		init)
			init_main $@
			;;
		add)
			add_main $@
			;;
		mysql)
			mysql_main $@
			;;
		help | -h | --help)
			show_help_and_exit
			;;
		*)
			echo "Unknown subcommand: $subcommand" >&2
			show_help_and_exit 1
			;;
	esac

}

if [ "$0" = "$BASH_SOURCE" ]
then
	main $@
fi
