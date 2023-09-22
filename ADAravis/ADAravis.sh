#!/bin/bash

##########################################################################
##### install script for ADAravis support module##########################
##########################################################################

# ARGUMENTS:
#  $1 VERSION to install (must match repo tag)
VERSION=${1}
NAME=ADAravis

# log output and abort on failure
set -xe

# install required system dependencies
ibek support apt-install --only=dev \
    libboost-all-dev \
    libxext-dev \
    libglib2.0-dev \
    libusb-1.0 \
    libxml2-dev \
    libx11-dev \
    meson \
    intltool \
    pkg-config \
    xz-utils

# declare packages for installation in the Dockerfile's runtime stage
ibek support apt-install --only=run libglib2.0-bin libusb-1.0 libxml2

# build aravis library
(
    cd /usr/local &&
    git clone -b ARAVIS_0_8_1 --depth 1 https://github.com/AravisProject/aravis &&
    cd aravis &&
    meson build &&
    cd build &&
    ninja &&
    ninja install &&
    rm -fr /usr/local/aravis
    echo /usr/local/lib64 > /etc/ld.so.conf.d/usr.conf &&
    ldconfig
    # is this necessary?
    pip install telnetlib3
)

# get the source and fix up the configure/RELEASE files
ibek support git-clone ${NAME} ${VERSION}
ibek support register ${NAME}

# declare the libs and DBDs that are required in ioc/iocApp/src/Makefile
ibek support add-libs ADAravis
ibek support add-dbds ADAravisSupport.dbd

# add any required changes to CONFIG_SITE
CONFIG='
AREA_DETECTOR=$(SUPPORT)
CROSS_COMPILER_TARGET_ARCHS =
GLIBPREFIX=/usr
USR_INCLUDES += -I$(GLIBPREFIX)/include/glib-2.0
USR_INCLUDES += -I$(GLIBPREFIX)/lib/x86_64-linux-gnu/glib-2.0/include/
glib-2.0_DIR = $(GLIBPREFIX)/lib/x86_64-linux-gnu
ARAVIS_INCLUDE  = /usr/local/include/aravis-0.8/
'

ibek support add-to-config-site ${NAME} "${CONFIG}"

# TODO may need
#    ioc_SYS_LIBS += aravis-0.8
# in the Makefile

# compile the support module
ibek support compile ${NAME}

# prepare *.bob, *.pvi, *.ibek.support.yaml for access outside the container.
ibek support generate-links ${NAME}

