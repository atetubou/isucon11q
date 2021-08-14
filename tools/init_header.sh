set -eu
source "${BASH_SOURCE%/*}/util.sh"
ensure_root

CONF_DIR=$(pwd)/
INIT_SH=$(pwd)/init.sh
LOG_DIR=$(pwd)/log

### utility functions for init.sh ###
update_file() {
	# return value: true iff updated
	ret=$(rsync -a --itemize-changes --dry-run "$1" "$2") || error "failed to rsync"
	if [ -z "$ret" ]
	then
		# nothing to do
		return 1
	else
		# copy
		mkdir -p $(dirname $2)
		info "Updating $2"
		rsync -a "$1" "$2" || error "failed to rsync"
#		# cp "$1" "$2" || error "failed to update (busy?)" # $2 may be busy
#		# simple cp may fail because $2 is busy: see https://qiita.com/todanano/items/05570fac310d56758888
#		temp=$(mktemp)
#		cp -a "$1" $temp
#		mv $temp "$2" || error "failed to mv"
#		rm -f $temp
		return 0
#	elif [ $ret -eq 0 ]
#	then
#		return 1
#	else
#		error "error in diff: $(diff -q "$1" "$2" 2>&1 >/dev/null)"
	fi
}
update_file_or_directory() {
	if [ ! -e "$1" ]
	then
		error "No such a file or directory: $1"
	elif [ -d "$1" ]
	then
		ok=1
		target="$1/"
		for file in $(find "$target" -type f)
		do
			dist="$2/$(echo $file | cut -b ${#target}-)"
			update_file "$file" "$dist" && ok=0
		done
		return $ok
	else
		update_file $@
		return $?
	fi
}
ensure_nginx_syntax() {
	nginx -t >/dev/null 2>&1 || nginx -t || error "nginx syntax error"
}
ensure_mysql_syntax() {
	mysqld --help --verbose >/dev/null || error "mysql syntax error"
}

declare -A UPDATED
update_if_differ() {
	# update_if_differ service_name from to
	if update_file_or_directory $2 $3
	then
		UPDATED[$1]=1
	fi
	return 0
}
restart_service_if_updated() {
	if [ ${UPDATED[$1]+dummy} ]
	then
		info "Restarting $1"
		systemctl restart $1
	fi
}

finish() {
	returnvalue=${?:-0}
	if [ $returnvalue -eq 0 ]
	then
		info 'done!'
	else
		error "exit with status $returnvalue" $?
	fi
	exit $?
}

trap 'trap - EXIT; info Interrupted; exit 0' INT
trap 'finish' TERM EXIT


