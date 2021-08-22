#!/usr/bin/sudo /bin/bash
set -eu
cd $(dirname $(readlink -f $0))
source ./util.sh

NGINX_LOG_FILE=/var/log/nginx/detailed.log
MYSQL_LOG_FILE=/var/log/mysql/mysql-slow.log
LOG_DIR=./log
CPUPROF_FOLDER=/tmp/isucon/
ALP_CONF=./alpconfig.yml

show_help_and_exit() {
	echo "Usage: $0 start [ID]  start logging using working directory ID.  If ID is not provided, use nextid" >&2
	echo "       $0 stop  [ID]  stop logging and record logs" >&2
	echo "       $0 term  ID    terminate logging and remove directory ID" >&2
	echo "       $0 nextid      print next candidate id" >&2
	echo "       $0 lastid      print last bench id" >&2
	exit ${1:-0}
}

clear_mysql_logfile() {
	truncate -s 0 $MYSQL_LOG_FILE
	# postrotate script from /etc/logrotate.d/mysql-server
	test -x /usr/bin/mysqladmin || exit 0
	# If this fails, check debian.conf!
	MYADMIN="/usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf"
	if [ -z "`$MYADMIN ping 2>/dev/null`" ]; then
		# Really no mysqld or rather a missing debian-sys-maint user?
		# If this occurs and is not a error please report a bug.
		#if ps cax | grep -q mysqld; then
		if killall -q -s0 -umysql mysqld; then
			return 1
		fi
	else
		$MYADMIN flush-logs
	fi
	return $?
}

clear_nginx_logfile() {
	truncate -s 0 $NGINX_LOG_FILE
	# postrotate script from /etc/logrotate.d/nginx
	service nginx rotate
	return $?
}

log_file_name_of() {
	# log_file_name_of NAME [EXTENSION]
	ext="${2:-log}"
	echo $LOG_DIR/$HOSTNAME.$1.$ext
}

start_dstat() {
	logfile=$(log_file_name_of dstat)
	rm -f "$logfile"
	DSTAT_MYSQL_USER=root DSTAT_MYSQL_PWD= script -q -c "stty cols 1000; TERM=xterm-256color timeout 60 dstat -t -c --top-cpu -d -n -m -s --top-mem --mysql5-cmds --mysql5-io --mysql5-keys" "$logfile" >/dev/null 2>&1 &
}

maximum_of() {
	res=${1:-0}
	shift
	for i in $@
	do
		if [ $res -lt $i ]
		then
			res=$i
		fi
	done
	res=$(expr $res + 0) # cast as integer
	echo $res
}
get_last_dir() {
	# find the last directory (i.e. with a name of the largest number)
	maximum_of $(find $LOG_DIR -maxdepth 1 -type d | grep -o -E '[0-9]+$')
}
next_id() {
	last_id=$(get_last_dir)
	last_id=$((last_id + 1))
	branch=$(basename $(git name-rev --name-only HEAD) 2>/dev/null || true)
	[ -n "$branch" ] && branch="$branch-"
	echo $branch$(printf '%04d' $last_id)
}

start_logging() {
	if [ $# -ge 1 ]
	then
		LOG_DIR="$LOG_DIR/$1"
	else
		LOG_DIR="$LOG_DIR/$(next_id)"
	fi
	mkdir -p $LOG_DIR

	record_git_information || warn "failed to record git information"
	clear_nginx_logfile || warn "failed to clear nginx logfile"
	clear_mysql_logfile || warn "failed to clear mysql logfile"
	start_dstat || warn "failed to start dstat"
	echo "Successfully started logging.  (Working directory: $LOG_DIR)"
}

record_git_information() {
	# record commit hash
	if ! git status >/dev/null 2>&1
	then
		# nothing to record (since logger.sh is not in any git repository)
		return 0
	fi
	CURRENT_COMMIT=$(git rev-parse HEAD)
	FILENAME=$(log_file_name_of git txt)
	date +"%Y-%m-%d %H:%M:%S" >>$FILENAME # This date information will be also used by record_journalctl

	echo "Branch: $(basename $(git name-rev --name-only HEAD) 2>/dev/null)" >>$FILENAME
	echo "git diff $CURRENT_COMMIT" >>$FILENAME
	git diff $CURRENT_COMMIT >>$FILENAME 2>&1
}
record_mysql_log() {
	cp $MYSQL_LOG_FILE $(log_file_name_of mysql-slow) || return 1
	chmod 644 $(log_file_name_of mysql-slow) || return 1
	mysqldumpslow -s t $(log_file_name_of mysql-slow) >$(log_file_name_of mysqldumpslow txt) || return 1
}
record_nginx_log() {
	cp $NGINX_LOG_FILE $(log_file_name_of nginx) || return 1
	chmod 644 $(log_file_name_of nginx) || return 1

	cat $(log_file_name_of nginx) | alp ltsv --config "$ALP_CONF"  > "$(log_file_name_of nginxalp txt)" || return 1
}
record_cpuprof() {
	for i in $(ls $CPUPROF_FOLDER/*.prof)
	do
		filename=$(basename $i)
		base=${filename%.*}
		cp $i $(log_file_name_of $base prof) || return 1
	done
	go tool pprof -list='main.*' $(log_file_name_of cpu prof) >$(log_file_name_of cpuproflist txt) || return 1
}
stop_logging() {
	if [ $# -ge 1 ]
	then
		LOG_DIR="$LOG_DIR/$1"
	else
		error "Please specify ID"
	fi
	if [ ! -d $LOG_DIR ]
	then
		error "Could not find working directory: $LOG_DIR  (Did you started logging?)"
	fi

	record_mysql_log || warn "failed to record mysql log"
	record_nginx_log || warn "failed to record nginx log"
	record_cpuprof || warn "failed to copy cpu profile"
	record_journalctl || warn "failed to record journalctl"
	echo "Successfully stopped logging.  (Working directory: $LOG_DIR)"
}

record_journalctl() {
	filename=$(log_file_name_of journalctl txt)
	gitfilename=$(log_file_name_of git txt)
	journalctl -S "$(head -1 $gitfilename)" >$filename
}

terminate_logging() {
	if [ $# -eq 0 ]
	then
		error "Requires ID as argument"
	fi

	LOG_DIR="$LOG_DIR/$1"
	if [ ! -d $LOG_DIR ]
	then
		error "Could not find working directory: $LOG_DIR  (Did you started logging?)"
	fi

	rm -r $LOG_DIR || error "Could not remove directory: $LOG_DIR"
	echo "Successfully terminated logging.  (Working directory: $LOG_DIR)"
}

main() {
	mkdir -p $LOG_DIR

	if [ $# -ge 1 ]
	then
		subcommand="$1"
		shift
	else
		subcommand=help
	fi

	case $subcommand in
		start)
			start_logging $@
			;;
		stop)
			stop_logging $@
			;;
		nextid)
			next_id $@
			;;
		term)
			terminate_logging $@
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

main $@
