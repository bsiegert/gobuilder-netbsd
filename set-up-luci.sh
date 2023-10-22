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
install_go_bin go.chromium.org/luci/tokenserver/cmd/luci_machine_tokend
install_go_bin golang.org/x/build/cmd/bootstrapswarm

make_dir /var/lib/luci_machine_tokend -o lucitoken
