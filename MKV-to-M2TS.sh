#!/bin/bash
#
# A simple wrapper around the tsmuxeR
# Creates a M2TS from a MKV, assuming video is MPEG4 and audio is AC3 or DTS
# Keeps any subs so long as they are SRT formatted inside the MKV container
#
# v0.1 initial version
# v0.2 added DTS support
# v0.3 changed to tsmuxer linux version + added multiple audio lang support
# v1.0 forked from v0.3
#
# Usage: MKV-to-M2TS filename.mkv
#
# References
# - http://sticky123.blogspot.com/2008/03/remuxing-mkv-to-m2ts-on-linux.html
# - http://ubuntuforums.org/showthread.php?t=1029760
# - http://www.bitburners.com/articles/create-avchd-discs-with-subtitles-using-tsmuxer/4047/comment-page-1/
# - http://www.spikedsoftware.co.uk/blog/index.php/2009/04/04/bashing-mkvs-into-m2ts/
# - http://github.com/JakeWharton/mkvdts2ac3
#

function usage {
    echo "Usage"
    echo "  ${0} movie.mkv"
    echo ""
    echo "You can also pass the following optional parameter"
    echo "  --split    : If required, the .M2TS output will be split at a boundary less than 4GB for FAT32 compatibility"
    echo
    exit 1
}

# Pass in the .mkv filename
function get_info {	
	MKV_FILENAME=${1}
	
	local MKV_TRACKS=`${CMD_MKTEMP}`
	${CMD_MKVMERGE} -i ${MKV_FILENAME} > ${MKV_TRACKS}
	local MKV_INFO=`${CMD_MKTEMP}`
	${CMD_MKVINFO} ${MKV_FILENAME} > ${MKV_INFO}

	# Get the track ids for audio/video assumes one audio and one video track currently.
	VIDEO_ID=`${CMD_GREP} video ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f3 | ${CMD_SED} 's/://'`
	AUDIO_ID=`${CMD_GREP} audio ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f3 | ${CMD_SED} 's/://'`
	SUBS_ID=`${CMD_GREP} subtitles ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f3 | ${CMD_SED} 's/://'`

	# Get the audio/video format. Strip the V_, A_ and brackets.
	VIDEO_FORMAT=`${CMD_GREP} video ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f5 | ${CMD_SED} 's/(\|V_\|)//g'`
	AUDIO_FORMAT=`${CMD_GREP} audio ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f5 | ${CMD_SED} 's/(\|A_\|)//g'`

	# Are there any subtitles in the .mkv
	if [ -z ${SUBS_ID} ]; then
		SUBS_FORMAT=""
	else
		SUBS_FORMAT=`${CMD_GREP} subtitles ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f5 | ${CMD_SED} 's/(\|S_\|)//g'`
	fi

	# Get the video frames per seconds (FPS), number of audio channels and audio sample rate.
	if [ $VIDEO_ID -lt $AUDIO_ID ]; then
	    # Video is before Audio track
    	VIDEO_FPS=`${CMD_GREP} fps ${MKV_INFO} | ${CMD_SED} -n 1p | ${CMD_CUT} -d'(' -f2 | ${CMD_CUT} -d' ' -f1`
	else
    	# Video is after Audio track
	    VIDEO_FPS=`${CMD_GREP} fps ${MKV_INFO} | ${CMD_SED} -n 2p | ${CMD_CUT} -d'(' -f2 | ${CMD_CUT} -d' ' -f1`
	fi

	VIDEO_WIDTH=`${CMD_GREP} "Pixel width" ${MKV_INFO} | ${CMD_CUT} -d':' -f2 | ${CMD_SED} 's/ //g'`
	VIDEO_HEIGHT=`${CMD_GREP} "Pixel height" ${MKV_INFO} | ${CMD_CUT} -d':' -f2 | ${CMD_SED} 's/ //g'`

	# Get the sample rate
	AUDIO_RATE=`${CMD_GREP} -A 1 "Audio track" ${MKV_INFO} | ${CMD_SED} -n 2p | ${CMD_CUT} -c 27-31`        

	# Get the number of channels
	AUDIO_CH=`${CMD_GREP} Channels ${MKV_INFO} | ${CMD_SED} -e 1q | ${CMD_CUT} -d':' -f2 | ${CMD_SED} 's/ //g'`
	
	# Is the video h264 and audio AC3 or DTS?
	if [ "${VIDEO_FORMAT}" != "MPEG4/ISO/AVC" ]; then
		echo "ERROR! The Video track is not H.264. I can't process ${VIDEO_FORMAT}, please use a different tool."
		exit 1
	elif [ "${AUDIO_FORMAT}" != "DTS" ] && [ "${AUDIO_FORMAT}" != "AC3" ]; then
		echo "ERROR! The audio track is not DTS or AC3. I can't process ${AUDIO_FORMAT}, please use a different tool."
		exit 1
	else
		echo -e "Video\t : Track ${VIDEO_ID} and of format ${VIDEO_FORMAT} (${VIDEO_WIDTH}x${VIDEO_HEIGHT} @ ${VIDEO_FPS}fps)"
		echo -e "Audio\t : Track ${AUDIO_ID} and of format ${AUDIO_FORMAT} with ${AUDIO_CH} channels @ ${AUDIO_RATE}hz"
		if [ -z ${SUBS_ID} ]; then
			echo -e "Subs\t : none"
		else
			# Check the format of the subtitles. If they are not TEXT/UTF8 we can't use them.
			if [ "${SUBS_FORMAT}" != "TEXT/UTF8" ]; then
				SUBS_ID=""
				echo -e "Subs\t : ${SUBS_FORMAT} is not supported, skipping subtitle processing"
			else
				echo -e "Subs\t : Track ${SUBS_ID} and of format ${SUBS_FORMAT}"
			fi
		fi	
	fi
	
	# Clean up the temp files
	${CMD_RM} ${MKV_TRACKS} 2>/dev/null
	${CMD_RM} ${MKV_INFO} 2>/dev/null
}

