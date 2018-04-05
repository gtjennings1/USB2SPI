# USB2SPI

python flasher.py -p COM19 -i RGB_LED_BLINK.hex -o read.bin -b 4 > flasher.log

('under the hood' command examples)
python flash_erase.py -p COM19 -a 0 -s 0

python flash_write.py -p COM19 -a 0 -v 256

python flash_dump.py -p COM19 -a 0 -s 4