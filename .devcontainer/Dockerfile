FROM osrf/ros:noetic-desktop

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    python3-pip \
    python3-catkin-tools \
    python3-rosdep \
    wget \
    curl \
    software-properties-common

# Create non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set up environment
ENV HOME=/home/$USERNAME
ENV ROS_DISTRO=noetic

# Install ROS Python packages
RUN apt-get update && apt-get install -y \
    ros-$ROS_DISTRO-rqt* \
    ros-$ROS_DISTRO-rviz \
    python3-rospy \
    python3-std-msgs \
    python3-sensor-msgs \
    python3-nav-msgs \
    python3-geometry-msgs \
    python3-rostest \
    python3-rosunit

# Install additional Python dependencies
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install \
    rospkg \
    catkin_pkg \
    numpy \
    pytest

# Ensure ROS setup is sourced for all users
RUN echo "source /opt/ros/noetic/setup.bash" >> /etc/bash.bashrc

# Add ROS binary path to system-wide PATH
RUN echo 'export PATH="/opt/ros/noetic/bin:$PATH"' >> /etc/profile.d/ros_path.sh

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up rosdep
RUN rosdep init || true \
    && su - $USERNAME -c "rosdep update"

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME/ws

# Source ROS setup in user's .bashrc
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

CMD ["/bin/bash"]