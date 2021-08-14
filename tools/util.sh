info() {
	printf '\033[33m%s\033[m\n' "$1"
}

warn() {
	printf '\033[31m%s\033[m\n' "Warning: $1"
}

error() {
	printf '\033[1m\033[31m%s\033[m\n' "Error: $1" 2>&1
	exit ${2:-1}
}

ensure_command() {
	if ! which "$1" >/dev/null 2>&1
	then
		case "$1" in
			"dstat")
				info "Installing dstat..."
				sudo DEBIAN_FRONTEND=noninteractive apt install -y python-mysqldb dstat
				;;
			*)
				error "Could not find '$1' command."
				;;
		esac
	fi
}

ensure_root() {
	if [ "$EUID" -ne 0 ]
	then
		error "Please run this script as root"
	fi
}

install_commands() {
	for cmd in "$@"
	do
		if ! which "$cmd" >/dev/null 2>&1
		then
			case "$cmd" in
				*)
					info "Installing $cmd..."
					sudo DEBIAN_FRONTEND=noninteractive apt install -y $cmd
					if ! which "$cmd" >/dev/null 2>&1
					then
						error "Failed to install '$cmd' command."
					fi
					;;
			esac
		fi
	done
}


