Scripts description:

flash.py - Class implemented flash memory command

flasher.py - The script for writing .hex file to flash and reading flash to .hex file

    arguments:
        -p <port name>  - VCP name
        -i <hex file>   - Hex file for writing to flash
        -o <hex file>   - Hex file for saving data has been read from flash
        -a <address>    - Start address where hex file will be written (prefix 0x for hex value is needed), this address also used for read operation
        -s <bytes count>   - How many bytes will be read from flash
        -e              - This flag indicate full chip erasing before writing hex file. But now supported full erasing only.
        
    If -i argument is present the script erase chip and write specified hex-file to flash. 
    If -i argument is not present the script goes to read operation
    IF -o argument is not present - exit
    If -o argument is present the script starts read operation
        If -i specified bytes count for reading = sizeof(-i hes file), if not bytes count = -s argument. If bytes count = 0 will be read all data from flash
        
flash_dump.py - The script for reading some data from flash

    arguments:
        -p <port name>  - VCP name
        -a <address>    - Start address for reading
        -s <bytes count>   - How many bytes will be read from flash
        
    
flash_erase.py - The script for erasing chip
            
    arguments:
        -p <port name>  - VCP name
        -a <address>    - Start address for erasing
        -s <bytes count>   - How many bytes will be erased
        -b <block size> - Block size 4K or 64K(default)
        
flash_id.py - The script for getting chip IDs
        
        arguments:
            -p <port name>  - VCP name
        
flash_status.py - The script for getting chip status
        
        arguments:
            -p <port name>  - VCP name
            
flash_write.py - The script for writeing int value to flash

    arguments:
        -p <port name>  - VCP name
        -a <address>    - Address for writing
        -v <value>      - Integer value for writing