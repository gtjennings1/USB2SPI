import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('-p', dest='portname', default=None)
parser.add_argument('-d', dest='debug', action='store_true')
args = parser.parse_args()

port = args.portname

if port == None:
    print('No port specified.')
    exit()


from flash import Flash 

flash = Flash()
flash.debug = True
flash.open(port)

try:
    
    input('Waiting rvl ready')
    data = []
    data.append(0x03)
    flash._write(data, 259, True)
    
        
finally:	
	flash.close()

