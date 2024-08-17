#!/bin/bash

# Function to get idle time in seconds
get_idle_time() {
    ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print $NF/1000000000; exit}'
}

# Function to reset Touch Bar
reset_touchbar() {
    sudo pkill TouchBarServer
    killall ControlStrip
    echo "Touch Bar has been reset at $(date)"
}

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Initialize variables
reset_count=0
last_reset_time=0
idle_threshold=30
post_reset_sleep=15

# Main loop
while true; do
    current_time=$(date +%s)
    idle_time=$(get_idle_time)
    idle_time=${idle_time%.*}  # Remove decimal part

    # If system just became active after being idle
    if [ "$idle_time" -lt 5 ] && [ $((current_time - last_reset_time)) -gt $idle_threshold ]; then
        reset_touchbar
        last_reset_time=$current_time
        reset_count=$((reset_count + 1))
        
        # Adjust timings based on reset frequency
        if [ $reset_count -gt 5 ]; then
            idle_threshold=$((idle_threshold - 5))
            post_reset_sleep=$((post_reset_sleep - 2))
            reset_count=0
            echo "Adjusted timings: Idle threshold = $idle_threshold, Post-reset sleep = $post_reset_sleep"
        fi

        sleep $post_reset_sleep
    elif [ "$idle_time" -ge $idle_threshold ]; then
        reset_touchbar
        last_reset_time=$current_time
        sleep $post_reset_sleep
    else
        sleep_time=$((idle_threshold - idle_time))
        sleep $sleep_time
    fi

    # Prevent timings from getting too low
    if [ $idle_threshold -lt 10 ]; then
        idle_threshold=10
    fi
    if [ $post_reset_sleep -lt 5 ]; then
        post_reset_sleep=5
    fi
done
