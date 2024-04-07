#!/bin/bash

if (( $# < 2 )) ; then
	echo "params error"
	echo "Usage: $0 CODE_DIR COMMA_VER"
	echo "CODE_DIR: The parent dir of repository "Comma""
	echo "COMMA_VER: The firmware version to be included in the OTA package"
	logger "params error"
	logger "CODE_DIR: The parent dir of repository "Comma""
	logger "COMMA_VER: The firmware version to be included in the OTA package"
	exit 1
fi

CODE_DIR=$1
if [ ! -d $CODE_DIR ];then
	echo "Directory $CODE_DIR does not exist"
	logger "Directory $CODE_DIR does not exist"
	exit 1
fi
TIME_NOW=`date +%Y%m%d%H%M`
COMMA_VER=$2

cd $CODE_DIR
CODE_DIR=$(pwd)
LOG_FILE="$CODE_DIR/Comma/Comma-OTA_$TIME_NOW.log"
echo "Comma OTA generation start at $TIME_NOW" | tee $LOG_FILE
echo "CODE_DIR: $CODE_DIR" | tee -a $LOG_FILE
echo "COMMA_VER: $COMMA_VER" | tee -a $LOG_FILE

OTA_PATH="$CODE_DIR/Comma/framework/ota/tools"
echo "OTA_PATH: $OTA_PATH" | tee -a $LOG_FILE
OTA_FILE="$OTA_PATH/upgrade_firmwares.json"
echo "OTA_FILE: $OTA_PATH/upgrade_firmwares.json" | tee -a $LOG_FILE

function prepare_ota() {
	# copy the necessary ota files to OTA_PATH
	cd "$OTA_PATH"
	echo -e "\ncd $(pwd)" | tee -a $LOG_FILE
	echo "Copy Comma FW to $OTA_PATH result ${PIPESTATUS[0]}" | tee -a $LOG_FILE
    cp $CODE_DIR/Comma/target/nRF52840/freertos.bin . >> $LOG_FILE 2>&1

    echo "Replace new_firmware_version with $COMMA_VER result ${PIPESTATUS[0]}" | tee -a $LOG_FILE
	sed -i '11s/2\.0/'"$COMMA_VER"'/' "$OTA_FILE" >> $LOG_FILE 2>&1
	
	return 0
}

function ota_generation() {
	cd $OTA_PATH
	echo -e "\ncd $(pwd)" | tee -a $LOG_FILE
    echo "Generating OTA upgrade bin file result ${PIPESTATUS[0]}" | tee -a $LOG_FILE
	python ota_packager.py >> $LOG_FILE 2>&1
	
    # Find the last generated file starts with "upgrade" and get the file name
    file=$(ls -t upgrade* | head -n 1)

    # if the file exists, replace "upgrade" with "comma_$COMMA_VER" in the file name
    if [ -n "$file" ]; then
        new_file=$(echo "$file" | sed "s/upgrade/comma_$COMMA_VER/")
        mv "$file" "$new_file"
        echo "Renamed $file to $new_file result ${PIPESTATUS[0]}" | tee -a $LOG_FILE
    else
        echo "OTA generation failed! result ${PIPESTATUS[0]}" | tee -a $LOG_FILE
    fi
	
	return 0
}

prepare_ota
ota_generation

echo -e "\nComma OTA generation completed at `date +%Y%m%d%H%M`" | tee -a $LOG_FILE

exit 0
