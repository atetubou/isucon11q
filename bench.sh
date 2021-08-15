#!/bin/bash -eu

#HOSTS=$(echo isucon@app{1,2,3})
HOSTS=isucon@app1

if [ "${1:-}" = "-h" ]
then
	echo "Usage: $0 [git branch]" 2>&1
	exit 1
fi

cd $(dirname $(readlink -f $0))
source ./tools/util.sh

PRECOMMAND=""
if [ $# -ge 1 ]
then
	BRANCH=$1
	info "git pull && git checkout $BRANCH"
	PRECOMMAND="cd ~/isucon11q/ && git fetch --all && git checkout $BRANCH && git pull &&"
fi

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
# curl ...
ssh -T isucon@app1 'cd ~/isuumo/bench/ && ./bench' &
for h in $HOSTS
do
	grep -m 1 "Successfully stopped logging" <(ssh -T $h 'journalctl -f -n 0 2>&1')
	rsync -Cva $h:~/isucon11q/tools/log ~/
done

