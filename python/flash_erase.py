import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('-p', dest='portname', default=None)
parser.add_argument('-d', dest='debug', action='store_true')
parser.add_argument('-a', dest='address', default=0)
parser.add_argument('-s', dest='size', default=0)
parser.add_argument('-b', dest='bsize', default='64K')
args = parser.parse_args()

port = args.portname

if port == None:
    print('No port specified.')
    exit()
    
if args.bsize == '64K':
    bsize = 64*1024
elif args.bsize == '4K':
    bsize = 4*1024
else:
    print('Block size {} is wrong. Supported 4K or 64K value')
    exit()


from flash import Flash 

flash = Flash()
flash.debug = args.debug
flash.open(port)

address = int(args.address, 0)
size = int(args.size, 0)


try:
    if address == 0 and size == 0:
        flash.erase_chip()
    else:
        chip_size = flash.get_chip_size()
        if size == 0:
            end_address = chip_size - 1
        else:
            if address + size > chip_size:
                end_address = chip_size - 1
            else:
                end_address = address + size - 1

        if bsize == 4*1024:
            start_address = address & 0xFFFFF000
            end_address = end_address | 0x00000FFF
        else:
            start_address = address & 0xFFFF0000
            end_address = end_address | 0x0000FFFF
            
        print('Partial chip erasing:')
        print('The memory range will be erased from 0x{:08x} to 0x{:08x}'.format(start_address, end_address))
        cont = input('Are you sure you want to continue?[y/N] ')
        if cont is None:
            exit()
        elif cont.lower() == 'n':
            exit()
        else:
            bcount = int((end_address - start_address)/bsize) + 1
            flash.erase_chip_partial(start_address, bsize, bcount)
                
finally:    
    flash.close()

