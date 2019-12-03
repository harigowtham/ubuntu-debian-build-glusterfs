# ubuntu-debian-build-glusterfs
A repo to build various versions of debian and ubuntu packages on ubuntu using the chroot environment provided by pbuilder.

The script is supposed to be run on a Jenkins' builder.
The Jenkins' builder setup will be done as an ansible script that will be added later.

The ansible script is supposed to:
Install the dependencies:  build-essential pbuilder devscripts reprepro debhelper dpkg-sig  debootstrap chrpath
SSH keys to be added to github.
Clone and set the username and email address on the machine.
copy the key in a way its safe: - `deb.packages.dot-gnupg.tgz`: has the ~/.gnupg dir with the keyring needed to build & sign packages
check Semiosis' github for any changes he has made:
https://github.com/semiosis/glusterfs-debian/tree/stretch-glusterfs-3.5/debian

The mirror for raspbian: http://archive.raspbian.org/raspbian/ 
The keyring for raspbian: keyring=/usr/share/keyrings/raspbian-archive-keyring.gpg"

The last step would be to add the script file in the machine.
