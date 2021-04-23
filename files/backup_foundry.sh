#! /bin/bash

###
#
# Backup der FoundryVTT-World
# Sichert veraenderte FoundryVTT-Welten auf das Storage.
#
# Version 1.0    2021.02.28    Martin Schatz     First Version
# Version 1.1    2021.03.20    Martin Schatz     Texte in Ausgabe klarer formuliert
#
#
#
# Todos:
#   - Cleanup of hash-file must be created
#   - Housekeeping for Backups must be created
#   - Bachup Module integrieren
#	- Parametrierung in einen Config-File auslagern
#
###

backup_storage=/media/storage/eremitage/system
backup_basedir=backup
backup_application=foundryVTT
foundry_datadir=/srv/foundryVTT/foundrydata/Data
world_directory=${foundry_datadir}/worlds
world_directory=${foundry_datadir}/modules
excludefile=backup_exclude.list
hashfile=backup_hash.list

timestamp_yearmonth=$(date "+%Y%m")
timestamp_full=$(date "+%Y%m%d-%H%M%S")
directory_cycle_dir="${timestamp_yearmonth}XX"
directory_basebackup="basebackup_$(date "+%Y%m%d-%H%M%S")"
directory_incremental="incbackup_$(date "+%Y%m%d-%H%M%S")"

DEBUG=true

function logfile_add {
	MESSAGE="${1}"
	echo "$(date +"%b %d %H:%M:%S") $(hostname) ${backup_application}: ${MESSAGE}" >> ${HOME}/log/${backup_application}/backup_${backup_application}.log
}

function build_backup_filestructure {
	# Baue Filestruktur für Backup
	if grep -qs "${backup_storage}" /proc/mounts
	then
		${DEBUG} && echo "Pruefe Verzeichnisstruktur ..." >&2
		for i in ${HOME}/log ${HOME}/log/${backup_application} ${HOME}/data ${HOME}/data/${backup_application} ${HOME}/etc ${HOME}/etc/${backup_application} ${backup_storage}/${backup_basedir} ${backup_storage}/${backup_basedir}/${backup_application}
		do
			if [ ! -d ${i} ]
			then
					mkdir ${i}
					${DEBUG} && echo "  ... erstelle ${i}" >&2
					logfile_add "Create directory ${i}"
				fi
			done
	else
		echo "ERROR: Filesystem in ${backup_storage} is not mounted"
		exit 128
	fi
}

function check_worlds {
	${DEBUG} && echo -e "\nPruefe Exclude-File fuer Backup ..." >&2
	if [ ! -f ${HOME}/etc/${backup_application}/${excludefile} ]
	then
			touch ${HOME}/etc/${backup_application}/${excludefile}
			${DEBUG} && echo "  ... erstelle Exclude-File ${HOME}/etc/${backup_application}/${excludefile}" >&2
			logfile_add "Create exclude-file ${HOME}/etc/${backup_application}/${excludefile}"
		fi

	${DEBUG} && echo -e "\nPruefe Weltverzeichnisse in ${world_directory} ..." >&2
	ls ${world_directory} | while read WORLDDIR
	do
		WORLDDIR=$(basename ${WORLDDIR})
		if [ -d ${world_directory}/${WORLDDIR} ]
		then
			if grep -q "^ *${WORLDDIR}$" ${HOME}/etc/${backup_application}/${excludefile}
			then
				${DEBUG} && echo "  => \"${WORLDDIR}\" gefunden in Exclude-File ${HOME}/etc/${backup_application}/${excludefile}" >&2
				logfile_add "World ${WORLDDIR} in Exclude-File, will not be included in backup"
			elif grep -q "^# *${WORLDDIR}$" ${HOME}/etc/${backup_application}/${excludefile}
			then
				echo "${WORLDDIR}"
				${DEBUG} && echo "  => \"${WORLDDIR}\" auskommentiert gefunden in Exclude-File ${HOME}/etc/${backup_application}/${excludefile}" >&2
			else
				echo "# ${WORLDDIR}" >> ${HOME}/etc/${backup_application}/${excludefile}
				${DEBUG} && echo "  => \"${WORLDDIR}\" nicht gefunden in ${HOME}/etc/${backup_application}/${excludefile}," >&2
				${DEBUG} && echo "      wird auskommentiert in den Exclude-File integriert und bei nächster Sicherung gesichert." >&2
				logfile_add "World ${WORLDDIR} not in Exclude-File, will be added (commented out)"
			fi
		fi
	done
}

function hash_directory {
	find ${1} -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum | cut -f 1 -d " "
}

function backup_world {
	local WORLD=${1}
	dir_hash=$(hash_directory ${world_directory}/${WORLD})
	if [ ! -f ${HOME}/data/${backup_application}/${hashfile} ]
	then
			touch ${HOME}/data/${backup_application}/${hashfile}
			${DEBUG} && echo "     Erstelle Hash-File ${HOME}/data/${backup_application}/${hashfile}" >&2
			logfile_add "Create hash-file ${HOME}/data/${backup_application}/${hashfile}"
		fi
	if grep -q "^ *${WORLD}:${dir_hash} ${world_directory}/${WORLD}:" ${HOME}/data/${backup_application}/${hashfile}
	then
		logfile_add "World ${WORLD} has not changed, skipping backup"
		${DEBUG} && echo "     Welt \"${WORLD}\" hat sich nicht geaendert, daher kein Backup"		
	else
		for i in ${backup_storage}/${backup_basedir}/${backup_application}/${WORLD} ${backup_storage}/${backup_basedir}/${backup_application}/${WORLD}/${directory_cycle_dir} ${backup_storage}/${backup_basedir}/${backup_application}/${WORLD}/${directory_cycle_dir}/${WORLD}.${timestamp_full}
		do
			if [ ! -d ${i} ]
			then
				mkdir ${i}
				${DEBUG} && echo "     Erstelle Verzeichnis ${i}" >&2
				logfile_add "Create directory ${i}"
			fi
		done
		logfile_add "Starting Backup of world ${WORLD} from ${world_directory}/${WORLD}/ to ${backup_storage}/${backup_basedir}/${backup_application}/${WORLD}/${directory_cycle_dir}/${WORLD}.${timestamp_full}/"
		${DEBUG} && echo "     Starte Backup von Welt \"${WORLD}\" (${world_directory}/${WORLD}/ => [...]/${backup_basedir}/${backup_application}/${WORLD}/${directory_cycle_dir}/${WORLD}.${timestamp_full}/)" >&2
		cp -r ${world_directory}/${WORLD}/* ${backup_storage}/${backup_basedir}/${backup_application}/${WORLD}/${directory_cycle_dir}/${WORLD}.${timestamp_full}/
		logfile_add "Finished Backup of world ${WORLD}"
		${DEBUG} && echo "     Beende Backup von Welt \"${WORLD}\""		
	fi

	echo "${WORLD}:${dir_hash} ${world_directory}/${WORLD}:${backup_storage}/${backup_basedir}/${backup_application}/${WORLD}/${directory_cycle_dir}/${WORLD}.${timestamp_full}" >> ${HOME}/data/${backup_application}/${hashfile}
}

# Mount Backup Storage
sudo mount ${backup_storage}
if [ ${?} -ne 0 ]
then
	logfile_add "Backup storage could not be mounted ${backup_storage}, exiting"
	exit 128
fi

build_backup_filestructure
check_worlds | while read WORLD
do
	backup_world ${WORLD}
done