#!/bin/sh -eux

if [[ "$PACKER_BUILDER_TYPE" == amazon* || "$PACKER_BUILDER_TYPE" == openstack* ]]; then

    if grep -q -i "CentOS release 6" /etc/redhat-release; then
        # official centos 6 AMI is 6.5
        yum clean all
        yum distro-sync --releasever=6.7 -y

        # the centos 6 image doesn't include cloud-init and
        # cloud-utils-growpart is in epel instead of extras
        yum install -y epel-release
        yum clean all

        yum install -y cloud-init cloud-utils-growpart dracut-modules-growroot
        # force initramfs rebuild
        # https://ask.openstack.org/en/question/58438/partition-is-not-expanding-even-with-cloud-init-during-first-boot/
        # we may have just installed a newer kernel than is running but will
        # used for the next boot
        KERNEL=`rpm -q kernel | sort -V | tail -n1 | sed -r 's/^kernel-(.+)/\1/'`
        dracut -f /boot/initramfs-${KERNEL}.img $KERNEL
        lsinitrd /boot/initramfs-${KERNEL}.img | grep grow

        yum erase -y epel-release
        yum clean all
    fi

    if grep -q -i "CentOS Linux release 7" /etc/redhat-release; then
        # official centos 7 AMI is 7.0.1406
        yum clean all
        yum distro-sync --releasever=7.1.1503 -y

        yum install -y cloud-init cloud-utils-growpart

        yum clean all
    fi

    /usr/sbin/groupadd vagrant
    /usr/sbin/useradd -d /home/vagrant -s /bin/bash -g vagrant -m vagrant

    # check for centos 6 manual ssh key setup
    if grep -q 169.254.169.254 /etc/rc.local; then
        # remove it...
        cat > /etc/rc.local <<END
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
    sed -i -e 's/name: fedora/name: vagrant/' /etc/cloud/cloud.cfg

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
