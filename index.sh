#!/bin/bash

# Function to kill processes using the webcam device
kill_using_device() {
    local device=$1
    local pids=$(lsof $device | awk 'NR>1 {print $2}')
    
    for pid in $pids; do
        kill -9 $pid
    done
}

declare -A webcams
selected_device=""

print_webcams() {
	v4l2-ctl --list-devices
}


# List webcams and store in an associative array
list_webcams() {
    while IFS=': ' read -r device name; do
        webcams["$device"]=$name
    done < <(v4l2-ctl --list-devices | awk -F':' '/\/dev\/video[0-9]+/{print $1 ": " device} /Card type/{device=$0}')
}

# Prompt user for webcam selection
select_webcam() {
    echo "Select a webcam:"
    local i=1
    for device in "${!webcams[@]}"; do
        echo "$i. ${webcams[$device]} ($device)"
        ((i++))
    done

    read -p "Enter your choice: " choice
    local j=1
    for device in "${!webcams[@]}"; do
        if [ "$choice" -eq "$j" ]; then
            selected_device=$device
            break
        fi
        ((j++))
    done
}

# Prompt user for action
select_action() {
    echo "What would you like to do?"
    echo "1. Show the stream"
    echo "2. Record the stream"
    echo "3. Both"
    echo "4. Show camera formats"
    echo "5. Show driver information"

    read -p "Enter your choice: " action
}

# Main script
echo "Here are the cameras on your system"
print_webcams
echo "______________________________"
list_webcams
select_webcam
echo "______________________________"
select_action

# Kill any process using the selected device
kill_using_device $selected_device

# Launch appropriate action based on user choice
case $action in
    1)
        ffplay -f v4l2 -video_size 1080x1920 -input_format mjpeg -i $selected_device
        ;;
    2)
        ffmpeg -f v4l2 -input_format mjpeg -video_size 1920x1080 -i $selected_device -c:v copy output.mp4
        ;;
    3)
        gst-launch-1.0 v4l2src device=$selected_device ! 'image/jpeg, width=1920, height=1080, framerate=30/1' ! jpegdec ! tee name=t ! queue ! identity silent=false ! autovideosink t. ! queue ! x264enc ! mp4mux ! filesink location=output.mp4
        ;;
    4)
        v4l2-ctl -d $selected_device --list-formats-ext
        ;;
    5)
        v4l2-ctl -d $selected_device -D
        ;;
    *)
        echo "Invalid choice."
        ;;
esac

