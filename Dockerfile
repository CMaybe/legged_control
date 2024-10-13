ARG ROS_DISTRO=noetic
ARG ROS_PACKAGE=desktop-full

FROM osrf/ros:${ROS_DISTRO}-${ROS_PACKAGE}

ENV DEBIAN_FRONTEND noninteractive

ARG USER_NAME=cmaybe
ARG GROUP_NAME=CAU
ARG PROJECT_NAME=LeggedRobotics


# Utility packages
RUN apt-get -q update \
    && apt-get -y -q --no-install-recommends install \
    apt-utils \
    bash-completion \
    clang-format \
    curl \
	dbus-x11 \
    doxygen \
    doxygen-latex \
    gcovr \
    gdb \
    git \
    git-lfs \
	gnome-terminal \
    unzip \
    htop \
    lcov \
    locales \
    lsb-release \
    nano \
    net-tools \
    ninja-build \
    python3-catkin-tools \
    python3-pip \
    software-properties-common \
    sshpass \
    wget \
    zip 

# Set locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen

# Dependency packages
RUN apt-get -q update \
    && apt-get -y -q --no-install-recommends install \
    libglpk-dev \
    liburdfdom-dev \
    liboctomap-dev \
    libassimp-dev

# Thirdparty dependencies
RUN git clone --branch 3.3 https://gitlab.com/libeigen/eigen.git /opt/eigen \
    && mkdir -p /opt/eigen/build && cd /opt/eigen/build \
    && cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DEIGEN_BUILD_DOC=OFF \
    -DBUILD_TESTING=OFF \
    .. \
    && make install

RUN git clone --recurse-submodules https://github.com/leggedrobotics/hpp-fcl.git /opt/hpp-fcl \
    && mkdir -p /opt/hpp-fcl/build && cd /opt/hpp-fcl/build \
    && cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DEIGEN_BUILD_DOC=OFF \
    -DBUILD_TESTING=OFF \
    .. \
    && make install


RUN git clone --branch 1.22.10 https://github.com/strasdat/Sophus.git /opt/Sophus \
    && mkdir -p /opt/Sophus/build && cd /opt/Sophus/build \
    && cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DSOPHUS_INSTALL=ON \
    -DSOPHUS_USE_BASIC_LOGGING=ON \
    -DBUILD_SOPHUS_TESTS=OFF \
    -DBUILD_SOPHUS_EXAMPLES=OFF \
    -DBUILD_PYTHON_BINDINGS=OFF \
    .. \
    && make install


# Clone OCS2
RUN git clone https://github.com/leggedrobotics/ocs2.git /home/${USER_NAME}/ocs2_ws/src/ocs2
RUN git clone https://github.com/leggedrobotics/ocs2_robotic_assets.git /home/${USER_NAME}/ocs2_ws/src/ocs2/ocs2_robotic_assets

# ROS packages
RUN apt-get -q update \
    && apt-get -y -q --no-install-recommends install \
    ros-${ROS_DISTRO}-rqt-multiplot \
    ros-${ROS_DISTRO}-pinocchio \
	



# Add user info
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid ${USER_GID} ${GROUP_NAME} 

RUN useradd --create-home --shell /bin/bash \
               --uid ${USER_UID} --gid ${USER_GID} ${USER_NAME} \
	# Possible security risk
	&& echo "${USER_NAME}:${GROUP_NAME}" | sudo chpasswd \
	&& echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USER_NAME}"



# Make workspace 
ENV HOME /home/${USER_NAME}
ENV WORKSPACE ${HOME}/${PROJECT_NAME}_ws
RUN mkdir -p ${WORKSPACE} \
    && chown -R ${USER_NAME}:${GROUP_NAME} ${HOME}

# Shell
USER ${USER_NAME}
WORKDIR ${WORKSPACE}
ENV SHELL "/bin/bash"


# build the ocs2 workspace
RUN cd /home/${USER_NAME}/ocs2_ws \
    && catkin init \
    && catkin config --extend /opt/ros/${ROS_DISTRO} \
    && catkin config -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    && catkin build ocs2_robotic_assets ocs2_legged_robot ocs2_legged_robot_ros ocs2_self_collision_visualization



RUN echo "export USER=${USER_NAME}" >> ${HOME}/.bashrc \
    && echo "export GROUP=${GROUP_NAME}" >> ${HOME}/.bashrc \
    && echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ${HOME}/.bashrc