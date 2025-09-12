FROM osrf/ros:humble-desktop-full AS base

# Add ubuntu user with same UID and GID as your host system, if it doesn't already exist
# Since Ubuntu 24.04, a non-root user is created by default with the name vscode and UID=1000
ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN if ! id -u $USER_UID >/dev/null 2>&1; then \
        groupadd --gid $USER_GID $USERNAME && \
        useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME; \
    fi
# Add sudo support for the non-root user
RUN apt-get update && \
    apt-get install -y sudo && \
    echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Add user to video group to allow access to webcam
RUN usermod --append --groups video $USERNAME

# Update and install all packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    curl \
    git \
    python3-pip \
    build-essential \
    ros-humble-tf-transformations \
    ros-humble-mavros \
    ros-humble-mavros-extras \
    ros-humble-mavros-msgs \
    ros-humble-libmavconn \
    ros-humble-realsense2-* \
    ros-humble-pcl-ros \
    ros-humble-rtabmap-ros \
    ros-humble-robot-localization \
    geographiclib-tools \
    libgl1
    
RUN pip install \
    pandas \
    --upgrade scipy \
    "numpy<2"

# ROS setup
RUN rosdep update && \
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/$USERNAME/.bashrc

# Allow USB access
RUN usermod -a -G dialout $USERNAME

######################
### Custom Section ###
######################

ARG WS=/home/$USERNAME/tree_landing_ws
ARG SRC=$WS/src

### Base repos
COPY ./.git/ $WS/.git/
COPY ./.gitignore $WS/.gitignore
COPY ./.gitmodules $WS/.gitmodules
COPY ./src/tree_landing/ $SRC/tree_landing/
COPY ./src/tree_landing_interfaces/ $SRC/tree_landing_interfaces/

WORKDIR $WS
RUN git submodule update --init --recursive

### Custom ros dependencies
RUN pip install python-statemachine

# Add geographic lib for mavros
RUN bash -c "source /opt/ros/humble/setup.bash && ros2 run mavros install_geographiclib_datasets.sh"

### First ROS compile
WORKDIR $WS
RUN bash -c "source /opt/ros/humble/setup.bash && apt-get update && rosdep update && rosdep install --from-paths src --ignore-src -r -y" && \
    echo "source $WS/install/local_setup.bash" >> /home/$USERNAME/.bashrc && \
    echo "alias bros='cd $WS && source /opt/ros/humble/setup.bash && MAKEFLAGS='-j1' colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON --packages-skip ardupilot_dds_tests --symlink-install && source $WS/install/local_setup.bash'" >> /home/$USERNAME/.bashrc && \
    echo "alias sros='cd $WS && source $WS/install/local_setup.bash'" >> /home/$USERNAME/.bashrc && \
    echo "alias spytf='cd $WS/src/tree_landing/ && ros2 run tf2_tools view_frames'" >> /home/$USERNAME/.bashrc && \
    echo "alias flat='bash $WS/src/tree_landing/scripts/fetch_latte.bash'" >> /home/$USERNAME/.bashrc

USER $USERNAME



### DEV BUILD ###
FROM base AS dev
USER root

### Gazebo Harmonic: https://gazebosim.org/docs/harmonic/install_ubuntu/
### Install dev apt packages
RUN curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    lsb-release \
    gnupg \
    gz-harmonic \
    # ros-humble-ros-gzharmonic
    lsb-release \
    tzdata \
    default-jre \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav \
    gstreamer1.0-gl \
    libfuse2 \
    libxcb-xinerama0 \
    libxkbcommon-x11-0 \
    libxcb-cursor-dev \
    fuse

### Dev repos
COPY ./ $WS/

WORKDIR $WS
RUN git submodule update --init --recursive
    
### ArdupilotSITL install: https://ardupilot.org/dev/docs/building-setup-linux.html#building-setup-linux
# Example: https://github.com/radarku/ardupilot-sitl-docker/blob/master/Dockerfile
USER $USERNAME
WORKDIR $SRC/ardupilot/
RUN USER=$USERNAME Tools/environment_install/install-prereqs-ubuntu.sh -y && \
    . /home/$USERNAME/.profile
USER root

RUN pip install \
    future \
    pexpect && \
    ./waf distclean && \
    ./waf configure --board sitl && \
    ./waf copter

### ROS Setup for ardupilot_sitl: https://ardupilot.org/dev/docs/ros2.html
WORKDIR $SRC/Micro-XRCE-DDS-Gen/
RUN ./gradlew assemble
RUN mkdir -p $WS/build/Micro-XRCE-DDS-Gen && \
    cp -r ./share $WS/build/Micro-XRCE-DDS-Gen/ && \
    cp -r ./scripts $WS/build/Micro-XRCE-DDS-Gen/
ENV PATH="$WS/build/Micro-XRCE-DDS-Gen:$WS/build/Micro-XRCE-DDS-Gen/scripts:$PATH"

# Fixes bug with ardupilot_sitl: https://github.com/pypa/setuptools/issues/4483
WORKDIR $WS
RUN pip install -U packaging

### Colcon build
# With gazebo setup: https://github.com/ArduPilot/ardupilot_gazebo
WORKDIR $WS
ENV GZ_VERSION=harmonic
RUN bash -c 'wget https://raw.githubusercontent.com/osrf/osrf-rosdep/master/gz/00-gazebo.list -O /etc/ros/rosdep/sources.list.d/00-gazebo.list' && \
    bash -c "source /opt/ros/humble/setup.bash && apt update && rosdep update && rosdep resolve gz-harmonic && rosdep install --from-paths src --ignore-src -r -y" && \
    echo "source $WS/install/local_setup.bash" >> /home/$USERNAME/.bashrc

# Setup Gazebo resources
WORKDIR /usr/share/gz/gz-sim8/media/materials/scripts/
RUN bash -c 'ln -s /usr/share/gz/gz-sim8/media/gazebo.material /usr/share/gz/gz-sim8/media/materials/scripts/gazebo.material'
ENV GZ_SIM_RESOURCE_PATH=$WS/install/tree_landing/share/:/share/tree_landing/gazebo/models/:/share/tree_landing/gazebo/worlds/:$WS/install/gazebo_vegetation/share/gazebo_vegetation/models/:/usr/share/gz/gz-sim8/

# Switch from root to user
USER $USERNAME
