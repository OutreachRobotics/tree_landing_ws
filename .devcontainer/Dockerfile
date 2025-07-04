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

# Switch from root to user
USER $USERNAME

# Add user to video group to allow access to webcam
RUN sudo usermod --append --groups video $USERNAME

# Update all packages
RUN sudo apt update && sudo apt upgrade -y

# Install pip
RUN sudo apt install -y\
    git \
    python3-pip

# Rosdep update
RUN rosdep update

# Source the ROS setup file
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc

# Allow USB access
RUN sudo usermod -a -G dialout $USERNAME

######################
### Custom Section ###
######################

ARG WS=/home/$USERNAME/tree_landing_ws
ARG SRC=$WS/src

### Base repos
COPY ./.git/ $WS/.git/
COPY ./.gitignore $WS/.gitignore
COPY ./.gitmodules $WS/.gitmodules
COPY ./src/ardupilot/ $SRC/ardupilot/
COPY ./src/DeepForest/ $SRC/DeepForest/
COPY ./src/mavros/ $SRC/mavros/
COPY ./src/tree_landing/ $SRC/tree_landing/
COPY ./src/tree_landing_interfaces/ $SRC/tree_landing_interfaces/

WORKDIR $WS
RUN sudo chown -R $(whoami) .
RUN git submodule update --init --recursive

### Custom ros dependencies
RUN sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo apt-get install -y \
    ros-humble-tf-transformations \
    ros-humble-mavros \
    ros-humble-mavros-extras \
    ros-humble-realsense2-* \
    ros-humble-pcl-ros \
    ros-humble-rtabmap-ros \
    ros-humble-robot-localization

RUN pip install python-statemachine

# Add geographic lib for mavros
RUN sudo apt-get install geographiclib-tools

WORKDIR $SRC/mavros/mavros/scripts
RUN sudo chmod +x install_geographiclib_datasets.sh &&\
    bash -c "sudo ./install_geographiclib_datasets.sh"

### DeepForest
RUN sudo apt-get update -y && \
    sudo apt-get install -y \
    libgl1

WORKDIR $SRC/DeepForest/
RUN pip install --upgrade pip && \
    pip install -r dev_requirements.txt && \
    pip install -e . && \
    pip install numpy==1.26.4

RUN sudo chown -R ubuntu:ubuntu $WS
WORKDIR $SRC/tree_landing/scripts/
RUN python3 download_deepforest.py $WS/install/DeepForest/deepforest_model.pl

### First ROS compile
WORKDIR $WS
RUN bash -c "source /opt/ros/humble/setup.bash && sudo apt-get update && rosdep update && rosdep install --from-paths src --ignore-src -r -y"
# RUN bash -c "source /opt/ros/humble/setup.bash && MAKEFLAGS='-j1' colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON --packages-up-to tree_landing mavros"
RUN echo "source $WS/install/local_setup.bash" >> ~/.bashrc

# Aliases
WORKDIR $WS
RUN echo "alias bros='cd $WS && source /opt/ros/humble/setup.bash && MAKEFLAGS='-j1' colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON --packages-skip ardupilot_dds_tests --symlink-install && source $WS/install/local_setup.bash'" >> ~/.bashrc && \
    echo "alias sros='cd $WS && source $WS/install/local_setup.bash'" >> ~/.bashrc && \
    echo "alias spytf='cd $WS/src/tree_landing/ && ros2 run tf2_tools view_frames'" >> ~/.bashrc && \
    echo "alias flat='bash $WS/src/tree_landing/scripts/fetch_latte.bash'" >> ~/.bashrc




### DEV BUILD ###
FROM base AS dev

### Dev repos
COPY ./ $WS/

WORKDIR $WS
RUN sudo chown -R $(whoami) .
RUN git submodule update --init --recursive
# RUN rm -rf $SRC/ros_gz/ros_ign_*

### Gazebo Harmonic: https://gazebosim.org/docs/harmonic/install_ubuntu/
RUN sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo apt-get install -y \
    curl \
    lsb-release \
    gnupg

RUN sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
RUN sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo apt-get install -y \
    gz-harmonic
    # ros-humble-ros-gzharmonic

### ArdupilotSITL install: https://ardupilot.org/dev/docs/building-setup-linux.html#building-setup-linux
# Example: https://github.com/radarku/ardupilot-sitl-docker/blob/master/Dockerfile
WORKDIR $SRC/ardupilot/
RUN sudo apt-get update && \
    sudo apt-get install -y \
    lsb-release \
    tzdata
RUN USER=$USERNAME Tools/environment_install/install-prereqs-ubuntu.sh -y && \
    . /home/$USERNAME/.profile

RUN ./waf distclean && \
    ./waf configure --board sitl && \
    ./waf copter

### ROS Setup for ardupilot_sitl: https://ardupilot.org/dev/docs/ros2.html
RUN sudo apt-get update && \
    sudo apt-get install -y default-jre

WORKDIR $SRC/Micro-XRCE-DDS-Gen/
RUN ./gradlew assemble
ENV PATH="$SRC/Micro-XRCE-DDS-Gen/scripts:$PATH"

# Fixes bug with ardupilot_sitl: https://github.com/pypa/setuptools/issues/4483
WORKDIR $WS
RUN pip install -U packaging

### QGC: https://docs.qgroundcontrol.com/master/en/qgc-user-guide/getting_started/download_and_install.html
WORKDIR $WS
# RUN sudo usermod -a -G dialout $USERNAME
RUN sudo apt-get remove modemmanager -y
RUN sudo apt install -y \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav \
    gstreamer1.0-gl \
    libfuse2 \
    libxcb-xinerama0 \
    libxkbcommon-x11-0 \
    libxcb-cursor-dev \
    fuse

USER $USERNAME
RUN curl https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage --output $WS/QGroundControl.AppImage
RUN chmod +x QGroundControl.AppImage

### Colcon build
# With gazebo setup: https://github.com/ArduPilot/ardupilot_gazebo
WORKDIR $WS
ENV GZ_VERSION=harmonic
RUN sudo bash -c 'wget https://raw.githubusercontent.com/osrf/osrf-rosdep/master/gz/00-gazebo.list -O /etc/ros/rosdep/sources.list.d/00-gazebo.list'
RUN bash -c "source /opt/ros/humble/setup.bash && sudo apt update && rosdep update && rosdep resolve gz-harmonic && rosdep install --from-paths src --ignore-src -r -y"
# RUN bash -c "source /opt/ros/humble/setup.bash && MAKEFLAGS='-j1' colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
RUN echo "source $WS/install/local_setup.bash" >> ~/.bashrc

# Setup Gazebo resources
WORKDIR /usr/share/gz/gz-sim8/media/materials/scripts/
RUN sudo bash -c 'ln -s /usr/share/gz/gz-sim8/media/gazebo.material /usr/share/gz/gz-sim8/media/materials/scripts/gazebo.material'
ENV GZ_SIM_RESOURCE_PATH=$WS/install/tree_landing/share/:/share/tree_landing/gazebo/models/:/share/tree_landing/gazebo/worlds/:$WS/install/gazebo_vegetation/share/gazebo_vegetation/models/:/usr/share/gz/gz-sim8/

# USER root


# RUN sudo apt-get --purge remove -y gz-tools2
# RUN sudo apt-get autoremove
# RUN sudo apt-get install -y ros-humble-gazebo-ros-pkgs
