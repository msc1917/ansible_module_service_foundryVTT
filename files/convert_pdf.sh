#! /bin/bash

###
#
# Extrahiert Bilddaten aus PDF-Dateien
# Extrahiert Bilddaten aus PDF-Dateien und verschiebt die Files in 
# passende Unterverzeichnisse
#
# Version 1.0    2021.03.02    Martin Schatz     First Version
# Version 1.1    2021.03.04    Martin Schatz     Konvertiert in das WebP-Format
#
###

basedir=/srv/foundryVTT/foundrydata/Data/local/pdf
basedir_doc_in=${basedir}/convert
basedir_doc_out=${basedir}/converted
imagedir=${basedir}/images

echo "Bearbeite Verzeichnis ${basedir_doc_in}"

ls ${basedir_doc_in} | grep "\.[Pp][Dd][Ff]$" | while read FILE;
do
	IMAGEDIR="$(echo "${FILE}" | sed "s/\.[Pp][Dd][Ff]$//")"
	echo "  -> Bearbeite Dokument: \"${FILE}\""
	mkdir "${imagedir}/${IMAGEDIR}"
	pdfimages -j "${basedir_doc_in}/${FILE}" "${imagedir}/${IMAGEDIR}/image" 2> /dev/null
	find "${imagedir}/${IMAGEDIR}" -type f | while read IMAGEFILE
	do
		echo "     ... Bearbeite File: \"${IMAGEFILE}\""
		filename="$(basename "${IMAGEFILE}")"
		directoryname="$(dirname "${IMAGEFILE}")"
		case "${filename##*.}" in
			ppm) rm "${directoryname}/${filename}"
				 echo "     ... Loesche: \"${IMAGEFILE}\"";;
			jpg) cwebp -quiet -q 60 "${directoryname}/${filename}" -o "${directoryname}/${filename%.*}.webp"
				 echo "     ... Konvertiere: \"${filename}\" => \"${filename%.*}.webp\" ($(du -h "${directoryname}/${filename}" | cut -f 1 -d $'\t') => $(du -h "${directoryname}/${filename%.*}.webp" | cut -f 1 -d $'\t'))"
			     rm "${directoryname}/${filename}"
				 echo "     ... Loesche: \"${IMAGEFILE}\"";;
		esac
	done

	mv "${basedir_doc_in}/${FILE}" "${basedir_doc_out}/${FILE}"
	sudo chown foundry:foundry "${imagedir}/${IMAGEDIR}"
	sudo chown foundry:foundry "${imagedir}/${IMAGEDIR}/"*
	sudo chown foundry:foundry "${basedir_doc_out}/${FILE}"
done