#!/bin/bash
set -e # Exit immediately on error

# Take ownership of the mounted workspace
sudo chown -R $(whoami):$(whoami) /home/$(whoami)/tree_landing_ws

# --- This is the new logic ---
echo "--- Building Micro-XRCE-DDS-Gen ---"
cd /home/$(whoami)/tree_landing_ws/src/Micro-XRCE-DDS-Gen
./gradlew assemble

# Now copy the files to the persistent build directory
mkdir -p /home/$(whoami)/tree_landing_ws/build/Micro-XRCE-DDS-Gen
cp -r ./share /home/$(whoami)/tree_landing_ws/build/Micro-XRCE-DDS-Gen/
cp -r ./scripts /home/$(whoami)/tree_landing_ws/build/Micro-XRCE-DDS-Gen/

# Make the script executable (a common missing step)
chmod +x /home/$(whoami)/tree_landing_ws/build/Micro-XRCE-DDS-Gen/scripts/microxrceddsgen
echo "--- Micro-XRCE-DDS-Gen build complete ---"

cd /home/$(whoami)/tree_landing_ws/src/
rosdep update
rosdep install --from-paths /home/$(whoami)/tree_landing_ws/src --ignore-src -r -y

cd /home/$(whoami)/tree_landing_ws/
bash -c "source /opt/ros/humble/setup.bash && MAKEFLAGS='-j1' colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON --packages-skip ardupilot_dds_tests --symlink-install" # --packages-up-to tree_landing"
bash -c "source /home/$(whoami)/tree_landing_ws/install/local_setup.bash"

cd /home/$(whoami)/tree_landing_ws/
bash -c "sudo apt-get update && sudo apt-get install libfuse2 fuse"
bash -c "curl -L https://github.com/mavlink/qgroundcontrol/releases/download/v4.4.5/QGroundControl.AppImage --output /home/$(whoami)/tree_landing_ws//QGroundControl.AppImage"
bash -c "chmod +x QGroundControl.AppImage"
