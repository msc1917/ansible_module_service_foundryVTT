#! /bin/bash

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
	pdfimages -j "${basedir_doc_in}/${FILE}" "${imagedir}/${IMAGEDIR}/image"
	mv "${basedir_doc_in}/${FILE}" "${basedir_doc_out}/${FILE}"
	sudo chown foundry:foundry "${imagedir}/${IMAGEDIR}"
	sudo chown foundry:foundry "${imagedir}/${IMAGEDIR}/"*
	sudo chown foundry:foundry "${basedir_doc_out}/${FILE}"
done