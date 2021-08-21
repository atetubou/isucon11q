#!/bin/bash -eu

#HOSTS=$(echo isucon@app{1,2,3})
HOSTS=isucon@app1

cd $(dirname $(readlink -f $0))
source ./tools/util.sh


if [ "${1:-}" = "-h" ]
then
	echo "Usage: $0 [git branch]" 2>&1
	exit 1
fi

if [ "${TMUX:-}" = "" ]
then
	echo "Please run this in a tmux session" >&2
	exit 1
fi

if [ $# -le 0 ]
then
	info "Branch is not specified.  Please choose:"
	select c in $(git ls-remote --heads origin | awk '{print $2}')
	do
		[ -n "$c" ] && break
	done
	BRANCH=$(basename $c)
else
	BRANCH=$1
fi

PRECOMMAND=""
info "git pull && git checkout $BRANCH"
PRECOMMAND="cd ~/isucon11q/ && git fetch --all && git checkout $BRANCH && git pull &&"

info "Execute init.sh"
if [ -n "${TMUX:-}" ]
then
	tmux set-window-option synchronize-panes 0
	xpanes -x -s -c "ssh {} -t '$PRECOMMAND init.sh'; read -p 'Press enter to continue> ' && exit"  $HOSTS
	tmux set-window-option synchronize-panes 1
	read -p 'Press enter to continue> '
else
	xpanes -s -c "ssh {} -t '$PRECOMMAND init.sh'; read -p 'Press enter to continue> ' && exit"  $HOSTS
fi

info "Execute benchmark"
# Some commands to run a benchmark (e.g., curl ...)
ssh -T isucon@app1 'cd ~/isuumo/bench/ && ./bench' &

tmux set-window-option synchronize-panes 0
xpanes -x -s -c "echo 'Waiting for stopping logger...' && grep -m 1 'Successfully stopped logging' <(ssh -T {} 'journalctl -f -n 0 2>&1') && rsync -Cva {}:~/isucon11q/tools/log ~/ && exit"  $HOSTS
tmux set-window-option synchronize-panes 1
read -p 'Press enter to continue> '
make -C ~/

