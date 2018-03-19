
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


    def __init__(self):
        self.port = None
        self.debug = False
        self.verbose = True

    def _write(self, data, dummies):
        for x in range(0, dummies):
            data.append(0xA)
        written = self.port.write(bytes(data))
        rd = self.port.read(written)  

        if self.debug:
            print('write ({}/{}): {}'.format(written, len(data), data))
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
        sr1 = self._write(data, 1)
        data = [self.READ_SR_2]
        sr2 = self._write(data, 1)
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
        rd = self._write(data, size)
        return rd[4:]

    def _read_data_fast(self, address, size):
        data = [self.READ_DATA_FAST]
        data.extend(self._address2bytes(address))
        rd = self._write(data, size + 1)
        return rd[5:]

    def _page_program(self, address, data):
        wr_data = [self.PAGE_PROG]
        wr_data.extend(self._address2bytes(address))
        wr_data.extend(data)
        self._write(wr_data, 0)

    def _sector_erase(self, address):
        data = [self.SECTOR_ERASE_4K]
        data.extend(self._address2bytes(address))
        self._write(data, 0)

    def _block_erase(self, address, block64K=False):
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
        rd = self._write(data, 5)
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
        rd = self._write(data, 12)
        return rd[5:]

    def _read_jedec_id(self):
        data = [self.JEDEC_ID]
        rd = self._write(data, 3)
        return rd[1:]

    def _isbusy(self):
        sts = self._get_status()
        return True if (sts[0] & 1) > 0 else False


    def open(self, port):
        self.port = serial.Serial(port, write_timeout=0, timeout=60)
        print(self.port.port)

    def get_device_info(self):
        dev_id = self._read_id()
        info = {}
        info['Manufacturer ID'] = ['Winbond Serial Flash' if dev_id[0] == 0xEF else 'Unknown', dev_id[0]]
        if dev_id[1] == 0x13:
            dev_id_str = 'W25Q80'
        elif dev_id[1] == 0x14:
            dev_id_str = 'W25Q16'
        elif dev_id[1] == 0x15:
            dev_id_str = 'W25Q32'
        else:
            dev_id_str = 'Unknown'
        info['Device ID'] =  [dev_id_str, dev_id[1]]
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

    def erase_chip(self):
        print('Chip erasing...')
        self._write_enable
        self._chip_erase
        bar = ProgressBar(max_value=80).start()
        i = 0
        while self._isbusy():
            time.sleep(1)
            if i < 80:
                i = i + 1
            bar.update(i)
        bar.finish()
        print('Chip erased.')


    def write_hex(self, address, hexfile):
        with open(hexfile, mode='rb') as hex:
            size = os.path.getsize(hexfile)
            print('Writing {} to 0x{:06x}'.format(hexfile, address))
            bar = ProgressBar(max_value=size).start()
            i = 0
            while True:
                data = hex.read(32)
                if len(data) > 0:
                    self._write_enable()
                    self._page_program(address, data)
                    address = address + len(data)
                    # while self._isbusy():
                    #      time.sleep(1)
                    i = i + len(data)
                    bar.update(i)
                else:
                    break
            print('Writing finished.')

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
                rd = self._read_data(address, 32)
                hh.write(bytes(rd))
                size = size - len(rd)
                address = address + len(rd)
                bar.update(i)
                i = i + len(rd)
                time.sleep(0.01)
            bar.finish()
            print('Reading finished')

    def verify_hex(self, address, hexfile):
        pass

    def close(self):
        self.port.close()