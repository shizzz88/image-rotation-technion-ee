--()--  
--()--  This package was developed by Ofer Hofman from Sital Technology
--()--  for the benfit of VHDL designers.
--()--  
--()--  This Package supports 24 bit RGB full color bit-map format.
--()--  
--()--  This file is writen in VHDL-93 and should be compiled that way.
--()--  
--()--  This Package includes types and global signals for the 
--()--  bit-map read and write entities.
--()--  
--()--  The bit-map file contains :
--()--  1. BMP file header.
--()--  2. Picture size and file dependent information.
--()--  3. Pallete information.
--()--  4. Payload data in array.
--()--  
--()--  This package supplies a set of functions that 
--()--  reads and writes data to and from a BMP file.
--()--  
--()--  The user should use these function calls to read and write from 
--()--  the BMP file. 
--()--  
--()-- 
--()-- Image data base -----------------------------------------------
--()-- The Image data base holds the picture. It is a two dimentional array.
--()-- At point (0,0) of it it holds the lower left pixel information
--()-- Point (Hight,width) holds the top right pixel of the BMP image
----------------------------------------------------------------------------
--()-- 24 bit RGB data bit map for Windows PC:
--()-- 14 bytes header
--()-- 40 bytes info
--()-- Rows :Each Row is a set of triplets of B(lsb) G R(msb) and alligned to multiples of 4 bytes.
--()--          So zero padding could be one to three bytes at the end.
--()--          The first byte is teh blue component, the second is the green the third is the red.	
------------------------------------------------------------------------------------------------------------------
--
-- Changes   Date    	By  			Description
--			 25.8.2008  Moshe Porian	(1) The last pixel of the first line is not read correct and not put well 
--											in case of the number of bytes of the picture file is not divded by 4
--                                          (set of integer is 4 bytes long). So,Declaring type file as set of 
--                                          characters, which force reading for each byte resolve the bug.
------------------------------------------------------------------------------------------------------------------

LIBRARY IEEE, std;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;

package BMP_io_package is

    constant image_maximum_width : natural := 800; -- 1200;
    constant image_maximum_hight : natural := 600; -- 1200;

    Type pic_array is array(1 to image_maximum_hight,1 to image_maximum_width) of integer range 0 to 255;
    Type RGB is (R, G, B);
    Type RGB_pic_array is array(RGB) of pic_array;
 
    procedure get_image(File_name : in string;
                        pic: out RGB_pic_array;
                        H_size : out natural;
                        V_size : out natural);

    procedure put_image(File_name : in string; 
                        pic: in RGB_pic_array;
                        H_size : in natural;
                        V_size : in natural);
	
	procedure compare_image_proc (
						File_name 				: in  string;
						Reference_File_name 	: in  string;
						Result_File_name 		: in  string );					
						
end BMP_io_package;

PACKAGE BODY BMP_io_package IS

    ---integer representation for the bytes.
    ---byte number 3 is the MSB of the integer
    ---byte number 0 is the LSB of the integer
    ---The file has : (lsb)424DC8D4(msb)  than the value is D4C84D42 or -725070526
    
	type CharFile is file of character; -- each byte is read separatelly 
	
    function GetByte(i : integer; Byte_num: natural := 0) return natural is
        VARIABLE    v : STD_LOGIC_VECTOR(31 downto 0);
    begin
        v := conv_std_logic_vector(i,32);
        CASE (byte_num) IS
            WHEN 1 =>       return conv_integer(unsigned(v(15 downto 08)));
            WHEN 2 =>       return conv_integer(unsigned(v(23 downto 16)));
            WHEN 3 =>       return conv_integer(unsigned(v(31 downto 24)));
            WHEN OTHERS =>  return conv_integer(unsigned(v(07 downto 00)));
        END CASE;        
    end;
    
-------------------------------------------------
--- 24 bits BMP Reader   
-------------------------------------------------

