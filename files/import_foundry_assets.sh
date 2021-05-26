#! /bin/bash

###
#
# Importiere Assets in die interne Filestruktur
# Hierbei werden die Files in das webp-format umgewandelt
#
# Version 1.0    2021.05.01    Martin Schatz     First Version
#
###

# Lade Config-Parameter
. ~/etc/foundryvtt_config.cfg
reportExistingFiles=false

function migrateFiles {
    globalSourceDir="${1}"
    globaltargetDir="${2}"
    if [ ! -d "${globalSourceDir}/" ]
    then
        sudo -u ${foundryuser} mkdir -p "${globalSourceDir}"
    fi
    if [ ! -d "${globaltargetDir}/" ]
    then
        sudo -u ${foundryuser} mkdir -p "${globaltargetDir}"
    fi
    find "${globaltargetDir}/" -type d | while read dirname
    do
        sourceSubDir="$(echo "${globaltargetDir}" | sed "s#^${globaltargetDir}#${globalSourceDir}#")"
        if [ ! -d ${sourceSubDir} ]
        then
            sudo -u ${foundryuser} mkdir -p "${sourceSubDir}"
        fi
    done
    find "${globalSourceDir}/" -type f | grep -Ei "\.(png|jpeg|jpg|tiff|bmp|webp)$" | while read FILENAME
    do
        sourceFile="${FILENAME}"
        targetFile="$(echo "${FILENAME%.*}.webp" | sed "s#^${globalSourceDir}#${globaltargetDir}#")"
        if [ "${sourceFile%.*}.webp" = "${targetFile}" ]
        then
            echo ""
            echo "Error!"
            echo "Could not create targetfile"
            echo " => sourceDir= \"${sourceDir}\""
            echo " => targetDir= \"${targetDir}\""
            echo " => sourceFile=\"${sourceFile}\""
            exit 1
        fi
        sourceDir="$(dirname "${sourceFile}")"
        sourceFilename="$(basename "${sourceFile}")"
        targetDir="$(dirname "${targetFile}")"
        targetFilename="$(basename "${targetFile}")"
        if [ -f "${sourceFile}" ]
        then
            if [ ! -d "${targetDir}" ]
            then
                sudo -u ${foundryuser} mkdir -p "${targetDir}"
                echo " => Erstelle Verzeichnis \"${targetDir}/\""
            fi
            if echo "${sourceFile}" | grep -Eqi "\.(webp|webm)$"
            then
                if [ ! -f "${targetFile}" ]
                then
                    filesize="$(du -b "${sourceFile}" | cut -f 1)"
                    sudo -u ${foundryuser} mv "${sourceFile}" "${targetFile}"
                    echo " => Verschiebe \"${sourceFilename}\" nach \"${targetDir}\" ($(numfmt --to iec --format "%1.2f" "${filesize}"))"
                else
                    filesize="$(du -b "${sourceFile}" | cut -f 1)"
                    sudo -u ${foundryuser} rm "${sourceFile}"
                    ${reportExistingFiles} && echo " => Datei \"${targetFile}\" bereits vorhanden ($(numfmt --to iec --format "%1.2f" "${filesize}"))"
                fi
            else
                if [ ! -f "${targetFile}" ]
                then
                    sudo -u ${foundryuser} cwebp -quiet -q 60 "${sourceFile}" -o "${targetFile%.*}.webp"
                    oldFilesize="$(du -b "${sourceFile}" | cut -f 1)"
                    newFilesize="$(du -b "${targetFile%.*}.webp" | cut -f 1)"
                    echo " => Konvertiere \"${sourceFilename}\" nach \"${targetFile}\" ($(numfmt --to iec --format "%1.2f" ${oldFilesize}) => $(numfmt --to iec --format "%1.2f" ${newFilesize}))"
                    #exitCode=${?}
                else
                    oldFilesize="$(du -b "${sourceFile}" | cut -f 1)"
                    newFilesize="$(du -b "${targetFile%.*}.webp" | cut -f 1)"
                    ${reportExistingFiles} && echo " => Datei \"${targetFile}\" bereits vorhanden ($(numfmt --to iec --format "%1.2f" ${oldFilesize}) => $(numfmt --to iec --format "%1.2f" ${newFilesize}))"
                fi
            fi
        else
            echo " => Fehler bei Datei \"${sourceFile}\"!"
        fi
    done
}

function build_dirtree {
    dirStructs="${*}"
    for dirStruct in ${dirStructs}
    do
        if [ ! -d "${token_sourceDir}/${dirStruct}" ]
        then
            sudo -u ${foundryuser} mkdir "${token_sourceDir}/${dirStruct}"
            echo " => Erstelle Verzeichnis \"${token_sourceDir}/${dirStruct}/\""
        fi
        # if [ ! -d "${token_targetDir}/${dirStruct}" ]
        # then
        #     sudo -u ${foundryuser} mkdir "${token_targetDir}/${dirStruct}"
        # fi
        for targetDirStruct in ${dirStructs}
        do
            if [ "${dirStruct}" != "${targetDirStruct}" ]
            then
                find "${token_sourceDir}/${dirStruct}" -type d | while read subDirStruct
                do
                    subDirTargetStruct="$(echo "${subDirStruct}" | sed "s#^${token_sourceDir}/${dirStruct}#${token_sourceDir}/${targetDirStruct}#")"
                    if [ ! -d "${subDirTargetStruct}" ]
                    then
                        sudo -u ${foundryuser} mkdir "${subDirTargetStruct}"
                        echo " => Erstelle Verzeichnis \"${subDirTargetStruct}/\""
                    fi
                done
            fi
        done
    done
}

function delete_wrong_files {
    find "${1}" -type f | grep -Evi "\.(png|jpeg|jpg|tiff|bmp|webp)$" | while read fileName
    do
        if [ -f "${fileName}" ]
        then
            sudo -u ${foundryuser} rm "${fileName}"
            echo " => Loesche Datei \"${fileName}\""
        fi
    done
}

echo "Importiere Token-Verzeichnisse (\"${token_sourceDir}\"):"
migrateFiles "${token_sourceDir}" "${token_targetDir}"
echo ""
echo "Erstelle Token-Verzeichnisbaum (\"${token_sourceDir}\"):"
build_dirtree ${token_dirtree}
echo ""
echo "Loesche falsche Dateien im Token-Verzeichnis (\"${token_sourceDir}\"):"
delete_wrong_files "${token_sourceDir}"
echo ""
echo "Importiere Map-Verzeichnisse (\"${map_sourceDir}\"):"
migrateFiles "${map_sourceDir}" "${map_targetDir}"
echo ""
echo "Loesche falsche Dateien im Map-Verzeichnisse (\"${map_sourceDir}\"):"
delete_wrong_files "${map_sourceDir}"
echo ""
echo "Importiere Visuals-Verzeichnisse (\"${visuals_sourceDir}\"):"
migrateFiles "${visuals_sourceDir}" "${visuals_targetDir}"
echo ""
echo "Loesche falsche Dateien im Visuals-Verzeichnisse (\"${visuals_sourceDir}\"):"
delete_wrong_files "${visuals_sourceDir}"
