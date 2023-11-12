#!/bin/sh

GO_VERSION=go121

createuser() {
	if userinfo -e $1; then
		echo "==> User $1 already exists." >&2
	else
		echo "==> Creating user $1." >&2
		useradd -m -p '*' $1
	fi
}

make_dir() {
	dir=$1
	shift
	if [ -e $dir ]; then
		echo "==> Directory $dir already exists." >&2
	else
		echo "==> Creating directory $1." >&2
		install -d $* $dir
	fi
}



install_go_bin() {
	echo "==> Installing $1." >&2
	env GOBIN=/usr/local/bin go install -v $1@latest
}

###############################

make_dir /usr/local/bin
make_dir /usr/local/sbin

createuser swarming
createuser lucitoken

install_go_bin golang.org/x/build/cmd/genbotcert
install_go_bin golang.org/x/build/cmd/bootstrapswarm
install_go_bin go.chromium.org/luci/tokenserver/cmd/luci_machine_tokend

make_dir /var/lib/luci_machine_tokend -o lucitoken

if [ -e /service ]; then
	echo "==> Directory /service already exists." >&2
else
	echo "==> Installing directory /service."
	pax -rw -pp service /
fi

if grep -q "Go builder settings" /etc/rc.conf; then
	echo "==> /etc/rc.conf already contains Go builder settings."
else
	echo "==> Installing Go builder settings to /etc/rc.conf, please verify!"
	cat rcd/rc.conf >> /etc/rc.conf
fi