----Format :     Header is 14 bytes includes :
----Format :     Signature  2 bytes 'BM'
----Format :     FileSize   4 bytes : File size in bytes
----Format :     reserved   4 bytes : unused (=0)
----Format :     DataOffset 4 bytes : File offset to Raster Data (=54 for 24 bit mode)
----Format :
----Format :     InfoHeader  40 bytes Windows Structure: BITMAPINFOHEADER
----Format :   Includes 
----Format :     Size 4 bytes   : Size of InfoHeader = 40 
----Format :     Width 4 bytes  : Bitmap Width                     (18,19,20,21)
----Format :     Height4 bytes  : Bitmap Height                    (22,23,24,25)
----Format :     Planes 2 bytes  : Number of Planes (=1)
----Format :     BitCount 2 bytes : Bits per Pixel                (bytes 28, 29)
----Format :            when 1  = monochrome palette. NumColors = 1   
----Format :            when 4  = 4  bit palletized. NumColors = 16   
----Format :            when 8  = 8  bit palletized. NumColors = 256  
----Format :            when 16 = 16 bit RGB. NumColors = 65536 (?)  
----Format :            when 24 = 24 bit RGB. NumColors = 16M
----Format :     Compression 4 bytes : Type of Compression   
----Format :                 0 = BI_RGB   no compression   
----Format :                 1 = BI_RLE8 8bit RLE encoding   
----Format :                 2 = BI_RLE4 4bit RLE encoding
----Format :     ImageSize   :4 bytes (compressed) Size of Image  
----Format :         It is valid to set this =0 if Compression = 0
----Format :     XpixelsPerM 4 bytes : horizontal resolution: Pixels/meter
----Format :     YpixelsPerM 4 bytes : vertical resolution: Pixels/meter
----Format :     ColorsUsed  4 bytes : Number of actually used colors
----Format :     ColorsImportant 4 bytes : Number of important colors  
----Format :         0 = all

    procedure get_image(File_name : in string;
                        pic: out RGB_pic_array;
                        H_size : out natural;
                        V_size : out natural) is

        FILE 		f  				: CharFile;
        VARIABLE 	status  		: file_open_status;
        VARIABLE 	temp    		: natural;
        VARIABLE 	file_length 	: natural;
        VARIABLE 	Bytes_per_row 	: natural;
        VARIABLE 	Image_width 	: natural;
        VARIABLE 	Image_hight 	: natural;

        ---this function returns the next byte in the file
        --- it reads an integer, holds it in a temp integer and holds 
        --- the position of the byte that was read from it. if the next byte is the 5th,
        --- an new integer is read and its first byte is returned.
        VARIABLE temp_char : character;

        impure function next_byte return natural IS
            VARIABLE i : natural;
        BEGIN
	        if not endfile(f) then 
	              read(f, temp_char); 
	        else
	            report "Get_Image of BMP file found premature End Of File. check file "& File_name & " Stopping simulation !"
	            severity note;
	        end if;		
		    i := character'pos(temp_char); 
			return i;
        END;

    BEGIN
        -- Open the file for read
        File_open(status, f , File_name);
        IF status /= open_ok THEN
            report "BMP_IO Message: File Open Error. Unable to open picture file: "&File_name
            Severity Failure;
            File_close( f );
            wait;
        END IF;

--        --algorithm :
--        --    read first 2 dwords.
--        --    Find file length
--        --    loop on file length/4 and fill byte array.
--        --    analyse file according to file array.
    
        TEMP := Next_Byte;
        ASSERT TEMP = 16#42# --'B'
        REPORT "BMP File format error in file " & file_name
        SEVERITY failure;
        TEMP := Next_Byte;
        ASSERT TEMP = 16#4D# --'M'
        REPORT "BMP File format error in file " & file_name
        SEVERITY failure;

        file_length := Next_Byte + Next_Byte*256 + Next_Byte*2**16 + next_byte*2**24;

        --strip off 'unused' 'raster offset' and header size. (integer each).
        for i in 1 to 12 loop temp := Next_Byte; end loop;

        Image_width := Next_Byte + Next_Byte*256 + Next_Byte*2**16 + next_byte*2**24;
        Image_hight := Next_Byte + Next_Byte*256 + Next_Byte*2**16 + next_byte*2**24;

        temp := Next_Byte; --number of planes
        temp := Next_Byte; --number of planes
        
        assert Next_byte = 24 
            report "BMP File format only supports 24 bit resolution images. Incorrect file format in " & file_name
            severity failure;

        temp := Next_Byte; --MSB of resolution

        for i in 1 to 6*4 loop temp := Next_Byte; end loop; --compression till end of header
            
        Bytes_per_row := (Image_width*3 + 3) / 4;
        Bytes_per_row := Bytes_per_row * 4;
        
        For row in image_hight-1 downto 0 loop
            for column in 0 to Bytes_per_row - 1 loop
                if column mod 3 = 0 then 
                    pic(B)(row+1,column/3+1) := Next_Byte;
                elsif column mod 3 = 1 then 
                    pic(G)(row+1,column/3+1) := Next_Byte;
                elsif column mod 3 = 2 then 
                    pic(R)(row+1,column/3+1) := Next_Byte;
                end if;
            end loop;
        end loop;
        
        File_close( f );

        H_size := image_width;
        V_size := image_hight;

    END;

