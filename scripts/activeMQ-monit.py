#!/usr/bin/python3

import stomp
import socket
import time
import sys

hostname = socket.gethostname()
ip = socket.gethostbyname(hostname)

queue_name = '/queue/monitTestQueue'
msgBody = "This is a test: " + str(time.time())

totalReceived = 0
successfulRead = False

class TestListener(stomp.ConnectionListener):
    def on_message(self, frame):
        if msgBody == frame.body:
            global successfulRead
            successfulRead = True
        else:
            print('Unexpected message, was: ' + frame.body)

        global totalReceived
        totalReceived = totalReceived + 1


conn = stomp.Connection([( hostname, 61613 )])
conn.connect(wait=True)
conn.set_listener("testlistener", TestListener())
conn.subscribe(destination = queue_name, id = 1, ack = "auto")

conn.send(body = msgBody, destination = queue_name)

totalCycles = 0
while totalReceived == 0:
    time.sleep(1)
    totalCycles = totalCycles + 1
    if totalCycles >= 5:
        print('Timed out waiting for message')
        break

conn.disconnect()

if not successfulRead:
    sys.exit(1)