#!/bin/bash -eu

HOSTS=$(echo app{1,2,3})
#HOSTS=isucon@app1

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
#ssh -T isucon@app1 'cd ~/isuumo/bench/ && ./bench' &
curl 'https://portal.isucon.net/api/contestant/benchmark_jobs' \
	-H 'authority: portal.isucon.net' \
	-H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
	-H 'accept: application/protobuf, application/vnd.google.protobuf, text/plain' \
	-H 'x-csrf-token: oyy+lSvZN/Lj1EhGEAVmbA0MqMrGdq2wDDpP32BkPoZxvapN2zZCavUf2sbFEgeO1fVWiZ1g/tLJh86lyfI+ug==' \
	-H 'sec-ch-ua-mobile: ?0' \
	-H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36' \
	-H 'content-type: application/vnd.google.protobuf' \
	-H 'origin: https://portal.isucon.net' \
	-H 'sec-fetch-site: same-origin' \
	-H 'sec-fetch-mode: cors' \
	-H 'sec-fetch-dest: empty' \
	-H 'referer: https://portal.isucon.net/contestant/benchmark_jobs' \
	-H 'accept-language: ja,en-US;q=0.9,en;q=0.8,ru;q=0.7' \
	-H 'cookie: __Host-isuxportal_sess=c83b91787912ca470a5e82bab7f2423e; _ga=GA1.2.819652436.1628859153; _gid=GA1.2.1935543190.1629376019' \
	--data-raw $'\u0008À\u0003' \
	--compressed &

tmux set-window-option synchronize-panes 0
xpanes -x -s -c "echo 'Waiting for stopping logger...' && grep -m 1 'Successfully stopped logging' <(ssh -T {} 'journalctl -f -n 0 2>&1') && rsync -Cva {}:~/isucon11q/tools/log ~/ && exit"  $HOSTS
tmux set-window-option synchronize-panes 1
read -p 'Press enter to continue> '
make -j 4 -C ~/

