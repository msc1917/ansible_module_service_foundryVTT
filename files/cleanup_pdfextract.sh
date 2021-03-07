#! /bin/bash
basedir=/srv/foundryVTT/foundrydata/Data/local/pdf
imagedir=${basedir}/images
foundryuser=foundry

###
#
# Bereinigen des PDF-Verzeichnisses
# Loescht zu kleine Bilddaten im BDF-Image-Extract-Verzeichhnis
#
# Version 1.0    2021.03.07    Martin Schatz     First Version
#
###

minwidth=30
minheight=30
minpixel=12000

echo "Mindestbreite = ${minwidth} Pixel"
echo "Mindesthoehe  = ${minheight} Pixel"
echo "Mindestpixel  = ${minpixel} Pixel"
echo ""
echo "Bereinige Verzeichnisstruktur ${basedir}:"
find "${imagedir}" - type f -name "*.webp" | while read IMAGEFILE
do
	IMAGEINFO="$(webpinfo "${IMAGEFILE}")"
	IMAGEWIDTH="$(echo "${IMAGEINFO}" | grep "^ *Width:" | sed "s/^ *Width: //")"
	IMAGEHEIGHT="$(echo "${IMAGEINFO}" | grep "^ *Height:" | sed "s/^ *Height: //")"
	IMAGEPIXEL=$(expr ${IMAGEWIDTH} \* ${IMAGEHEIGHT} )
	if [ ${IMAGEWIDTH} -lt ${minwidth} ]
	then
		sudo -u ${foundryuser} rm "${IMAGEFILE}"
		echo "  Loesche wegen geringer Bildbreite: ...$(echo "${IMAGEFILE}" | sed "s#${basedir}##") (${IMAGEWIDTH}*${IMAGEHEIGHT}=${IMAGEPIXEL})"
	elif [ ${IMAGEHEIGHT} -lt ${minheight} ]
	then
		sudo -u ${foundryuser} rm "${IMAGEFILE}"
		echo "  Loesche wegen geringer Bildhoehe:  ...$(echo "${IMAGEFILE}" | sed "s#${basedir}##") (${IMAGEWIDTH}*${IMAGEHEIGHT}=${IMAGEPIXEL})"
	elif [ ${IMAGEPIXEL} -lt ${minpixel} ]
	then
		sudo -u ${foundryuser} rm "${IMAGEFILE}"
		echo "  Loesche wegen geringer Pixelzahl:  ...$(echo "${IMAGEFILE}" | sed "s#${basedir}##") (${IMAGEWIDTH}*${IMAGEHEIGHT}=${IMAGEPIXEL})"
	fi

done