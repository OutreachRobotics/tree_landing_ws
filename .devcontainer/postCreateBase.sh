#!/bin/bash
set -e # Exit immediately on error

# Take ownership of the mounted workspace
sudo chown -R $(whoami):$(whoami) /home/$(whoami)/tree_landing_ws

cd /home/$(whoami)/tree_landing_ws/src/
rosdep update
rosdep install --from-paths /home/$(whoami)/tree_landing_ws/src/tree_landing /home/$(whoami)/tree_landing_ws/src/tree_landing_interfaces --ignore-src -r -y

cd /home/$(whoami)/tree_landing_ws/
bash -c "source /opt/ros/humble/setup.bash && MAKEFLAGS='-j1' colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON --packages-up-to tree_landing --symlink-install"
bash -c "source /home/$(whoami)/tree_landing_ws/install/local_setup.bash"
