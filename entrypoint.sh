export DISPLAY=:99

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

echo "Waiting for virtual screen to be ready ($DISPLAY)"
sleep 2 

echo "Hiding mouse cursor"
unclutter -display $DISPLAY -idle 0 &  

echo "Starting audio service"
pulseaudio --start

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
  --start-fullscreen \
  --window-size=$(echo $RESOLUTION | sed 's/x/,/') \
  $([ "$SHOW_FPS_COUNTER" == "1" ] && echo "--ui-show-fps-counter") \
  --kiosk $WEBPAGE_URL &

echo "Starting stream ($RTMP_URL)"
# Stream from remote video file to check A/V Drift
# ffmpeg \
#   -loglevel $FFMPEG_LOGLEVEL \
#   -re -i $WEBPAGE_URL \
#   -c:v libx264 -preset veryfast -maxrate 3000k -bufsize 6000k -g 60 -r 30 \
#   -pix_fmt yuv420p \
#   -c:a aac -b:a 128k -ar 44100 \
#   -f flv $RTMP_URL

# Stream from x11 to check A/V Drift
ffmpeg \
  -loglevel $FFMPEG_LOGLEVEL \
  -use_wallclock_as_timestamps 1 \
  -thread_queue_size 1024 -f pulse -ac 2 -ar 48000 -i default \
  -thread_queue_size 1024 -f x11grab -r 30 -s $RESOLUTION -i "$DISPLAY.0" \
  -c:v libx264 -preset veryfast -maxrate 3000k -bufsize 6000k -g 60 -r 30 \
  -pix_fmt yuv420p \
  -c:a aac -b:a 128k -ar 48000 \
  -f flv $RTMP_URL