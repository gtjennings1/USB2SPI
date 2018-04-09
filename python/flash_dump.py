import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('-p', dest='portname', default=None)
parser.add_argument('-d', dest='debug', action='store_true')
parser.add_argument('-a', dest='address', default=None)
parser.add_argument('-s', dest='size', default=None, type=int)
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
    input("waiting")
    print(flash.read(int(args.address,0), args.size))
    
finally:    
    flash.close()

