#!/bin/sh -eux

if [[ "$PACKER_BUILDER_TYPE" == amazon* ]]; then
    groupadd vagrant
    useradd -d /home/vagrant -s /bin/bash -g vagrant -m vagrant

    # the centos 6 image doesn't include cloud-init
    yum install -y cloud-init

    # check for centos 6 manual ssh key setup
    grep 169.254.169.254 /etc/rc.local
    if test $? -eq 0; then
        # remove it...
        cat > /etc/rc.local <END
#!/bin/sh
#
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.

touch /var/lock/subsys/local
END
    fi

    # change cloud-init default user to vagrant
    sed -i -e 's/name: centos/name: vagrant/' /etc/cloud/cloud.cfg

    # sudo
    sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
else

# set a default HOME_DIR environment variable if not set
HOME_DIR="${HOME_DIR:-/home/vagrant}";

pubkey_url="https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub";
mkdir -p $HOME_DIR/.ssh;
if command -v wget >/dev/null 2>&1; then
    wget --no-check-certificate "$pubkey_url" -O $HOME_DIR/.ssh/authorized_keys;
elif command -v curl >/dev/null 2>&1; then
    curl --insecure --location "$pubkey_url" > $HOME_DIR/.ssh/authorized_keys;
elif command -v fetch >/dev/null 2>&1; then
    fetch -am -o $HOME_DIR/.ssh/authorized_keys "$pubkey_url";
else
    echo "Cannot download vagrant public key";
    exit 1;
fi
chown -R vagrant $HOME_DIR/.ssh;
chmod -R go-rwsx $HOME_DIR/.ssh;

fi
