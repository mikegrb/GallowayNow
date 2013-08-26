#!/usr/bin/liquidsoap -v

set("log.file.path","/home/michael/liquidsoap/liquidsoap.log")

gallowaynow= (input.http(max=30.0,"http://gallowaynow.com:8000/stream"):source(1,0,0))

# fill in password and mount
output.icecast( %mp3(stereo=false, bitrate=16, samplerate=22050),
 host="audio1.radioreference.com",  port = 80, password =  "",
 genre="Scanner",  description="Scanner audio", mount="", 
 name="Galloway and Absecon Police, Fire / EMS", user="source",
 url="http://www.gallowaynow.com", fallible=true, gallowaynow)