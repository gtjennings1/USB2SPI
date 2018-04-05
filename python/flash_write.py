import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('-p', dest='portname', default=None)
parser.add_argument('-d', dest='debug', action='store_true')
parser.add_argument('-a', dest='address', default=None)
parser.add_argument('-v', dest='value', default=None)
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
	flash.write_int(int(args.address, 0), int(args.value, 0))
	
finally:	
	flash.close()

