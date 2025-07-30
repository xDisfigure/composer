export DISPLAY=:99
PULSE_SINK=virtual_sink

echo -e "Environment variable\n\n"
echo "WEBPAGE_URL => $WEBPAGE_URL"
echo "RTMP_URL => $RTMP_URL"
echo "RESOLUTION => $RESOLUTION"
echo "FFMPEG_LOGLEVEL => $FFMPEG_LOGLEVEL"
echo "SHOW_FPS_COUNTER => ${SHOW_FPS_COUNTER:-0}"
echo -e "\n\nIf one of the environment variable is wrong press Ctrl+C" 
sleep 10

echo "Creating virtual screen ($DISPLAY)"
Xvfb $DISPLAY -screen 0 ${RESOLUTION}x24 &

echo "Hidding mouse cursor"
sleep 1
unclutter -display $DISPLAY -idle 0 &

echo "Waiting for virtual screen to be ready ($DISPLAY)"
sleep 2 

echo "Starting audio service"
pulseaudio --start
pactl load-module module-null-sink sink_name=$PULSE_SINK sink_properties=device.description=Virtual_Sink
pactl set-default-sink $PULSE_SINK

echo "Starting chrome ($WEBPAGE_URL)"
google-chrome \
  --disable-gpu \
  --disable-software-rasterizer \
  --disable-accelerated-video-decode \
  --disable-accelerated-2d-canvas \
  --disable-dev-shm-usage \
  --disable-extensions \
  --disable-background-networking \
  --disable-background-timer-throttling \
  --disable-renderer-backgrounding \
  --disable-frame-rate-limit \
  --disable-sync \
  --disable-default-apps \
  --disable-hang-monitor \
  --disable-popup-blocking \
  --metrics-recording-only \
  --test-type \
  --no-sandbox \
  --no-first-run \
  --autoplay-policy=no-user-gesture-required \
  --hide-scrollbars \
  --window-position=0,0 \
  --window-size=$(echo $RESOLUTION | sed 's/x/,/') \
  $([ "$SHOW_FPS_COUNTER" == "1" ] && echo "--ui-show-fps-counter") \
  --kiosk $WEBPAGE_URL &

echo "Starting stream ($RTMP_URL)"

WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f1)
HEIGHT=$(echo "$RESOLUTION" | cut -d'x' -f2)

gst-launch-1.0 -v \
  ximagesrc display-name=$DISPLAY use-damage=0 ! \
    video/x-raw,framerate=30/1,width=$WIDTH,height=$HEIGHT ! \
    queue ! videoconvert ! \
    x264enc bitrate=3000 speed-preset=veryfast tune=fastdecode key-int-max=60 ! \
    queue ! mux. \
  pulsesrc device=$PULSE_SINK.monitor ! \
    queue ! audioconvert ! voaacenc bitrate=128000 ! \
    queue ! mux. \
  flvmux streamable=true name=mux ! rtmpsink location=$RTMP_URL