FROM ubuntu:18.04

ENV RISCV=/opt/riscv
ENV PATH=$RISCV/bin:$PATH
WORKDIR $RISCV

# required to install tzdata, used by qemu
RUN export DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# compiling the toolchain
RUN apt-get update
RUN apt-get install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential \
  bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
RUN apt-get install -y git
RUN git clone https://github.com/riscv/riscv-gnu-toolchain
WORKDIR $RISCV/riscv-gnu-toolchain
RUN git submodule update --init --recursive
RUN ./configure --prefix=/opt/riscv --disable-linux --with-arch=rv32im --with-abi=ilp32 --enable-multilib
RUN make -j4 && make install

# compiling qemu
RUN apt-get -y update && \
    apt-get -y install apt-transport-https ca-certificates curl software-properties-common && \
    apt-get -y install git cmake pkg-config valgrind && \
    apt-get install -y tzdata
# bigger packages
RUN apt-get -y install libglib2.0-dev zlib1g libpixman-1-dev libsdl1.2-dev libgtk3.0-cil-dev libvte-dev && \
    apt-get purge -y --auto-remove
RUN dpkg-reconfigure --frontend noninteractive tzdata
RUN cd qemu && ./configure --extra-cflags="-w" --enable-debug --target-list="riscv32-softmmu"
RUN make -j4 && make install && cd ..

RUN apt-get update && apt-get install -y gosu
WORKDIR /usr/local/bin
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
