FROM centos:7

RUN yum -y update && yum -y install gcc git autoconf automake libtool perl-core zlib-devel make yum-utils wget unzip doxygen graphviz xsltproc python3 python3-pip  && yum check-update

RUN pip3 install -U pytest nose rednose pytest-xdist

# liboqs requires better gcc than default 4.8:
RUN yum -y remove gcc
RUN yum -y install centos-release-scl
RUN yum -y install devtoolset-8-gcc*
RUN yum -y install libtool
RUN echo "source /opt/rh/devtoolset-8/enable" >> /root/.bashrc

WORKDIR /root
RUN git clone --single-branch --branch master https://github.com/open-quantum-safe/liboqs && \
    git clone --single-branch --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl;

# install liboqs
WORKDIR /root/liboqs
RUN source /opt/rh/devtoolset-8/enable && \
    autoreconf -i && \
    ./configure --prefix=/usr/local --without-openssl && \
    make -j && \
    make install;

# install OQS-OpenSSL 1.1.1
WORKDIR /root/openssl
RUN source /opt/rh/devtoolset-8/enable && \
    ./config --prefix=/usr/local && \
    make -j && \
    make install;

# add dynamic loader search paths
RUN echo '/usr/local/lib' > /etc/ld.so.conf.d/oqs.conf && \
    echo '/usr/local/lib64' > /etc/ld.so.conf.d/oqs-openssl.conf && \
    ldconfig -v;

CMD ["/bin/bash"]
