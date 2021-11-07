FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04

USER root

### BASICS ###
# Technical Environment Variables
ENV \
    SHELL="/bin/bash" \
    HOME="/root"  \
    DEBIAN_FRONTEND="noninteractive"  \
    USER_GID=0 
RUN \
    # TODO add repos?
    # add-apt-repository ppa:apt-fast/stable
    # add-apt-repository 'deb http://security.ubuntu.com/ubuntu xenial-security main'
    apt-get update --fix-missing && \
    apt-get install -y sudo apt-utils && \
    apt-get upgrade -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    # This is necessary for apt to access HTTPS sources:
    apt-transport-https \
    gnupg-agent \
    gpg-agent \
    gnupg2 \
    ca-certificates \
    build-essential \
    pkg-config \
    software-properties-common \
    lsof \
    net-tools \
    libcurl4 \
    curl \
    wget \
    cron \
    openssl \
    psmisc \
    iproute2 \
    tmux \
    dpkg-sig \
    uuid-dev \
    csh \
    xclip \
    clinfo \
    time \
    libssl-dev \
    libgdbm-dev \
    libncurses5-dev \
    libncursesw5-dev \
    # required by pyenv
    libreadline-dev \
    libedit-dev \
    xz-utils \
    gawk \
    # Simplified Wrapper and Interface Generator (5.8MB) - required by lots of py-libs
    swig \
    # Graphviz (graph visualization software) (4MB)
    graphviz libgraphviz-dev \
    # Terminal multiplexer
    screen \
    # Editor
    nano \
    # Find files
    locate \
    # Dev Tools
    sqlite3 \
    # XML Utils
    xmlstarlet \
    # GNU parallel
    parallel \
    #  R*-tree implementation - Required for earthpy, geoviews (3MB)
    libspatialindex-dev \
    # Search text and binary files
    yara \
    # Minimalistic C client for Redis
    libhiredis-dev \
    # postgresql client
    libpq-dev \
    # mariadb client (7MB)
    # libmariadbclient-dev \
    # image processing library (6MB), required for tesseract
    libleptonica-dev \
    # GEOS library (3MB)
    libgeos-dev \
    # style sheet preprocessor
    less \
    # Print dir tree
    tree \
    # Bash autocompletion functionality
    bash-completion \
    # ping support
    iputils-ping \
    # Map remote ports to localhosM
    socat \
    # Json Processor
    jq \
    rsync \
    # sqlite3 driver - required for pyenv
    libsqlite3-dev \
    # VCS:
    git \
    subversion \
    jed \
    # odbc drivers
    unixodbc unixodbc-dev \
    # Image support
    libtiff-dev \
    libjpeg-dev \
    libpng-dev \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxext-dev \
    libxrender1 \
    libzmq3-dev \
    # protobuffer support
    protobuf-compiler \
    libprotobuf-dev \
    libprotoc-dev \
    autoconf \
    automake \
    libtool \
    cmake  \
    fonts-liberation \
    google-perftools \
    # Compression Libs
    # also install rar/unrar? but both are propriatory or unar (40MB)
    zip \
    gzip \
    unzip \
    bzip2 \
    lzop \
    # deprecates bsdtar (https://ubuntu.pkgs.org/20.04/ubuntu-universe-i386/libarchive-tools_3.4.0-2ubuntu1_i386.deb.html)
    libarchive-tools \
    zlibc \
    # unpack (almost) everything with one command
    unp \
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \ 
    # OpenMPI support
    libopenmpi-dev \
    openmpi-bin \
    # libartals
    liblapack-dev \
    libatlas-base-dev \
    libeigen3-dev \
    libblas-dev \
    # HDF5
    libhdf5-dev \
    # TBB   
    libtbb-dev \
    # TODO: installs tenserflow 2.4 - Required for tensorflow graphics (9MB)
    libopenexr-dev \
    # GCC OpenMP
    libgomp1 \
    # ttyd
    libwebsockets-dev \
    libjson-c-dev \
    libssl-dev \
    # data science
    libopenmpi-dev \
    openmpi-bin \
    libomp-dev \
    libopenblas-base \
    # ETC
    vim && \
    # Update git to newest version
    add-apt-repository -y ppa:git-core/ppa  && \
    apt-get update && \
    apt-get install -y --no-install-recommends git
    
RUN apt-get update && apt-get install -y \
    python3.7 \
    python3-pip \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    ffmpeg

ENV APP_HOME /test_code
WORKDIR $APP_HOME

COPY requirements.txt .

RUN pip3 install --upgrade pip setuptools

RUN pip3 install -r requirements.txt

COPY . .
## Install ttyd. (Not recommended to edit)
RUN \
    wget https://github.com/tsl0922/ttyd/archive/refs/tags/1.6.2.zip \
    && unzip 1.6.2.zip \
    && cd ttyd-1.6.2 \
    && mkdir build \ 
    && cd build \
    && cmake .. \
    && make \
    && make install

### END DEV TOOLS ###

# Make folders (Not recommended to edit)
ENV WORKSPACE_HOME="/workspace"
RUN \
    if [ -e $WORKSPACE_HOME ] ; then \
    chmod a+rwx $WORKSPACE_HOME; \   
    else \
    mkdir $WORKSPACE_HOME && chmod a+rwx $WORKSPACE_HOME; \
    fi
ENV HOME=$WORKSPACE_HOME
WORKDIR $WORKSPACE_HOME

CMD python3 app.py
