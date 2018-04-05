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
	chip_info = {}
	chip_info = flash.get_device_status()
	for key in chip_info:
		print('{}: {}'.format(key, chip_info[key]))
finally:	
	flash.close()

