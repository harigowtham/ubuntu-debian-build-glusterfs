#!/bin/bash

#OS (e.g. Ubuntu/Debian)
#Series (e.g. 4.1)
#Version (e.g. 4.1.0)
#Release (e.g. 1)
#Flavor(e.g. Ubuntu - xenial/bionic/cosmic/disco/eoan, Debian - buster/stretch/bullseye)

# to run use: 'bash build.sh debian stretch 6 4.1.0 1'

os=$1
flavor=$2
series=$3
version=$4
release=$5

#Keys required in debian builds
declare -a debuild_keys
debuild_keys=("8B7C364430B66F0B084C0B0C55339A4C6A7BD8D4",
              "55F839E173AC06F364120D46FA86EEACB306CEE1",
              "32F8E2FDBE1460F94A62407E468C889BEEDF12A8",
              "F9C958A3AEE0D2184FAD1CBD43607F0DC2F8238C")

declare -a pbuild_keys
pbuild_keys=("7F6E5563", "EFCE7625", "4061252D", "BF11C87C")

# Check for OS(Ubuntu or Debian)
if [ "$os" == "ubuntu" ]; then
        mirror="http://ubuntu.osuosl.org/ubuntu/"
	debuild_key=4F5B5CA5
elif [ "$os" == "debian" ]; then
        mirror="http://ftp.us.debian.org/debian/"
	case ${series} in
	  "3.12")
    	    debuild_key=${debuild_keys[0]}
    	    pbuild_key=${pbuild_keys[0]}
    	    ;;
  	  "4.0")
            debuild_key=${debuild_keys[1]}
            pbuild_key=${pbuild_keys[1]}
            ;;
          "4.1")
            debuild_key=${pbuild_keys[2]}
            pbuild_key=${pbuild_keys[2]}
            ;;
          "5" | "6" | "7")
            debuild_key=${pbuild_keys[3]}
            pbuild_key=${pbuild_keys[3]}
        esac
else
	echo "Exiting: OS should be debian or ubuntu. Please provide the right one"
	exit
fi

mkdir ${os}-${flavor}-Glusterfs-${version}

cd ${os}-${flavor}-Glusterfs-${version}

mkdir build packages

echo "Building glusterfs-${version}-${release} for ${flavor}"

cd build

TGZS=(`ls ~/glusterfs-${version}-?-*/build/glusterfs-${version}.tar.gz`)
echo ${TGZS[0]}

if [ -z ${TGZS[0]} ]; then
        echo "wget https://download.gluster.org/pub/gluster/glusterfs/${series}/${version}/glusterfs-${version}.tar.gz"
        wget https://download.gluster.org/pub/gluster/glusterfs/${series}/${version}/glusterfs-${version}.tar.gz
else
        echo "found ${TGZS[0]}, using it..."
        cp ${TGZS[0]} .
fi

ln -s glusterfs-${version}.tar.gz glusterfs_${version}.orig.tar.gz

echo "Untaring.."
tar xpf glusterfs-${version}.tar.gz
ls

# Changelogs needed for building are maintained in a separate repo.
# the repo has to be clone and updated properly so we can copy the changelogs so far.

echo "Cloning the glusterfs-debian repo"

git clone https://github.com/gluster/glusterfs-debian.git

cd glusterfs-debian/

git checkout -b ${flavor}-${series}-local origin/${flavor}-glusterfs-${series}

sed -i "1s/^/glusterfs (${version}-${os}1~${flavor}1) ${flavor}; urgency=medium\n\n  * GlusterFS ${version} GA\n\n -- GlusterFS GlusterFS deb packages <deb.packages@gluster.org>  `date +"%a, %d %b %Y %T %z"` \n\n" debian/changelog

git commit -a -m "Glusterfs ${version} G.A (${flavor})"

echo "Pushing Changelog changes.."
#git push origin ${flavor}-${series}-local:${flavor}-glusterfs-${series}

echo "Copying Changelog to source"
cp -a debian ../glusterfs-${version}/

echo "Building source package.."
cd ../glusterfs-${version}

#Running debuild on the source code.
#debuild -S -sa -k${debuild_key}
debuild -us -uc

echo "creating chroot for ${os} ${flavor}"
sudo pbuilder create --distribution ${flavor} --mirror ${mirror} --debootstrapopts --keyring=/usr/share/keyrings/${os}-archive-keyring.gpg

echo "Building glusterfs-${version} for ${os} ${flavor} using the chroot and .dsc we created"

# have to use the .dsc file inside the ${os}${flavor} folder
cd ../../
sudo pbuilder --build --distribution ${flavor} --debootstrapopts --keyring=/usr/share/keyrings/${os}-archive-keyring.gpg glusterfs_${version}-${os}1~${flavor}1.dsc

#move the packages to packages directory.
mv build/glusterfs-*.deb packages/

echo "removing the chroot"
rm -rf /var/cache/pbuilder/base.tgz

echo "removing the unnecessary files"
rm -rf build/glusterfs-${version}.tar.gz build/glusterfs_${version}.orig.tar.gz
#check which are the files not necessary and delete them.
#remove the source package and other such files
#sign it
#push it
echo "Done."
