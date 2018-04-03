# This file is part of the bladeRF project:
#   http://www.github.com/nuand/bladeRF
#
# Copyright (c) 2018 Nuand LLC.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

FROM fedora:latest

LABEL maintainer="Nuand LLC <bladeRF@nuand.com>"
LABEL version="0.0.2"
LABEL description="CI build environment for the bladeRF project"
LABEL com.nuand.ci.distribution.name="Fedora"

# Install things
RUN yum groupinstall -y "Development Tools" \
 && yum install -y \
    clang \
    cmake \
    doxygen \
    help2man \
    hostname \
    libusbx \
    libusbx-devel \
    pandoc \
    wget \
 && yum clean all \
 && rm -rf /var/cache/yum \
 && echo "/usr/local/lib" > /etc/ld.so.conf.d/locallib.conf \
 && echo "/usr/local/lib64" >> /etc/ld.so.conf.d/locallib.conf

# Fedora lacks libtecla packages, so download and build.
RUN (curl http://www.astro.caltech.edu/~mcs/tecla/libtecla.tar.gz | tar xzf -) \
 && cd libtecla \
 && CC=gcc ./configure \
 && make \
 && make install \
 && cd .. \
 && rm -rf libtecla

# Copy in our build context
WORKDIR /root
COPY --from=nuand/bladerf-buildenv:base /root/bladeRF /root/bladeRF

# Build arguments
ARG compiler=gcc
ARG buildtype=Release
ARG taggedrelease=NO

# Do the build!
RUN cd /root/bladeRF/ \
 && mkdir -p build \
 && cd build \
 && cmake \
        -DBUILD_DOCUMENTATION=ON \
        -DCMAKE_C_COMPILER=${compiler} \
        -DCMAKE_BUILD_TYPE=${buildtype} \
        -DENABLE_FX3_BUILD=OFF \
        -DENABLE_HOST_BUILD=ON \
        -DTAGGED_RELEASE=${taggedrelease} \
    ../ \
 && make -j$(nproc) \
 && make install \
 && ldconfig
