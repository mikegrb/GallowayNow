#!/bin/sh

/home/michael/bin/fPls -T 10 -L-1 -v http://localhost:8000/stream.m3u 2>/dev/null |
   /usr/bin/sox -t mp3 - -t wav - silence -l 1 0.3 1% -1 3.0 1 2>/dev/null |
   /home/michael/gallowaynow/galloway_now/script/dispatch_tones.pl