# Define the commands we will be using. If you don't have them, get them! ;-)

REQUIRED_TOOLS="chmod file stat grep cut sed rm mktemp mkvmerge mkvinfo mkvextract tsMuxeR dcadec aften"
which ${REQUIRED_TOOLS} >/dev/null
        
if [ $? -eq 1 ]; then
    echo "ERROR! One of the required tools is missing."
    echo "The following tools are required for ${0} to operate:"
    echo " * ${REQUIRED_TOOLS}"
    exit 1
fi   

CMD_CHMOD=`which chmod`
CMD_FILE=`which file`
CMD_STAT=`which stat`
CMD_GREP=`which grep`
CMD_CUT=`which cut`
CMD_SED=`which sed`
CMD_RM=`which rm`
CMD_MKTEMP=`which mktemp`
CMD_MKVMERGE=`which mkvmerge`
CMD_MKVINFO=`which mkvinfo`
CMD_MKVEXTRACT=`which mkvextract`
CMD_TSMUXER=`which tsMuxeR`
CMD_DCADEC=`which dcadec`
CMD_AFTEN=`which aften`

# Get the first parameter passed in and validate it.
if [ $# -lt 1 ]; then
    echo "ERROR! ${0} requires a .mkv file as input"	
    echo    
	usage
elif [ "${1}" == "-h" ] || [ "${1}" == "--h" ] || [ "${1}" == "-help" ] || [ "${1}" == "--help" ] || [ "${1}" == "-?" ]; then
    usage
else    
    MKV_FILENAME=${1}
        
    # Is the .mkv a real Matroska file?
    MKV_VALID=`${CMD_FILE} ${MKV_FILENAME} | ${CMD_GREP} Matroska`
    if [ -z "${MKV_VALID}" ]; then
        echo "ERROR! ${0} requires valid a Matroska file as input. \"${1}\" is not a Matroska file."
        echo
        usage
    fi	    
    
    # It appears to be a valid Matroska file.
    BASENAME=$(basename "$1" .mkv)        
    M2TS_FILENAME=${BASENAME}.m2ts
    META_FILENAME=${BASENAME}.meta
    
    # Audio filenames should we need to transcode DTS to AC3.
    AC3_FILENAME=${BASENAME}.ac3
    DTS_FILENAME=${BASENAME}.dts
    shift
fi

# Init optional parameters.
M2TS_SPLIT_SIZE=0

# Check for optional parameters
while [ $# -gt 0 ]; 
do	
	case "${1}" in
		-s|--split)
            # Get the size of the .mkv file in bytes (b)
            MKV_SIZE=`${CMD_STAT} ${MKV_FILENAME} | ${CMD_GREP} Size | ${CMD_CUT} -f1 | ${CMD_SED} 's/ \|Size://g'`

            # The PS3 can't play files which are bigger than 4GB and FAT32 doesn't like files bigger than 4GB.
            # Lets figure out the M2TS split size should in kilo-bytes (kb)
            if [ ${MKV_SIZE} -ge 12884901888 ]; then    
	            # >= 12gb : Split into 3.5GB chunks ensuring PS3 and FAT32 compatibility
	            M2TS_SPLIT_SIZE="3670016"
            elif [ ${MKV_SIZE} -ge 9663676416 ]; then   
	            # >= 9gb  : Divide .mkv filesize by 3 and split by that amount
	            M2TS_SPLIT_SIZE=$(((${MKV_SIZE} / 3) / 1024))
            elif [ ${MKV_SIZE} -ge 4294967296 ]; then   
	            # >= 4gb  : Divide .mkv filesize by 2 and split by that amount
	            M2TS_SPLIT_SIZE=$(((${MKV_SIZE} / 2) / 1024))
            fi										                        
            shift;;        
	esac    
done

# Add 'KB' to the split size for tsMuxeR compatibility
M2TS_SPLIT_SIZE=`echo "${M2TS_SPLIT_SIZE}KB"`

# Get the required infor from the MKV file and validate we can process it.
get_info ${MKV_FILENAME}

# Remove .meta file from previous run. Then create a new tsMuxeR .meta file.
${CMD_RM} ${META_FILENAME} 2>/dev/null

# Add split options, if required.
if [ "${M2TS_SPLIT_SIZE}" != "0KB" ]; then
    echo "MUXOPT --no-pcr-on-video-pid --new-audio-pes --vbr --vbv-len=500 --split-size=${M2TS_SPLIT_SIZE}" >> ${META_FILENAME}
else
    echo "MUXOPT --no-pcr-on-video-pid --new-audio-pes --vbr --vbv-len=500" >> ${META_FILENAME}    
fi    

# Adding video stream.
echo "V_MPEG4/ISO/AVC, \"${MKV_FILENAME}\", fps=${VIDEO_FPS}, level=4.1, insertSEI, contSPS, ar=As source, track=${VIDEO_ID}, lang=und" >> ${META_FILENAME}

# Add audio stream.
if [ "${AUDIO_FORMAT}" == "AC3" ]; then
    # We have AC3, no need to transcode.
    echo "A_AC3, \"${MKV_FILENAME}\", track=${AUDIO_ID}, lang=und" >> ${META_FILENAME}
else    
    # We have DTS, transcoding required.
    ${CMD_MKVEXTRACT} tracks "${MKV_FILENAME}" ${AUDIO_ID}:"${DTS_FILENAME}" 
    ${CMD_DCADEC} -o wavall "${DTS_FILENAME}" | ${CMD_AFTEN} -v 0 -readtoeof 1 - "${AC3_FILENAME}"
    echo "A_AC3, \"${AC3_FILENAME}\", track=1, lang=und" >> ${META_FILENAME}
fi

# Add any subtitles, if required.
if [ "${SUBS_ID}" != "" ]; then
    echo "S_TEXT/UTF8, \"${MKV_FILENAME}\", font-name=\"Arial\", font-size=65, font-color=0x00ffffff, bottom-offset=24, font-border=2, text-align=center, video-width=${VIDEO_WIDTH}, video-height=${VIDEO_HEIGHT}, fps=${VIDEO_FPS}, track=${SUBS_ID}, lang=und" >> ${META_FILENAME}
fi

# For debugging
cat ${META_FILENAME}

# Convert the MKV to M2TS
${CMD_TSMUXER} ${META_FILENAME} ${M2TS_FILENAME}

# Remove the transient files
${CMD_RM} ${META_FILENAME} 2>/dev/null
${CMD_RM} ${AC3_FILENAME} 2>/dev/null
${CMD_RM} ${DTS_FILENAME} 2>/dev/null

# Change the permission on the M2TS file(s) to something sane.
${CMD_CHMOD} 644 ${BASENAME}*.m2ts 2>/dev/null   

echo "All Done!"
