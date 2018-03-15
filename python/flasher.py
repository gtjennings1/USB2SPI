
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-p', dest='portname', default=None)

args = parser.parse_args()

port = args.portname

if port == None:
    print('No port specified.')
    exit()

print('Port: {}'.format(port))

from flash import Flash

flash = Flash()
flash.open(port)

flash.close

