#!/bin/bash
cd /home/$(whoami)/tree_landing_ws/src/
rosdep update
rosdep install --from-paths /home/$(whoami)/tree_landing_ws/src --ignore-src -r -y

cd /home/$(whoami)/tree_landing_ws/
bash -c "source /opt/ros/humble/setup.bash && MAKEFLAGS='-j1' colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON --packages-skip ardupilot_dds_tests --symlink-install" # --packages-up-to tree_landing"
bash -c "source /home/$(whoami)/tree_landing_ws/install/local_setup.bash"
