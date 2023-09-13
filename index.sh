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

    read -p "Enter your choice: " action
}

# Main script
list_webcams
select_webcam
select_action

# Kill any process using the selected device
kill_using_device $selected_device

# Launch appropriate GStreamer pipeline based on user action
case $action in
    1)
        gst-launch-1.0 v4l2src device=$selected_device ! 'image/jpeg, width=1920, height=1080, framerate=30/1' ! jpegdec ! identity silent=false ! autovideosink
        ;;
    2)
        gst-launch-1.0 v4l2src device=$selected_device ! 'image/jpeg, width=1920, height=1080, framerate=30/1' ! jpegdec ! x264enc ! mp4mux ! filesink location=output.mp4
        ;;
    3)
        gst-launch-1.0 v4l2src device=$selected_device ! 'image/jpeg, width=1920, height=1080, framerate=30/1' ! jpegdec ! tee name=t ! queue ! identity silent=false ! autovideosink t. ! queue ! x264enc ! mp4mux ! filesink location=output.mp4
        ;;
    *)
        echo "Invalid choice."
        ;;
esac

