#!/bin/bash -eu

HOSTS=$(echo app{1,2,3})
cd $(dirname $(readlink -f $0))
source ./tools/util.sh

tmux set-window-option synchronize-panes 0
xpanes -x -s -c "rsync -Cva {}:~/isucon11q/tools/log ~/ && exit"  $HOSTS
tmux set-window-option synchronize-panes 1
read -p 'Press enter to continue> '
make -j 4 -C ~/ >/dev/null 2>&1 &

