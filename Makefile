SHELL := /bin/bash

.PHONY: check install run

check:
	@command -v v4l2-ctl > /dev/null 2>&1 || { echo "v4l2-ctl is not installed"; exit 1; }
	@command -v ffplay > /dev/null 2>&1 || { echo "ffplay is not installed"; exit 1; }
	@command -v ffmpeg > /dev/null 2>&1 || { echo "ffmpeg is not installed"; exit 1; }
	@command -v gst-launch-1.0 > /dev/null 2>&1 || { echo "GStreamer is not installed"; exit 1; }

install:
	@sudo apt-get update
	@sudo apt-get install -y v4l-utils ffmpeg gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad

run:
	@bash index.sh

all: check install run