-------------------------------------------------
--- 24 bits BMP Writer 
-------------------------------------------------
----Format :     Header is 14 bytes includes :
----Format :     Signature  2 bytes 'BM'
----Format :     FileSize   4 bytes : File size in bytes
----Format :     reserved   4 bytes : unused (=0)
----Format :     DataOffset 4 bytes : File offset to Raster Data (=54 for 24 bit mode)
----Format :
----Format :     InfoHeader  40 bytes Windows Structure: BITMAPINFOHEADER
----Format :   Includes 
----Format :     Size 4 bytes   : Size of InfoHeader = 40 
----Format :     Width 4 bytes  : Bitmap Width                     (18,19,20,21)
----Format :     Height4 bytes  : Bitmap Height                    (22,23,24,25)
----Format :     Planes 2 bytes  : Number of Planes (=1)
----Format :     BitCount 2 bytes : Bits per Pixel                (bytes 28, 29)
----Format :            when 1  = monochrome palette. NumColors = 1   
----Format :            when 4  = 4  bit palletized. NumColors = 16   
----Format :            when 8  = 8  bit palletized. NumColors = 256  
----Format :            when 16 = 16 bit RGB. NumColors = 65536 (?)  
----Format :            when 24 = 24 bit RGB. NumColors = 16M
----Format :     Compression 4 bytes : Type of Compression   
----Format :                 0 = BI_RGB   no compression   
----Format :                 1 = BI_RLE8 8bit RLE encoding   
----Format :                 2 = BI_RLE4 4bit RLE encoding
----Format :     ImageSize   :4 bytes (compressed) Size of Image  
----Format :         It is valid to set this =0 if Compression = 0
----Format :     XpixelsPerM 4 bytes : horizontal resolution: Pixels/meter
----Format :     YpixelsPerM 4 bytes : vertical resolution: Pixels/meter
----Format :     ColorsUsed  4 bytes : Number of actually used colors
----Format :     ColorsImportant 4 bytes : Number of important colors  
----Format :         0 = all

    procedure put_image(File_name : in string; 
                        pic: in RGB_pic_array;
                        H_size : in natural;
                        V_size : in natural) IS
 
		FILE 		f  				: CharFile;
        VARIABLE 	status  		: file_open_status;
        VARIABLE 	file_length 	: natural;
        VARIABLE 	Bytes_per_row 	: natural;
        VARIABLE 	Image_width 	: natural:=H_size;
        VARIABLE 	Image_hight 	: natural:=V_size;

		procedure write_byte(i : natural) IS  
        BEGIN
            write(f, character'val(i)); 
        END;  
		
    Begin
        -- Open the file for read
        File_open(status, f , File_name, write_mode);
        IF status /= open_ok THEN
            report "BMP_IO Message: File Open Error. Unable to open output picture file: " & File_name
            Severity Failure;
            File_close( f );
            wait;
        END IF;

       --algorithm :
       -- same as the get_image but in the other direction
        write_byte(16#42#);
        write_byte(16#4D#);

        Bytes_per_row := (Image_width*3 + 3) / 4;
        Bytes_per_row := Bytes_per_row * 4;

        file_length := (Bytes_per_row * Image_hight) + 54;
        write_byte((file_length      ) mod 256);
        write_byte((file_length/2**08) mod 256);
        write_byte((file_length/2**16) mod 256);
        write_byte((file_length/2**24) mod 256);

        ----Format :     reserved   4 bytes : unused (=0)
        for i in 1 to 4 loop write_byte(0); end loop;
        ----Format :     DataOffset 4 bytes : File offset to Raster Data (=54 for 24 bit mode)
        write_byte(54);
        for i in 1 to 3 loop write_byte(0); end loop;
        ----Format :     Size 4 bytes   : Size of InfoHeader = 40 
        write_byte(40);
        for i in 1 to 3 loop write_byte(0); end loop;
        ----Format :     Width 4 bytes  : Bitmap Width                     (18,19,20,21)
        write_byte((Image_width      ) mod 256);
        write_byte((Image_width/2**08) mod 256);
        write_byte((Image_width/2**16) mod 256);
        write_byte((Image_width/2**24) mod 256);
        ----Format :     Height4 bytes  : Bitmap Height                    (22,23,24,25)
        write_byte((Image_hight      ) mod 256);
        write_byte((Image_hight/2**08) mod 256);
        write_byte((Image_hight/2**16) mod 256);
        write_byte((Image_hight/2**24) mod 256);

        ----Format :     Planes 2 bytes  : Number of Planes (=1)
        write_byte(1);
        write_byte(0);
        ----Format :     BitCount 2 bytes : Bits per Pixel                (bytes 28, 29)
        write_byte(24);
        write_byte(0);
        ----Format :     Compression 4 bytes : Type of Compression   
        ----Format :                 0 = BI_RGB   no compression   
        for i in 1 to 4 loop write_byte(0); end loop;
        ----Format :     ImageSize   :4 bytes (compressed) Size of Image  
        ----Format :         It is valid to set this =0 if Compression = 0
        for i in 1 to 4 loop write_byte(0); end loop;
        ----Format :     XpixelsPerM 4 bytes : horizontal resolution: Pixels/meter
        write_byte(117);
        write_byte(10);
        write_byte(0);
        write_byte(0);
        ----Format :     YpixelsPerM 4 bytes : vertical resolution: Pixels/meter
        write_byte(117);
        write_byte(10);
        write_byte(0);
        write_byte(0);
        ----Format :     ColorsUsed  4 bytes : Number of actually used colors
        ----Format :     ColorsImportant 4 bytes : Number of important colors  
        ----Format :         0 = all
        for i in 1 to 8 loop write_byte(0); end loop;

        For row in image_hight-1 downto 0 loop
            for column in 0 to Bytes_per_row - 1 loop
                if column mod 3 = 0 then 
                    write_byte(pic(B)(row+1,column/3+1));
                elsif column mod 3 = 1 then 
                    write_byte(pic(G)(row+1,column/3+1));
                elsif column mod 3 = 2 then 
                    write_byte(pic(R)(row+1,column/3+1));
                end if;
            end loop;
        end loop;
        write_byte(0);
        write_byte(0);
        write_byte(0);
        write_byte(0);
        File_close( f );
    End;
	
	
	procedure compare_image_proc (
		File_name 				: in  string;
		Reference_File_name 	: in  string;
		Result_File_name 		: in  string ) is 
		
		variable screen_pixel,screen_line		: natural; 
		variable H_size,Ref_H_size 				: natural; 
		variable V_size,Ref_V_size 				: natural;
		variable image,Ref_image,Result_image	: RGB_pic_array; 
		variable No_Difference					: boolean := true ;
		
-- ==================================			 
		function find_char_in_str(constant str : in string; constant char : in character) return integer is
		  variable pos : integer := 1;
		begin
			if (str'length > 0) then 
				while pos <= str'length loop
					if str(pos) = char then
						exit ;
					else
						pos := pos + 1;
					end if;
				end loop; 
			else
				return 0 ;
			end if;	  
			if pos = str'length + 1 then  
				return 0 ;
			else
				return pos ;
			end if ;
		end function find_char_in_str ;	  
		
-- =================================
	begin	 
		
		get_image(File_name,image,H_size,V_size); 
		get_image(Reference_File_name,Ref_image,Ref_H_size,Ref_V_size);	 
		
		if H_size /= Ref_H_size then 
			report "Time: "& time'image(now) & ", DETECT DIFFERENCE BETWEEN HORIZONTAL SIZE OF THE FILE " & File_name(1 to find_char_in_str(File_name, nul)-1) & ": "& integer'image(H_size) & ", WITH HORIZONTAL SIZE OF THE REFERENCE FILE " & Reference_File_name(1 to find_char_in_str(Reference_File_name, nul)-1) &  ": " & integer'image(Ref_H_size) & " ."
				severity WARNING;
			if H_size > Ref_H_size then	
				report "Time: "& time'image(now) & ", COMPARE WILL BE EXECUTE WITH THE LOWER HORIZONTAL SIZE FROM THE REFERENCE FILE " & Reference_File_name(1 to find_char_in_str(Reference_File_name, nul)-1) & " - " & integer'image(Ref_H_size)
					severity WARNING;
				H_size := Ref_H_size ; 
			else  
				report "Time: "& time'image(now) & ", COMPARE WILL BE EXECUTE WITH THE LOWER HORIZONTAL SIZE FROM THE FILE " & File_name(1 to find_char_in_str(File_name, nul)-1) & " - " & integer'image(H_size)
					severity WARNING;
				H_size := H_size ; 
			end if ;  
		end if ;
		
		if V_size /= Ref_V_size then
			report "Time: "& time'image(now) & ", DETECT DIFFERENCE BETWEEN VERTICAL SIZE OF THE FILE " & File_name(1 to find_char_in_str(File_name, nul)-1) & ": "& integer'image(V_size) & ", WITH VERTICAL SIZE OF THE REFERENCE FILE " & Reference_File_name(1 to find_char_in_str(Reference_File_name, nul)-1) &  ": " & integer'image(Ref_V_size) & " ."
				severity WARNING;
			if V_size > Ref_V_size then
				report "Time: "& time'image(now) & ", COMPARE WILL BE EXECUTE WITH THE LOWER VERTICAL SIZE FROM THE REFERENCE FILE " & Reference_File_name(1 to find_char_in_str(Reference_File_name, nul)-1) & " - " & integer'image(Ref_V_size)
					severity WARNING;
				V_size := Ref_V_size ; 
			else  
				report "Time: "& time'image(now) & ", COMPARE WILL BE EXECUTE WITH THE LOWER VERTICAL SIZE FROM THE DUMPED FILE " & File_name(1 to find_char_in_str(File_name, nul)-1) & " - " & integer'image(V_size)
					severity WARNING;
				V_size := V_size ; 
			end if ;  
		end if ;
		
		screen_line := 1;
		while screen_line <= V_size loop	        -- screen line counter
	
		  	screen_pixel := 1;
			while screen_pixel <= H_size loop	     -- screen pixel counter
				
				Result_image(R)(screen_line,screen_pixel) 	:= 0 ; 
				Result_image(G)(screen_line,screen_pixel) 	:= 0;
				Result_image(B)(screen_line,screen_pixel) 	:= 0;
				
				if (image(R)(screen_line,screen_pixel) /= Ref_image(R)(screen_line,screen_pixel)) or
				(image(G)(screen_line,screen_pixel) /= Ref_image(G)(screen_line,screen_pixel)) or
				(image(B)(screen_line,screen_pixel) /= Ref_image(B)(screen_line,screen_pixel)) then
					Result_image(R)(screen_line,screen_pixel) 	:= 255 ;  
					No_Difference := false ;
				end if ;
													  
				screen_pixel := screen_pixel + 1;
		  	end loop;
			  
			screen_line := screen_line + 1;
		end loop;
		
		put_image(Result_File_name,Result_image,H_size,V_size);	
		
		assert No_Difference 
			report "Time: "& time'image(now) & ", DETECT DIFFERENCE BETWEEN FILE " & File_name(1 to find_char_in_str(File_name, nul)-1) & " WITH REFERENCE FILE " & Reference_File_name(1 to find_char_in_str(Reference_File_name, nul)-1) & ", SEE RESULTS IN FILE " & Result_File_name(1 to find_char_in_str(Result_File_name, nul)-1)
				severity ERROR;
					
	end procedure compare_image_proc;
	
	
	
END BMP_io_package;    