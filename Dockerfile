# Install ubuntu 22.04
FROM ubuntu:22.04

# Arguments
ARG user=pwner
ARG passwd=pwner
ARG group=pwner
ARG uid=3141
ARG gid=3141
ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Etc/UTC

# Unminimize image and install essential tools and deps
# dpkg --add-architecture i386 && install *:i386 for 32bit binary execution support
RUN dpkg --add-architecture i386
RUN yes | unminimize
RUN apt -y update && apt install -y \
    ubuntu-minimal \
    ubuntu-dev-tools \
    vim \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python2 \
    python2-dev \
    libssl-dev \
    libffi-dev \
    libglib2.0-dev \
    libseccomp-dev \
    libc6-dbg \
    build-essential \
    nghttp2 \
    libnghttp2-dev \
    gdb \
    gdbserver \
    wget \
    curl \
    ssh \
    gcc \
    make \
    git \
    sudo \
    libc6:i386 \
    libc6-dbg:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
    libseccomp-dev:i386 \
    ca-certificates \
    pkg-config \
    strace \
    ltrace \
    htop \
    psmisc \
    screen \
    file \
    gawk \
    hexdiff \
    upx-ucl \
    net-tools \
    netcat \
    socat \
    ruby-full \
    zsh \
    man \
    man-db \
    apt-file \
    && rm -rf /var/lib/apt/lists/*

# Set apt-file cache
RUN apt-file update

# Configure /usr/bin/python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 1
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 2

# Install Pwntools
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install --upgrade pwntools

# Set nopassword for sudo for the installation
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Create user so not all the shabang goes on root
RUN groupadd -g ${gid} ${group} && useradd -rm -s /bin/zsh -g ${gid} -G sudo -u ${uid} ${user} && echo "${user}:${passwd}" | chpasswd
USER ${user}
WORKDIR /home/${user}

# Create user "Source" dir
RUN mkdir /home/${user}/Source

# Create dir for tools under opt and cd
RUN sudo mkdir /opt/tools
RUN sudo chown ${uid}:${gid} /opt/tools
WORKDIR /opt/tools

# Install Pwndbg + GEF + Peda
RUN git clone https://github.com/RoiKlevansky/gdb-peda-pwndbg-gef.git
WORKDIR gdb-peda-pwndbg-gef
RUN ./install.sh /opt/tools

# Radare2
WORKDIR /opt/tools
RUN git clone https://github.com/radare/radare2 
RUN ./radare2/sys/install.sh

# r2pm and plugins & r2dec plugin install
RUN r2pm init
RUN r2pm install r2dec

# Pwntools-ruby
RUN sudo gem install pwntools

# one-gadget
RUN sudo gem install one_gadget

# ROPgadget
RUN sudo -H python3 -m pip install ROPgadget

# Install oh-my-zsh
WORKDIR /home/${user}
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.2/zsh-in-docker.sh)" -- \
    -p git \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting

# Set GNU Screen to use zsh
RUN echo 'shell "/usr/bin/zsh"' > ~/.screenrc

# Remove nopasswd from sudo
RUN sudo sed -i '$ d' /etc/sudoers

