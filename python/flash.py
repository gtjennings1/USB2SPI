
import serial

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

    def _write(self, data, dummies):
        for x in range(0, dummies - 1):
            data.append(0)
        self.port.write(data)
        return self.port.read(len(data))

    def _write_enable(self):
        data = bytes([self.WRITE_ENA])
        self._write(data, 0)

    def _write_disable(self):
        data = bytes([self.WRITE_DIS])
        self._write(data, 0)

    def _get_status(self):
        data = bytes([self.READ_SR_1])
        sr1 = self._write(data, 1)
        data = bytes([self.READ_SR_2])
        sr2 = self._write(data, 1)
        return bytes([sr1[1], sr2[1]])

    def _set_status(self, status):
        data = bytes([self.WRITE_SR, status[0], status[1]])
        self._write(data, 0)

    def _address2bytes(self, address):
        ba = []
        ba.append((address >> 16) & 0xFF)
        ba.append((address >> 8) & 0xFF)
        ba.append((address) & 0xFF)
        return bytes(ba)

    def _read_data(self, address, size):
        data = bytes([self.READ_DATA])
        data.join(self._address2bytes(address))
        rd = self._write(data, size)
        return rd[4:]

    def _read_data_fast(self, address, size):
        data = bytes([self.READ_DATA_FAST])
        data.join(self._address2bytes(address))
        rd = self._write(data, size + 1)
        return rd[5:]

    def _page_program(self, address, data):
        data = bytes([self.PAGE_PROG])
        data.join(self._address2bytes(address))
        data.join(bytes(data))
        self._write(data, 0)

    def _sector_erase(self, address):
        data = bytes([self.SECTOR_ERASE_4K])
        data.join(self._address2bytes(address))
        self._write(data, 0)

    def _block_erase(self, address, block64K=False):
        if block64K:
            data = bytes([self.BLOCK_ERASE_64K])
        else:
            data = bytes([self.BLOCK_ERASE_32K])
        data.join(self._address2bytes(address))
        self._write(data, 0)

    def _chip_erase(self):
        data = bytes([self.CHIP_ERASE])
        self._write(data, 0)

    def _suspend_erase(self):
        data = bytes([self.ERASE_SUSPEND])
        self._write(data, 0)

    def _resume_erase(self):
        data = bytes([self.ERASE_RESUME])
        self._write(data, 0)

    def _power_down(self):
        data = bytes([self.POWER_DOWN])
        self._write(data, 0)

    def _power_up(self):
        data = bytes([self.RELEASE_POWER_DOWN])
        self._write(data, 4)

    def _read_id(self):
        data = bytes([self.DEVICE_ID])
        rd = self._write(data, 5)
        return rd[4:]

    def _read_iniq_id(self):
        data = bytes([self.READ_UNIQ_ID])
        rd = self._write(data, 12)
        return rd[5:]

    def _read_jedec_id(self):
        data = bytes([self.JEDEC_ID])
        rd = self._write(data, 3)
        return rd[1:]

    def _isbusy(self):
        sts = self._get_status()
        return True if (sts[0] & 1) > 0 else False


    def open(self, port):
        self.port = serial.Serial(port)
        print(self.port.port)

    def get_device_info(self):
        dev_id = self._read_id()
        info = {'Manufacturer ID':['Winbond Serial Flash' if dev_id[0] == 0xEF else 'Unknown', dev_id[0]]}
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
        self._write_enable
        self._chip_erase
        while self._isbusy:
            pass

    def write_hex(self, address, hexfile):
        with open(hexfile, mode='rb') as hex:
            while True:
                data = hex.read(256)
                if len(data) > 0:
                    self._write_enable
                    self._page_program(address, data)
                    address = address + len(data)
                else:
                    break


    def close(self):
        self.port.close()