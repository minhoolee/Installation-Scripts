#! /bin/bash
# Installation script for Protobuf
# Builds by source and allows user to select version number (if valid)
# For Ubuntu only; untested

# Written by Min Hoo Lee
# August 10, 2017 (8/1/17)

# Exit script on failure
set -e

# Allow bash to interpret new line characters for echo
shopt -s xpg_echo

# Compares two versions with dots as delimiters
# Returns "=", ">", or "<", default is "="
vercomp () {
    if [[ $1 == $2 ]]
    then
        echo "="
        return
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            echo ">"
            return
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            echo "<"
            return
        fi
    done
    echo "="
}

echo "\n*** Protobuf Install Script for Ubuntu by Min Hoo Lee ***\n"

echo "\n*** Installing dependencies... ***\n"
sudo apt-get install git build-essential cmake pkg-config wget -yf
sudo apt-get install autoconf automake libtool curl make g++ unzip -yf

echo "\nHere is the list of protobuf versions (refs/tags/v...)\n"
git ls-remote --tags https://github.com/google/protobuf
echo "\n"

TAG=""

# Acquire user input
while true; do
    read -p "Which version of protobuf do you wish to install? \
      (e.g. \"2.5.0\", \"3.3.0\"): " TAG
    if [[ `git ls-remote https://github.com/google/protobuf \
      refs/tags/v$TAG` ]]; then
       break
    fi
done

echo "\n\n*** Downloading Protobuf $TAG... ***\n"
git clone https://github.com/google/protobuf.git
cd protobuf
git checkout "v$TAG"

echo "\n\n*** Installing Protobuf $TAG... ***\n"

# Protobof versions before 3.0.0 have broken links
if [[ `vercomp $TAG 3.0.0` == "<" ]]; then
    curl https://raw.githubusercontent.com/google/protobuf/3.0.x/autogen.sh > autogen.sh
    chmod +x autogen.sh
    ./autogen.sh
fi

# Protobof versions before 3.0.0 have broken links
# Extract version number and replace the googletest link
V=`grep googletest autogen.sh | grep -o '[0-9].[0-9].[0-9]'`
S="curl http://googletest.googlecode.com/files/gtest-$V.tar.bz2 | tar jx"
R="curl -L \
https://github.com/google/googletest/archive/release-$V.tar.gz | tar xz"
if [[ `vercomp $TAG 3.0.0` == "<" ]]; then
    sed -i'' -e "s@$S@$R@g" autogen.sh
    sed -i'' -e "s@gtest-$V@googletest-release-$V@g" autogen.sh
fi

./autogen.sh
./configure
make -j$(nproc)
make check
sudo make install
sudo ldconfig

echo "\n\n*** Installation was successful! ***\n"
protoc --version
