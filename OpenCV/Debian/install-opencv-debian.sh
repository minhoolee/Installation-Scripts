#! /bin/sh
# Install script for the latest version of OpenCV with python support and the extra modules added
# If installing with python, make sure to start the virtualenv before running the script
# For Debian only; untested

# Written by Min Hoo Lee
# February 1, 2017 (2/1/17)

# Exit script on failure
set -e

echo "\n*** OpenCV Install Script for Ubuntu by Min Hoo Lee ***\n"

PYTHON=false
EXTRA=false
SAMPLES=false

# Acquire user input
while true; do
    read -p "Do you wish to install with python support? (y/n [n]) " yn
    case $yn in
        [Yy]* ) 
            PYTHON=true;
            while true; do
                read -p "Which version of python [2.7/3.5] " v
                case $v in
                    [2.7]* ) PYTHON_VERSION=2.7; break;;
                    [3.5]* ) PYTHON_VERSION=3.5; break;;
                    * ) echo "Please enter the python version.";;
                esac
            done
            break;;
        [Nn]* ) break;;
        [A-Za-z]* ) echo "Please answer y or n";;
        * ) break;;
    esac
done

while true; do
    read -p "Do you wish to install with the extra opencv_contrib modules? (y/n [n]) " yn
    case $yn in
        [Yy]* ) EXTRA=true; break;;
        [Nn]* ) break;;
        [A-Za-z]* ) echo "Please answer y or n";;
        * ) break;;
    esac
done

while true; do
    read -p "Do you wish to build OpenCV samples? (y/n [n]) " yn
    case $yn in
        [Yy]* ) SAMPLES=true; break;;
        [Nn]* ) break;;
        [A-Za-z]* ) echo "Please answer y or n";;
        * ) break;;
    esac
done

echo "\n*** Installing dependencies... ***\n"
# Developer tools
sudo apt-get install git build-essential cmake pkg-config wget

# File I/O
sudo apt-get install libjpeg8-dev libtiff5-dev libjasper-dev libpng12-dev

# Video I/O
sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev

# GUI (gtk)
sudo apt-get install libgtk-3-dev

# Optimization (BLAS)
sudo apt-get install libatlas-base-dev gfortran liblapacke-dev

# Python headers
sudo apt-get install python2.7-dev python3.5-dev

echo "\n\n*** Downloading the latest version of OpenCV... ***\n"
git clone https://github.com/opencv/opencv.git
cd opencv
# Grab the latest version of OpenCV
TAG=`git describe --abbrev=0 --tags`

git checkout $TAG
mkdir build
cd build

if [[ $EXTRA == true ]]; then
    # Grab the latest version of the OpenCV extra modules
    git clone https://github.com/opencv/opencv_contrib.git
    git --git-dir=opencv_contrib/.git --work-tree=opencv_contrib checkout $TAG
fi

echo "\n\n*** Installing OpenCV $TAG" | tr -d '\n'

CMAKE_CMD="cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local/ \
    -D WITH_LIBV4L=ON"

# Configure cmake options for OpenCV based off of user input
if [[ $PYTHON == true ]]; then 
    echo " with Python" | tr -d '\n'
    CMAKE_CMD=$CMAKE_CMD" -D PYTHON_EXECUTABLE=`which python`"
    case $PYTHON_VERSION in
        [2.7]* ) 
            CMAKE_CMD=$CMAKE_CMD" -D BUILD_opencv_python2=ON \
                -D BUILD_opencv_python3=OFF"; break;;
        [3.5]* ) 
            CMAKE_CMD=$CMAKE_CMD" -D BUILD_opencv_python2=OFF \
                -D BUILD_opencv_python3=ON"; break;;
        * ) break;;
    esac
fi
if [[ $EXTRA == true ]]; then
    echo " and the Extra Modules" | tr -d '\n'
    CMAKE_CMD=$CMAKE_CMD" -D OPENCV_EXTRA_MODULES_PATH=opencv_contrib/modules"
fi
if [[ $SAMPLES == true ]]; then
    echo " and OpenCV samples" | tr -d '\n'
    CMAKE_CMD=$CMAKE_CMD" -D BUILD_EXAMPLES=ON"
fi

CMAKE_CMD=$CMAKE_CMD" .."
echo "...\n"
echo $CMAKE_CMD

# Execute the cmake command
$CMAKE_CMD

make -j$(nproc)
sudo make install
sudo ldconfig

SITE_PACKAGES=`python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"`

if [[ $PYTHON_VERSION == "2.7" ]]; then
    ln -s /usr/local/lib/python2.7/site-packages/cv2.so  $SITE_PACKAGES/cv2.so
elif [[ $PYTHON_VERSION == "3.5" ]]; then
    ln -s /usr/local/lib/python3.5/site-packages/cv2.so  $SITE_PACKAGES/cv2.so
fi

echo "\n\n*** Installation was successful! ***\n"
