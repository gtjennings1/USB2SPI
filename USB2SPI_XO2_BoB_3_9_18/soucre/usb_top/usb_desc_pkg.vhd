library ieee;
use ieee.std_logic_1164.all;

package usb_desc_pkg is 

	constant VENDORSTR : string := "Grant Jennings & Co";
	constant PRODUCTSTR: string := "USB Flash Programer";
	constant SERIALSTR_LEN : integer := 4; 	
	type usb_desc is record 
		-- Vendor ID to report in device descriptor.
        VENDORID :      std_logic_vector(15 downto 0);
        -- Product ID to report in device descriptor.
        PRODUCTID :     std_logic_vector(15 downto 0);
        -- Product version to report in device descriptor.
        VERSIONBCD :    std_logic_vector(15 downto 0);
        -- Optional description of manufacturer (max 126 characters).
        VENDORSTR :     string(1 to VENDORSTR'high);
        -- Optional description of product (max 126 characters).
        PRODUCTSTR :    string(1 to PRODUCTSTR'high);
        -- Optional product serial number (max 126 characters).
        SERIALSTR :     string(1 to SERIALSTR_LEN);
	end record usb_desc;
	
	
	constant GENERAL_VCP_DESC : usb_desc := (
		VENDORID => X"FB9A",
		PRODUCTID => X"FB9A",
		VERSIONBCD => X"0020",
		VENDORSTR => VENDORSTR,
		PRODUCTSTR => PRODUCTSTR,
		SERIALSTR => "0000");
		
	constant SILABS_CP210x_DESC : usb_desc := (
		VENDORID => X"10C4",
		PRODUCTID => X"EA60",
		VERSIONBCD => X"0100",
		VENDORSTR => VENDORSTR,
		PRODUCTSTR => PRODUCTSTR,
		SERIALSTR => "0001");
		
	constant FDTI_DESC : usb_desc := (
		VENDORID => X"0403",
		PRODUCTID => X"6001",
		VERSIONBCD => X"1400",
		VENDORSTR => VENDORSTR,
		PRODUCTSTR => PRODUCTSTR,
		SERIALSTR => "0000");

end package usb_desc_pkg;