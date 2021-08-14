#!/bin/bash

usage_exit() {
	echo "Usage: $0 [-u USERNAME] SSH_TARGET" >&2
	echo "       SSH_TARGETに対して設定ファイルを転送して末尾に加える。"
	exit 1
}

TARGET_USER=""
while getopts u:h OPT
do
	case $OPT in
		u)  TARGET_USER=$OPTARG
			;;
		h)  usage_exit
			;;
		\?) usage_exit
			;;
	esac
done

shift $((OPTIND - 1))

#[ $# -ne 1 ] && usage_exit



TARGET=$1

set -eux

cd $(dirname $0)

echo "SSH Target: $TARGET"
echo "User: $TARGET_USER"

shopt -s extglob
LIST=!(*.sh)
echo "File List: $LIST"


if [ "$TARGET" = "" ]
then
	echo -n "Are you sure to rewrite the setting files of this computer? Y/n>"
	read OK; [ "$OK" = "n" ] && exit
	bash -c "for i in $(echo $LIST); do cat \$i >> ~/.\$i; done"
elif [ "$TARGET_USER" = "" ]
then
	scp $LIST $1:~/
	ssh $1 -t "for i in $(echo $LIST); do cat \$i >> ~/.\$i && rm \$i; done"
else
	scp $LIST $1:~/
	ssh $1 -t "sudo su $TARGET_USER -c 'for i in $(echo $LIST); do cat \$i >> ~/.\$i; done' && rm $(echo $LIST)"
fi

