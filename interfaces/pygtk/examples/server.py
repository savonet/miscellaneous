#!/usr/bin/python

import os

os.execlp('liquidsoap','liquidsoap',"set('server.telnet.port',2000)"+\
"set('frame.size',940)"+\
"set('server.telnet',true)"+\
"main=request.equeue(id='main')"+\
"mixer_main=mix(id='mixer_main',[main])"+\
"output.alsa(mksafe(mixer_main),bufferize=false,id='alsaOut')"
)

