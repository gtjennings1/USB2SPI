import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('-p', dest='portname', default=None)
parser.add_argument('-i', dest='input', default=None)
parser.add_argument('-a', dest='address', default='0')
parser.add_argument('-o', dest='output', default=None)
parser.add_argument('-s', dest='size', default=None, type=int)
parser.add_argument('-e', dest='full_erase', action='store_true')

args = parser.parse_args()

port = args.portname

if port == None:
    print('No port specified.')
    exit()

input = args.input
if input is not None:
    if not os.path.exists(input):
        print('Input file {} not found.'.format(input))
        exit()

address = int(args.address, 0)

from flash import Flash 

flash = Flash()
flash.debug = False
flash.open(port)

chip_info = {}
chip_info = flash.get_device_info()
for key in chip_info:
    print('{}: {} (0x{:02X})'.format(key, chip_info[key][0], chip_info[key][1]))

if input is None:
    print('No input file. Skip write operation.')
else:
    print('Write operation')
    
    flash.erase_chip()
    written = flash.write_hex(address, input)
    print('Written: {}'.format(written))

output = args.output
size = args.size

if output is None:
    pass
else:
    print('Read operation')
    if size is None:
        if input is not None:
            size = written
    
    flash.read_hex(address, output, size)
    
    if input is not None:
        flash.verify_hex(address, input, output)

flash.close()

