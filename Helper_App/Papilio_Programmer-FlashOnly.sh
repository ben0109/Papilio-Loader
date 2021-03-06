# Copyright 2009-2011 Jack Gassett
# Creative Commons Attribution license
# Made for the Papilio FPGA boards

bitfile=bitfile
	
echo "Programming to SPI Flash"
# Find device id and choose appropriate bscan bit file

device_id=`./papilio-prog.exe -j | ./gawk '{print $9}'`
return_value=$?

case $device_id in
	XC3S250E)
		echo "Programming a Papilio One 250K"
		bscan_bitfile=bscan_spi_xc3s250e.bit
		;;	
	XC3S500E)
		echo "Programming a Papilio One 500K"
		bscan_bitfile=bscan_spi_xc3s500e.bit
		;;
	*)
		echo "Unknown Papilio Board"
		;;
esac

./papilio-prog.exe -v -f "$1" -b $bscan_bitfile -sa -r
#Cause the Papilio to restart
./papilio-prog.exe -c
return_value=$?

if [ $return_value == 1 ] #If programming failed then show error.
then
	./dialog --timeout 5 --msgbox "The bit file failed to program to the Papilio, please check that the Papilio is plugged into a USB port." 15 55
	read -n1 -r -p "Press any key to continue..." key
fi
read -n1 -r -p "Press any key to continue..." key