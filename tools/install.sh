#!/bin/bash -eu
# install apt and go if not exists

cd $(dirname $0)

make_symlink() {
	TARGET_PATH=$1
	for bin in $(find /usr/local/go/bin -type f)
	do
		TARGET="$TARGET_PATH/$(basename "$bin")"
		[ -f $TARGET ] && sudo mv $TARGET "$TARGET"_old
		sudo cp --symbolic-link $bin $TARGET_PATH
	done
}

install_go() {
	TARGET_PATH=/usr/bin
        if which go > /dev/null 2>&1; then
            TARGET_PATH=$(dirname $(which go))
        fi
	(
		cd /tmp
		rm -rf ./update-golang
		git clone https://github.com/udhos/update-golang
		cd update-golang
    # installed to /usr/local/go
		sudo ./update-golang.sh
	)
}

install_alp() {
	TARGET_PATH=/usr/bin
	which alp >/dev/null 2>&1 && return
	(
		echo "# Install alp"
		cd /tmp
		wget https://github.com/tkuchiki/alp/releases/download/v1.0.7/alp_linux_amd64.zip
		unzip alp_linux_amd64.zip
		sudo mv alp $TARGET_PATH
	)
}

install_myprofiler() {
	TARGET_PATH=/usr/bin
	which myprofiler >/dev/null 2>&1 && return
	(
		echo "# Install myprofiler"
		cd /tmp
		wget https://github.com/KLab/myprofiler/releases/download/0.1/myprofiler.linux_amd64.tar.gz
		tar xf myprofiler.linux_amd64.tar.gz
		sudo mv myprofiler $TARGET_PATH
	)
}


echo "# Install several tools by apt"
sudo DEBIAN_FRONTEND=noninteractive apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y git pv dstat unzip graphviz python3-mysqldb percona-toolkit

install_alp
install_myprofiler
install_go
