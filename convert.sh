#!/bin/bash

#
# video conversion script for publishing as HTML 5 video, via videojs (with hd button extension)
# 2011 by zpea
# feel free to use as public domain / Creative Commons CC0 1.0 (http://creativecommons.org/publicdomain/zero/1.0/)
# fork from https://gist.github.com/zpea/3154378
#update by AhmadShamli for mp4 only conversion - 20151019
#convert from source dir to converted dir, skipping any converted video
#ffmpeg version 2.6.4 
#used on ScaleWay C1 ARM server

FFMPEG=ffmpeg
THREADS=4
HD_SUFFIX='_hd'
EMBED_WIDTH='320'
EMBED_HEIGHT='-1'
SD_RESOLUTION=$EMBED_WIDTH':'$EMBED_HEIGHT
SOURCEVIDEO='' #empty for current dir
CONVERTDIR='converted/'
DESCR_H264='mp4 (mpeg4/aac)'
SHOWINFO=false

if $SHOWINFO;then
echo
echo 'The video file in folder '$SOURCEVIDEO' is converted to '$DESCR_H264' videos.'
echo
echo 'There are two versions created, one "SD" version in low resolution ('$SD_RESOLUTION') '
echo 'and one "HD" version in original resolution (with the "'$HD_SUFFIX'" suffix in the name).'
echo 'Additionally a poster image is created from a screenshot.'
echo
echo 'All output files are created in the '$CONVERTDIR' directory and named according to the input file'\''s name' 
echo
echo
fi

skipdir () {
    local seeking=$1; shift
    local in=1
    for element; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}

arrskipdir=("converted" "public") #delimited by space,enclose in ""

#start looping
for file in "${SOURCEVIDEO}"*.* "${SOURCEVIDEO}"**/*.*;do
	#matched video extension only to proceed
	if [ ${file: -4} == ".avi" ]||[ ${file: -4} == ".mp4" ]||[ ${file: -4} == ".mkv" ];then
	DIR=$(dirname "${file}")
	#skip if source file in skipdir
	skipdir "$DIR" "${arrskipdir[@]}" && continue 
	
	#as $file might be in subdirectory within source dir, need to create this subdirectory in convertdir,otherwise will fail
	if [[ ! -d "$CONVERTDIR$DIR" ]]; then
		mkdir -p "$CONVERTDIR$DIR"
	fi

	BASE_WITHOUT_EXT=${file%.*}
	OUT_H264=$CONVERTDIR$BASE_WITHOUT_EXT.mp4
	OUT_H264_HD=$CONVERTDIR$BASE_WITHOUT_EXT$HD_SUFFIX.mp4
	OUT_JPEG=$CONVERTDIR$BASE_WITHOUT_EXT.jpg
	
	#remove file if already exist but have zero length(might be from previous non successful conversion
	if [ ! -s "$OUT_H264" ];then
		rm -f "$OUT_H264"
	fi
	if [ ! -s "$OUT_H264_HD" ];then
		rm -f "$OUT_H264_HD"
	fi
	if [ ! -s "$OUT_JPEG" ];then
		rm -f "$OUT_JPEG"
	fi
	#not converted(not exist) file only to proceed,skip if already created
	if [ -f "$OUT_H264" ];then
		echo 'Skipping existed file: '"$OUT_H264"
	else
	
	#Threads
	if [ $THREADS -ge 1 ]; then
		THREADS='-threads '$THREADS
	else
		THREADS=''  #empty for default(nominal)
	fi
echo
echo ================================================================
echo '   Starting conversion to SD '$DESCR_H264
echo '   output to '$OUT_H264
echo ================================================================
echo
#arm from scaleway unable to process libx264
$FFMPEG -i "$file" $THREADS -c:v mpeg4 -c:a libfdk_aac -ac 2 -vf scale=$SD_RESOLUTION  -movflags +faststart "$OUT_H264"

echo
echo ================================================================
echo '   Starting conversion to HD '$DESCR_H264
echo '   output to '$OUT_H264_HD
echo ================================================================
echo
#arm from scaleway unable to process libx264
#$FFMPEG -i "$file" -c:v mpeg4 -vtag xvid -qscale:v 2 -c:a libfdk_aac -movflags +faststart "$OUT_H264_HD"
# -vtag xvid produce error
$FFMPEG -i "$file" $THREADS -c:v libxvid -qscale:v 10 -c:a libfdk_aac -movflags +faststart "$OUT_H264_HD"

echo
echo ================================================================
echo '   Creating poster jpeg (frame at 5s)'
echo ================================================================
echo
$FFMPEG -i "$file" $THREADS -ss 00:05:00 -vframes 1 -q:v 2 "$OUT_JPEG"

echo
echo ================================================================
echo '   Done Converting'
echo ================================================================
echo 'mp4 SD file = '$OUT_H264
echo 'mp4 HD file = '$OUT_H264_HD
echo 'poster file = '$OUT_JPEG
echo ================================================================
echo ================================================================

#break   #stop at first iteration for troubleshooting
fi
#end not converted file only to proceed
fi
#end matched video extension only to proceed

done
#done looping
