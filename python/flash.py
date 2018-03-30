
import serial
import time
import os
from progressbar import ProgressBar

class Flash:
    # W25Q32 instructions
    WRITE_ENA = 0x06
    WRITE_DIS = 0x04
    READ_SR_1 = 0x05
    READ_SR_2 = 0x35
    WRITE_SR  = 0x01
    PAGE_PROG = 0x02
    QUAD_PAGE_PROG = 0x32
    BLOCK_ERASE_64K = 0xD8
    BLOCK_ERASE_32K = 0x52
    SECTOR_ERASE_4K = 0x20
    CHIP_ERASE = 0xC7 # 0x60
    ERASE_SUSPEND = 0x75
    ERASE_RESUME = 0x7A
    POWER_DOWN = 0xB9
    HIGH_PERFOM_MODE = 0xA3
    MODE_BIT_RESET = 0xFF
    RELEASE_POWER_DOWN = 0xAB
    DEVICE_ID = 0x90
    READ_UNIQ_ID = 0x4B
    JEDEC_ID = 0x9F
    READ_DATA = 0x03
    READ_DATA_FAST = 0x0B
    
    BLOCK_SIZE_WR = 64
    BLOCK_SIZE_RD = 64

    Manufacturer_IDs = {
        0x20: "Micron",
        0xEF: "Winbond"
    }

    Capacity_IDs = {
    0x14: '8M',
    0x15: '16M',
    0x16: '32M',
    0x17: '64M',
    0x18: '128M',
    0x19: '256M'
    }

    def __init__(self):
        self.port = None
        self.debug = False
        self.verbose = True

    def _write(self, data, dummies, read = False):
        for x in range(0, dummies):
            data.append(x & 0xFF)
        size = len(data)
        start = 0
        while size > 0:
            cur_size = min(64, size)
            written = self.port.write(bytes(data[start:start+cur_size]))
            start += written
            size -= written
            #self.port.flush()
            
        rd = []
        if read :
            while size > 0:
                cur_size = min(64, size)
                rdc = self.port.read(cur_size)
                rd.extend(rdc)
                size -= len(rdc)

        if self.debug:
            print('write ({}/{}): {}'.format(written, len(data), data))
            if read:
                print('read ({}/{}): {}'.format(len(rd), written, rd))
        return rd

    def _write_enable(self):
        data = [self.WRITE_ENA]
        self._write(data, 0)

    def _write_disable(self):
        data = [self.WRITE_DIS]
        self._write(data, 0)

    def _get_status(self):
        data = [self.READ_SR_1]
        sr1 = self._write(data, 1, True)
        data = [self.READ_SR_2]
        sr2 = self._write(data, 1, True)
        return [sr1[1], sr2[1]]

    def _set_status(self, status):
        data = [self.WRITE_SR, status[0], status[1]]
        self._write(data, 0)

    def _address2bytes(self, address):
        ba = []
        ba.append((address >> 16) & 0xFF)
        ba.append((address >> 8) & 0xFF)
        ba.append((address) & 0xFF)
        return ba

    def _read_data(self, address, size):
        data = [self.READ_DATA]
        data.extend(self._address2bytes(address))
        rd = self._write(data, size, True)
        return rd[4:]

    def _read_data_fast(self, address, size):
        data = [self.READ_DATA_FAST]
        data.extend(self._address2bytes(address))
        rd = self._write(data, size + 1, True)
        return rd[5:]

    def _page_program(self, address, data):
        size = len(data)
        start = 0
        while size > 0:
            self._write_enable()
            max_size = (address | 0xFF) - address + 1
            real_size = min(max_size, size)
            real_size = min(self.BLOCK_SIZE_WR - 4, real_size)
            wr_data = [self.PAGE_PROG]
            wr_data.extend(self._address2bytes(address))
            wr_data.extend(data[start:start + real_size])
            self._write(wr_data, 0)
            address += real_size
            start += real_size
            size -= real_size
            while self._isbusy():
                time.sleep(0.01)
            

    def _sector_erase(self, address):
        data = [self.SECTOR_ERASE_4K]
        data.extend(self._address2bytes(address))
        self._write(data, 0)

    def _block_erase(self, address, block64K=True):
        if block64K:
            data = [self.BLOCK_ERASE_64K]
        else:
            data = [self.BLOCK_ERASE_32K]
        data.extend(self._address2bytes(address))
        self._write(data, 0)

    def _chip_erase(self):
        data = [self.CHIP_ERASE]
        self._write(data, 0)

    def _suspend_erase(self):
        data = [self.ERASE_SUSPEND]
        self._write(data, 0)

    def _resume_erase(self):
        data = [self.ERASE_RESUME]
        self._write(data, 0)

    def _power_down(self):
        data = [self.POWER_DOWN]
        self._write(data, 0)

    def _power_up(self):
        data = [self.RELEASE_POWER_DOWN]
        self._write(data, 4)

    def _read_id(self):
        data = [self.DEVICE_ID]
        rd = self._write(data, 5, True)
        return rd[4:]

    def _get_chip_size(self):
        rd = self._read_id()
        if rd[1] == 0x13:
            return 1048576
        elif rd[1] == 0x14:
            return 2097152
        elif rd[1] == 0x15:
            return 4194304
        else:
            return 0

    def _read_iniq_id(self):
        data = [self.READ_UNIQ_ID]
        rd = self._write(data, 12, True)
        return rd[5:]

    def _read_jedec_id(self):
        data = [self.JEDEC_ID]
        rd = self._write(data, 3, True)
        return rd[1:]

    def _isbusy(self):
        sts = self._get_status()
        return True if (sts[0] & 1) > 0 else False
        
    def _ascii2hex(self, hex_data):
        hex_array = hex_data.split(' ')
        bin_data = []
        for hex in hex_array:
            try:
                bin_data.append(int(hex, 16))
            except ValueError:
                pass
        return bin_data


    def open(self, port):
        self.port = serial.Serial(port, write_timeout=0, timeout=60)
        print(self.port.port)
        self._write_enable()
        

    def get_device_info(self):
        dev_id = self._read_jedec_id()
        info = {}
        if dev_id[0] in self.Manufacturer_IDs:
            info['Manufacturer ID'] = [self.Manufacturer_IDs[dev_id[0]], dev_id[0]]
        else:
            info['Manufacturer ID'] = ['Unknown', dev_id[0]]
        info['Memory Type'] = [dev_id[1], dev_id[1]]
        if dev_id[2] in self.Capacity_IDs:
            info['Capacity'] = [self.Capacity_IDs[dev_id[2]], dev_id[2]]
        else:
            info['Capacity'] = ['Unknown', dev_id[2]]
        return info

    def get_device_status(self):
        sts = self._get_status()
        status = {
            'BUSY' : sts[0] & 1,
            'Write Enable Latch' : (sts[0] >> 1) & 1,
            'Block Protect Bits' : (sts[0] >> 2) & 7,
            'Top/Bottom Block Protect': (sts[0] >> 5) & 1,
            'Sector/Block Protect' : (sts[0] >> 6) & 1,
            'Status Register Protect 0' : (sts[0] >> 7) & 1,
            'Status Register Protect 1' : (sts[1] & 1), 
            'Quad Enable' : (sts[1] >> 1) & 1
        }
        return status
        
    def get_chip_size(self):
        id = self._read_jedec_id()
        return pow(2, (id[2] + 3))

    def erase_chip(self):
        print('Chip erasing...')
        self._write_enable()
        self._chip_erase()
        bar = ProgressBar(max_value=80).start()
        i = 0
        while self._isbusy():
            time.sleep(1)
            if i < 80:
                i = i + 1
            bar.update(i)
        bar.finish()
        print('Chip erased.')
        
    def erase_chip_partial(self, start_addr, bsize, bcount):
        print('Partial chip erasing...')
        bar = ProgressBar(max_value=bcount).start()
        i = 0
        while bcount > 0:
            self._write_enable()
            if bsize == 4*1024:
                self._sector_erase(start_addr)
            else:
                self._block_erase(start_addr)
            bar.update(i)
            i = i + 1
            bcount = bcount - 1
            start_addr = start_addr + bsize
            while self._isbusy():
                time.sleep(0.05)
        bar.finish()
        print('Chip erased')
        
    def _block_start_address(self, address, bsize):
        if bsize == '4K':
            return address & 0xFFFFF000
        elif bsize == '64K':
            return address & 0xFFFF0000
        else:
            return address
           
    def _block_end_address(self, address, bsize):
        if bsize == '4K':
            return address | 0xFFF
        elif bsize == '64K':
            return address | 0xFFFF
        else:
            return address


    def write_hex(self, address, hexfile, erasing = None):
        written = 0
        with open(hexfile, mode='rt') as hex:
            size = os.path.getsize(hexfile)
            print('Writing {} to 0x{:06x}'.format(hexfile, address))
            bar = ProgressBar(max_value=size).start()
            i = 0
            hex_data = ''
            while True:
                hex_data = ''
                while len(hex_data) < 3*self.BLOCK_SIZE_WR:
                    hx = hex.readline()
                    hx = hx[:-1]
                    if len(hx) > 0:
                        hx += ' '
                    if len(hx) == 0:
                        break
                    else:
                        hex_data += hx
                if len(hex_data) > 0:
                    self._write_enable()
                    bin_data = self._ascii2hex(hex_data)
                    self._page_program(address, bin_data)
                    address = address + len(bin_data)
                    written = written + len(bin_data)
                    # while self._isbusy():
                    #      time.sleep(1)
                    i = i + len(hex_data)
                    bar.update(i)
                else:
                    break
            print('Writing finished.')
            return written

    def read_hex(self, address, hexfile, size):
        if size is None:
            size = self._get_chip_size()
            if size == 0:
                print('Error: 0 bytes for read.')
                return

        with open(hexfile, mode='wb') as hh:
            bar = ProgressBar(max_value=size).start()
            i = 0
            while size > 0:
                rd = self._read_data(address, self.BLOCK_SIZE_RD - 4)
                hh.write(bytes(rd))
                size = size - len(rd)
                address = address + len(rd)
                bar.update(i)
                i = i + len(rd)
                time.sleep(0.01)
            bar.finish()
            print('Reading finished')
            
    def write_int(self, address, value):
        data[0] = value & 0xFF
        data[1] = (value >> 8) & 0xFF
        data[2] = (value >> 16) & 0xFF
        data[3] = (value >> 24) & 0xFF
        self._write_enable()
        self._page_program(address, data)
        
            
            
    def read(self, address, size):
        bar = ProgressBar(max_value=size).start()
        i = 0
        hh = []
        while size > 0:
            rds = min(self.BLOCK_SIZE_RD-4, size)
            rd = self._read_data(address, rds)
            hh.extend(bytes(rd))
            size = size - len(rd)
            address = address + len(rd)
            bar.update(i)
            i = i + len(rd)
            time.sleep(0.01)
        bar.finish()
        return hh
        
       
    def verify_hex(self, address, hexfile, binfile):
        with open(hexfile, mode='rt') as hex:
            size = os.path.getsize(hexfile)
            bar = ProgressBar(max_value=size).start()
            err_addr = None
            with open(binfile, mode = 'rb') as bin:
                i = 0
                hex_data = ''
                while True:
                    hex_data = ''
                    while len(hex_data) < 3*self.BLOCK_SIZE_WR:
                        hx = hex.readline()
                        hx = hx[:-1]
                        if len(hx) > 0:
                            hx += ' '
                        if len(hx) == 0:
                            break
                        else:
                            hex_data += (hx)
                    if len(hex_data) > 0:
                        bin_data = self._ascii2hex(hex_data)
                        rd_data = bin.read(len(bin_data))
                        for index, bv in enumerate(bin_data):
                            if bv != rd_data[index]:
                                err_addr = address + index
                                expected_value = bv
                                value = rd_data[index]
                                break
                        address = address + len(bin_data)
                        i = i + len(hex_data)
                        bar.update(i)
                    else:
                        break
            if err_addr is not None:
                print('Verification failed: at address 0x{:06x} expected value 0x{:02x} got 0x{:02x}'.format(err_addr, expected_value, value))
            else:
                print('Verification completed successfully.')
    
    def release_rst(self):
        self._write_disable()
        self.port.flush()
        time.sleep(1)
        

    def close(self):
        self.release_rst()
        self.port.close()
