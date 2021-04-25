#! /bin/bash

###
#
# Extrahiert Bilddaten aus PDF-Dateien
# Extrahiert Bilddaten aus PDF-Dateien und verschiebt die Files in 
# passende Unterverzeichnisse
#
# Version 1.0    2021.03.02    Martin Schatz     First Version
# Version 1.1    2021.03.04    Martin Schatz     Konvertiert in das WebP-Format
# Version 1.2    2021.04.25    Martin Schatz     Konfigurationsparameter in eigenen File ausgegliedert
#
###

. ~/etc/foundryvtt_config.cfg
basedir_doc_in=${foundry_pdfdir}/convert
basedir_doc_out=${foundry_pdfdir}/converted
foundry_imagedir=${foundry_pdfdir}/images

echo "Bearbeite Verzeichnis ${basedir_doc_in}"

ls ${basedir_doc_in} | grep "\.[Pp][Dd][Ff]$" | while read FILE;
do
	IMAGEDIR="$(echo "${FILE}" | sed "s/\.[Pp][Dd][Ff]$//")"
	echo "  -> Bearbeite Dokument: \"${FILE}\""
	mkdir "${foundry_imagedir}/${IMAGEDIR}"
	pdfimages -j "${basedir_doc_in}/${FILE}" "${foundry_imagedir}/${IMAGEDIR}/image" 2> /dev/null
	find "${foundry_imagedir}/${IMAGEDIR}" -type f | while read IMAGEFILE
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
	sudo chown foundry:foundry "${foundry_imagedir}/${IMAGEDIR}"
	sudo chown foundry:foundry "${foundry_imagedir}/${IMAGEDIR}/"*
	sudo chown foundry:foundry "${basedir_doc_out}/${FILE}"
done