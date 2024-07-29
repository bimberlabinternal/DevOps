#!/usr/bin/env python3

import sys
import re

line_regex = re.compile("^ERROR")
currentError = []

def processMessage(msgLines):
    if len(msgLines) == 0:
        return
        
    # This can be caused by DuckDuckGo Browsers:
    lastLine = msgLines[-1]
    if lastLine == 'Error: feature named `clickToLoad` was not found':
        currentError.clear()
        return
    
    # False alarms, such as security bots trying to reset passwords:
    if any("Password reset attempted" in s for s in msgLines):
        currentError.clear()
        return
        
    delim = ''
    for line in msgLines:
        print(delim + line)
        delim = '\t'
    print('\n')

    currentError.clear()

for line in sys.stdin:
    line = line.strip()
    
    if (line_regex.search(line)):
        processMessage(currentError)
    
    currentError.append(line.strip())

processMessage(currentError)