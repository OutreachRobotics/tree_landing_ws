# Drone arboricole

Documentation et code nécessaire à l'opération du drone arboricole autonome.



## Dépendances principales

ROS2: https://github.com/ros2

ArduPilot: https://github.com/ArduPilot/ardupilot

Mavros: https://github.com/mavlink/mavros/tree/ros2

Intel RealSense: https://github.com/IntelRealSense/realsense-ros

RTABMap: https://github.com/introlab/rtabmap_ros

DeepForest: https://github.com/weecology/DeepForest



# On-Board Computer Setup (Ubuntu 22.04)
The following guide goes through the setup required to deploy the OceanSight Docker container.

## Git setup

1. **Install Git**
   ```
   sudo apt install -y git
   ```

2. **Setup your ssh key**  
   Setup your github ssh key by following the instructions under [Generating a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and [Adding your SSH key to the ssh-agent](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

3. **Verify setup**  
   After completing the setup, make sure that your ssh key exists at this location with the following command.
   ```
   cat ~/.ssh/id_ed25519
   ```

4. **Clone the repository**  
   Clone the repository with this command to install all the submodules properly.
   ```
   git clone --recurse-submodules https://github.com/chcaya/tree_landing_ws.git
   ```

## Docker setup

1. **Install Docker Engine**  
   Install Docker Engine by following the instructions in this [link](https://docs.docker.com/engine/install/ubuntu/).

2. **Complete Docker Post-Installation Steps**  
   Complete the post-installation steps to remove the need for `sudo` with Docker commands by following this [link](https://docs.docker.com/engine/install/linux-postinstall/).


#### Do not forget to periodically clean up after using docker tools
   ```
   sudo docker system prune -a
   ```

## Docker build and run on companion computer

1. **Build the base docker image**
   ```
    cd ~/tree_landing_ws/
    docker build --target base -f ~/tree_landing_ws/.devcontainer/Dockerfile -t ros:base ~/tree_landing_ws/
   ```

2. **Run post build script from inside the container**
   ```
    docker run --rm -u ubuntu -v ~/tree_landing_ws:/home/ubuntu/tree_landing_ws ros:base bash /home/ubuntu/tree_landing_ws/.devcontainer/postCreateBase.sh
   ```

3. **Test the new docker image**
   ```
   bash ~/tree_landing_ws/src/tree_landing/scripts/drone_launch.sh
   ```

4. **Run the script to create the start up service**
   ```
   bash ~/tree_landing_ws/src/tree_landing/scripts/create_startup_script.bash
   ```

5. **Reboot the computer to test the whole pipeline**
   ```
   sudo reboot
   ```
