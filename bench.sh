#!/bin/bash -eu

HOSTS=$(echo isucon@app{1,2,3})

if [ "${1:-}" = "-h" ]
then
	echo "Usage: $0 [git branch]" 2>&1
	exit 1
fi

cd $(dirname $(readlink -f $0))
source ./tools/util.sh

if [ $# -ge 1 ]
then
	BRANCH=$1
	info "git pull && git checkout $BRANCH"
	git pull && git checkout $BRANCH
fi

info "Execute init.sh"
xpanes -c "ssh {} -t 'init.sh'; read -p 'Press enter to continue> ' && exit"  $HOSTS

info "Execute benchmark"
# curl ...
ssh isucon@app1 -t 'cd ~/isuumo/bench/ && ./bench'

