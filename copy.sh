#!/bin/bash
JOB_NAME=$1

VERSION_NUMBER=$2

VERSION_NAME="V$2"
PLATEFORME=`echo $JOB_NAME |cut -d"_" -f1`
export username=$3
export password=$4
PROJECT_SQL_NAME=$5
PLATEFORME_SOURCE=$7
WORKSPACE=$6
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_BASEDIR_PATH=$(dirname "$SCRIPT_PATH")
. ${SCRIPT_BASEDIR_PATH}/environment_config.sh

DATE_NOW=`date '+%Y-%m-%d-%H-%M-%S'`
TIMESTAMP=`date '+%Y-%m-%d-%H:%M:%S'`
SCRIPT_HANDLED_LIST=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select script_name from scripts where (script_state='succes' or script_state='valid') and script_handled='traite' and version='$VERSION_NAME';"  ) )
SCRIPT_CHECKSUM_HANDLED_LIST=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select script_name, CHECKSUM_VALUE  from scripts where script_state='succes' and script_handled='traite' and version='$VERSION_NAME';"  ) )
platforms_script=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select DISTINCT script_platform from scripts where version = '$VERSION_NAME';"))
list_dbs_in_version=($( mysql --batch mysql -u $username -p$password -N -e  "use db5;select DISTINCT db_in_script from scripts  where version = '$VERSION_NAME' and db_in_script IS NOT NULL;" ))
list_id_script=($( mysql --batch mysql -u $username -p$password -N -e  "use db5;select script_id from scripts  where version = '$VERSION_NAME';" ))
list_script_succed=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select script_name from scripts where script_state='succes' and script_handled='traite' and version='$VERSION_NAME';"  ) )
echo "-------------------"
log "DATE $DATE_NOW"
echo ${#list_dbs_in_version[@]}

SCRIPT_ALREADY_HANDLED_LIST=()
# mkdir -p $VERSIONED_SQL_DEPLOYMENT_DIRECTORY_PROCESSED/$DATE_NOW
if [[ ${PLATEFORME_SOURCE} != "" ]]; then 
		# VERSIONED_SQL_SCRIPTS_DIRECTORY=${SQL_DEPLOYMENT_DIRECTORY}/${PLATEFORME_SOURCE}/$VERSION_NUMBER/PROCESSED
	VERSIONED_SQL_SCRIPTS_DIRECTORY=appli/deployment/sql/${PLATEFORME_SOURCE}/$VERSION_NUMBER/PROCESSED
else 
	VERSIONED_SQL_SCRIPTS_DIRECTORY=${VERSIONED_GIT_SQL_SCRIPTS_DIRECTORY}
fi

SQL_SCRIPTS_DIRECTORY_COUNT=0
if [ -d "$VERSIONED_GIT_SQL_SCRIPTS_DIRECTORY" ]; then
	SQL_SCRIPTS_DIRECTORY_COUNT=`ls -1 $VERSIONED_SQL_SCRIPTS_DIRECTORY | wc -l`
fi
echo $SQL_SCRIPTS_DIRECTORY_COUNT = ${#SCRIPT_HANDLED_LIST[@]}
if [[ $SQL_SCRIPTS_DIRECTORY_COUNT = ${#SCRIPT_HANDLED_LIST[@]} ]] 
then
# si les scripts SQL s'exécutent pour le premier foie

	mysql --batch mysql -u $username -p$password -N -e "use db5;insert into execution_plateforme(script_id) select script_id from scripts where version = '$VERSION_NAME' and script_id NOT IN (select script_id from execution_plateforme) ;"
	# mysql --batch mysql -u $username -p$password -N -e "update execution_plateforme set $PLATEFORME = 1 where script_id in (select script_id from scripts where version = '$VERSION_NAME');"
# si les scripts ont ete deja executer dans la plateform courant 
echo  $version_exec_in_pf
		if [[ $version_exec_in_pf = "0" ]]
		then
			# la recupiration des version deja executer dans la plateform courant
			list_id_palteform_alredy_exec=($( mysql --batch mysql -u $username -p$password -N -e  "use db5;SELECT Distinct S.script_platform  FROM scripts S,EXECUTION_PLATEFORME E WHERE S.script_platform =E.PF_$PLATEFORME;" ))
			nbr_script_valid=($( mysql --batch mysql -u $username -p$password -N -e  "use db5;SELECT COUNT(*) from scripts where version ='$VERSION_NAME' and script_state='valid';" ))
			if [[ ${list_id_palteform_alredy_exec[@]} =~ "EXEC_$VERSION_NAME" ]] && [[ $nbr_script_valid = ${#SCRIPT_HANDLED_LIST[@]} ]]
			then
				
				log "cet version $VERSION_NAME est deja tester et deployer dans la plateform $PLATEFORME"
				exit 1
			fi
		fi
	

    # mkdir -p  ${VERSIONED_SQL_DEPLOYMENT_DIRECTORY_PROCESSED}
	mkdir -p "appli/deployment/sql/$PLATEFORME/$VERSION_NUMBER/PROCESSED"
	for script in `ls -1 $VERSIONED_SQL_SCRIPTS_DIRECTORY`
	do
		if [[ ${SCRIPT_HANDLED_LIST[@]} =~ $script ]]
		then
			# cp -f "${VERSIONED_SQL_SCRIPTS_DIRECTORY}/${script}"  "${VERSIONED_SQL_DEPLOYMENT_DIRECTORY_PROCESSED}"

			cp -f "${VERSIONED_SQL_SCRIPTS_DIRECTORY}/${script}"  "appli/deployment/sql/$PLATEFORME/$VERSION_NUMBER/PROCESSED"
		fi
	done

# création du dossier daté  
	# for i in ${list_dbs_in_version[@]}
	# do
		 
	# 	# mkdir -p "${VERSIONED_SQL_DEPLOYMENT_DIRECTORY_PROCESSED}/$DATE_NOW/$i"
	# 	mkdir -p "appli/deployment/sql/$PLATEFORME/$VERSION_NUMBER/PROCESSED/$DATE_NOW/$i"
	# done
# copie des fichiers sql dans le dossier daté
	for script in `ls -1 $VERSIONED_SQL_SCRIPTS_DIRECTORY`
	do
		for i in ${list_dbs_in_version[@]}
		do
			i_upper=$(echo $i | tr '[:lower:]' '[:upper:]')
			if [[ $script = *"$i_upper"* ]] 
			then
				if [[ ${list_script_succed[@]} =~ $script ]]
				then
					mkdir -p "appli/deployment/sql/$PLATEFORME/$VERSION_NUMBER/PROCESSED/$DATE_NOW/$i"
				# cp -f "${VERSIONED_SQL_SCRIPTS_DIRECTORY}/${script}"  "${VERSIONED_SQL_DEPLOYMENT_DIRECTORY_PROCESSED}/$DATE_NOW/$i"
				cp -f "${VERSIONED_SQL_SCRIPTS_DIRECTORY}/${script}"  "appli/deployment/sql/$PLATEFORME/$VERSION_NUMBER/PROCESSED/$DATE_NOW/$i"
				fi
			fi
		done
	done

	log "Les scripts de version $VERSION_NAME ont été copiés dans le dossier de déploiement"
				
else
	log "les scripts de la $VERSION_NAME ne peuvent pas être copiés dans le dossier de déploiement "
	log "il y a toujours des scripts rejetés dans la version $VERSION_NAME, soit ils sont mal nommés,ou ils ont échoué pendant le test (verifier la table de register)"
	exit 1
fi

																										

log "Creation du dossier sql dans CIFS"
# TARGET_SQL_FOLDER=$TARGET_BASE_FOLDER/$PLATEFORME/$VERSION_NUMBER/$CURRENT_INCREMENT/sql
# ssh -i /appli/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${TARGET_HOST} bash -c "'mkdir -p ${TARGET_SQL_FOLDER}'"  |& tee -a ${LOG_FILE}
# if [ ${PIPESTATUS[0]} -ne "0" ]; then
# 	log "Erreur lors de la creation du dossier cible dans CIFS"
# 	log "FIN DES TRAITEMENTS AVEC ERREUR VOIR FICHIER DE LOG ${LOG_FILE}"
# 	exit 1
# fi

# if [ $SCRIPT_HANDLED_TO_BE_DEPLOYED_LIST_COUNT -gt "0" ]; then
# 	log "copie des dossiers contenant les fichiers sql dans les dossiers cibles sur cifs"
# 	scp -i /appli/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ${VERSIONED_SQL_DEPLOYMENT_DIRECTORY_PROCESSED}/$DATE_NOW/* root@${TARGET_HOST}:${TARGET_SQL_FOLDER}  |& tee -a ${LOG_FILE}
# 	if [ ${PIPESTATUS[0]} -ne "0" ]; then
# 		log "Erreur lors de la copie des scripts sql dans le dossier cible sous CIFS"
# 		log "FIN DES TRAITEMENTS AVEC ERREUR VOIR FICHIER DE LOG ${LOG_FILE}"
# 		exit 1
# 	fi
# fi


# # suppression du dossier au nom daté après copie des fichiers sql qu'il contient dans CIFS
# # rm -rf ${VERSIONED_SQL_DEPLOYMENT_DIRECTORY_PROCESSED}/$DATE_NOW |& tee -a ${LOG_FILE}
# rm -rf appli/deployment/sql/$PLATEFORME/$VERSION_NUMBER/PROCESSED/$DATE_NOW |& tee -a ${LOG_FILE}

count=${#SCRIPT_CHECKSUM_HANDLED_LIST[@]}
echo "${TIMESTAMP}|BUILD_RUNNING" >> appli/deployment/sql/$PLATEFORME/$VERSION_NUMBER/register
	if [ $count -gt "0" ]
		then
		
		log " fin de traitement avec succes "
		for (( c=0; c<$count; c++ ))
		do
			echo "${SCRIPT_CHECKSUM_HANDLED_LIST[$c]}|${SCRIPT_CHECKSUM_HANDLED_LIST[$c+1]}" >> appli/deployment/sql/$PLATEFORME/$VERSION_NUMBER/register
			c=$c+1
		done
		

	fi


# RELEASE_TIME=`date '+%Y %m %d - %Hh%M'`
# sed -i "s/{{VERSION_NUMBER}}/${VERSION_NUMBER}/g; s/{{RELEASE_TIME}}/${RELEASE_TIME}/g" $NEW_HTML_TAG |& tee -a ${LOG_FILE}