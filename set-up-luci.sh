#!/bin/sh

GO_VERSION=go123

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
		echo "==> Creating directory $dir." >&2
		install -d $* $dir
	fi
}

copy_file() {
	src=$1
	dest=$2
	srcfile=`basename $1`
	if [ -e $dest/$srcfile ]; then
		echo "==> file $dest/$srcfile already exists." >&2
	elif [ ! -e $src ]; then
		echo "==> missing file $src!" >&2
	else
		echo "==> copying $src to $dest." >&2
		cp $src $dest
	fi
}

install_go_bin() {
	echo "==> Installing $1." >&2
	env GOBIN=/usr/local/bin go install -v $1@latest
}

###############################

echo "==> Installing useful packages." >&2
if [ -x /usr/pkg/bin/pkgin ]; then
	pkgin -y install emacs-nox11 watch estd screen sysupgrade bash go123 w3m vim llvm git-base htop sudo mosh pkg_alternatives clang daemontools daemontools-run node_exporter doas
else
	echo "pkgin not found, please install packages manually" >&2
fi


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
	echo "==> Installing directory /service." >&2
	pax -rw -pp service /
fi

copy_file /usr/pkg/share/examples/rc.d/svscan /etc/rc.d
copy_file /usr/pkg/share/examples/rc.d/node_exporter /etc/rc.d
chmod 555 /etc/rc.d/svscan
chmod 555 /etc/rc.d/node_exporter

copy_file rcd/newfs_scratch /etc/rc.d
chmod 555 /etc/rc.d/newfs_scratch

if grep -q "Go builder settings" /etc/rc.conf; then
	echo "==> /etc/rc.conf already contains Go builder settings." >&2
else
	echo "==> Installing Go builder settings to /etc/rc.conf, please verify!" >&2
	cat rcd/rc.conf >> /etc/rc.conf
fi

if grep -q "Go builder settings" /usr/pkg/etc/sudoers; then
	echo "==> /usr/pkg/etc/sudoers already contains Go builder settings." >&2
else
	echo "==> Installing Go builder settings to /usr/pkg/etc/sudoers, please verify!" >&2
	cat rcd/sudoers >> /usr/pkg/etc/sudoers
fi

. ./rcd/rc.conf
copy_file ${builder_name}.cert /home/lucitoken
copy_file ${builder_name}.key /home/lucitoken
chown lucitoken /home/lucitoken/${builder_name}.cert
chown lucitoken /home/lucitoken/${builder_name}.key
