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
flash.debug = args.debug
flash.open(port)

try:
	flash.release_rst()
finally:	
	flash.close()