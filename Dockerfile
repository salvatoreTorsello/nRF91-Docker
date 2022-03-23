FROM ubuntu:20.04
ENV TZ=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y --no-install-recommends \
    git \
    ninja-build \
    gperf \
    ccache \
    doxygen \
    dfu-util \
    device-tree-compiler \
    python3-ply \
    python3-pip \
    python3-setuptools \
    xz-utils \
    file \
    make \
    wget \
	  curl
RUN mkdir nRF_dependencies
WORKDIR /nRF_dependencies
RUN wget https://apt.kitware.com/kitware-archive.sh
RUN bash kitware-archive.sh
RUN apt install -y --no-install-recommends git cmake ninja-build gperf \
  ccache dfu-util device-tree-compiler wget \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
  make gcc gcc-multilib g++-multilib libsdl2-dev
RUN cmake --version
RUN python3 --version
RUN dtc --version
# Latest PIP & Python dependencies
RUN python3 -m pip install -U pip && \
    python3 -m pip install -U setuptools && \
    python3 -m pip install -U west && \
    python3 -m pip install -U nrfutil && \
    python3 -m pip install pc_ble_driver_py && \
    # Newer PIP will not overwrite distutils, so upgrade PyYAML manually
    python3 -m pip install --ignore-installed -U PyYAML

RUN echo 'export PATH=~/.local/bin:"$PATH"' >> ~/.bashrc
WORKDIR /
RUN echo "source ~/.bashrc" >> /tmp/bashrc_exec
RUN /bin/bash -C "/tmp/bashrc_exec"
RUN rm -f /tmp/setup
#RUN source ~/.bashrc

WORKDIR /
ENV PATH "$PATH:/.local/bin"
WORKDIR /.local/bin
RUN ls

WORKDIR /nRF_dependencies
RUN mkdir ncs
WORKDIR /ncs
RUN west init -m https://github.com/nrfconnect/sdk-nrf --mr v1.9.0
RUN west update
RUN west zephyr-export
RUN python3 -m pip install --user -r zephyr/scripts/requirements.txt
RUN python3 -m pip install --user -r nrf/scripts/requirements.txt
RUN python3 -m pip install --user -r bootloader/mcuboot/scripts/requirements.txt
WORKDIR /
RUN mkdir gnuarmemb
WORKDIR /gnuarmemb
COPY gcc-arm-none-eabi.tar.bz2 /gnuarmemb
RUN tar xf gcc-arm-none-eabi.tar.bz2
RUN ls
ENV ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
ENV GNUARMEMB_TOOLCHAIN_PATH="/gnuarmemb/gcc-arm-none-eabi-10.3-2021.10"
ENV PATH="${GNUARMEMB_TOOLCHAIN_PATH}/bin:${PATH}"
ENV ZEPHYR_BASE=/nRF91_Projects/zephyr
ENV PATH="${ZEPHYR_BASE}/scripts:${PATH}"
# RUN touch ~/.zephyrrc
# RUN echo 'export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb' >> ~/.zephyrrc
# RUN echo 'export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb' >> ~/.bashrc 
# RUN echo 'export GNUARMEMB_TOOLCHAIN_PATH="~/gnuarmemb/gcc-arm-none-eabi-10.3-2021.10"' >> ~/.zephyrrc
# RUN echo 'export GNUARMEMB_TOOLCHAIN_PATH="~/gnuarmemb/gcc-arm-none-eabi-10.3-2021.10"' >> ~/.bashrc
# RUN echo 'export PATH="~/gnuarmemb/bin":"$PATH"' >> ~/.zephyrrc
# RUN echo 'export PATH="~/gnuarmemb/bin":"$PATH"' >> ~/.bashrc
# WORKDIR /ncs
# RUN ls
# WORKDIR /ncs/zephyr/
# RUN ls
# RUN .zephyr-env.sh

# RUN echo "source /ncs/zephyr/zephyr-env.sh" >> /tmp/zephyr-env_exec
# RUN /bin/bash -C "/tmp/zephyr-env_exec"

RUN apt install -y libfuse2 libgconf-2-4 libatk1.0-0 libatk-bridge2.0-0 libgdk-pixbuf2.0-0 libgtk-3-0 libgbm-dev libnss3-dev libxss-dev libncurses5
ENV APPIMAGE_EXTRACT_AND_RUN=1

WORKDIR /nRF_dependencies
COPY  nrfconnect-3.10.0-x86_64.appimage /nRF_dependencies
RUN chmod +x nrfconnect-3.10.0-x86_64.appimage

RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y install linux-tools-5.4.0-77-generic hwdata
RUN update-alternatives --install /usr/local/bin/usbip usbip /usr/lib/linux-tools/5.4.0-77-generic/usbip 20

WORKDIR /nRF_dependencies
RUN apt install -y libxcb-render-util0 libxcb-shape0 libxcb-randr0 libxcb-icccm4 libxcb-keysyms1 libxcb-image0  libxkbcommon-x11-0  udev

COPY JLink_Linux_V763b_x86_64.deb /nRF_dependencies/
RUN dpkg -i JLink_Linux_V763b_x86_64.deb 

RUN apt install linux-tools-5.4.0-77-generic hwdata
RUN update-alternatives --install /usr/local/bin/usbip usbip /usr/lib/linux-tools/5.4.0-77-generic/usbip 20

COPY nrf-command-line-tools_10.15.3_amd64.deb /nRF_dependencies/
RUN dpkg -i nrf-command-line-tools_10.15.3_amd64.deb 

COPY nrf-udev_1.0.1-all.deb /nRF_dependencies
#RUN dpkg -i nrf-udev_1.0.1-all.deb 

WORKDIR  /
COPY JLink_Linux_V763b_x86_64.tgz /nRF_dependencies
#RUN mkdir -p /opt/SEGGER 
#WORKDIR /opt/SEGGER
#RUN tar xf /nRF_dependencies/JLink_Linux_V763b_x86_64.tgz & \
#    chmod a-w JLink_Linux_V763b_x86_64 & \
#    ls -l JLink_Linux_V763b_x86_64


WORKDIR /
RUN mkdir nRF91_Projects
WORKDIR /nRF91_Projects

#RUN apt-get install -y sudo
#RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo 
#USER docker

RUN apt-get install -y locales
RUN sed -i '/en_GB.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_GB.UTF-8  
ENV LANGUAGE en_GB:en  
ENV LC_ALL en_GB.UTF-8

RUN pip3install pynrfjprog  
