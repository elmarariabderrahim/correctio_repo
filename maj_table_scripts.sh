#!/bin/bash

#========================================================================================================
#   le but de ce script est de mettre a jour le registre des scripts sql apres execution
#   sur les serveurs de base de données dans le but de statuer sur l'etat d'execution de chaque script 
#   en succes ou en echec.
#   tout script dont l'execution a echoue sont etat va etre modifier en INVALID et VALID s'il est en succes
#========================================================================================================

JOB_NAME=$1
WORKSPACE=$2
VERSION_NUMBER=$3
VERSION_NAME="V$3"
export username=$4
export password=$5
DATE_TODAY=`date '+%Y-%m-%d'`
PLATEFORME=`echo $JOB_NAME |cut -d"_" -f1`
# lecture des parametres / variables environnements
SCRIPT_NAME=`basename "$0"`
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_BASEDIR_PATH=$(dirname "$SCRIPT_PATH")
. "${SCRIPT_BASEDIR_PATH}/environment_config.sh"

# LIST=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select script_name from scripts where script_state='succes' and script_handled='traite' and version !='$VERSION_NAME';"  ) )
# lisrof=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select script_name,CHECKSUM_VALUE  from scripts;"  ) )

# log "Mise a jour du registre des scripts sql apres execution"
# log "Recuperation des noms des scripts dont l'execution a reussie depuis $TARGET_HOST/${SQL_EXECUTION_RESULT_FILE}"
# TEMP_SUCCESS_SCRIPTS=`ssh -i /appli/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${TARGET_HOST} bash -c "'cat ${SQL_EXECUTION_RESULT_FILE}'"`
TEMP_SUCCESS_SCRIPTS=()
TEMP_SUCCESS_SCRIPTS+=("001_ABD_PROVIDER_TI_67087_sjnlsfl.sql|a83e78cc9e56ab8f48887bcced0b180c")
TEMP_SUCCESS_SCRIPTS+=("012_AMN_MISSION_TI_7654_fgjkfa.sql|95ef924d079acdbd80009c2387e9cf94")
TEMP_SUCCESS_SCRIPTS+=("015_AME_MISSION_TI_7654_fgjkfa.sql|95ef924d079acdbd80009c2387e9cf94")
TEMP_SUCCESS_SCRIPTS+=("001_AEL_PIXID_TI_67899_sjnlsfl.sql 95ef924d079acdbd80009c2387e9cf94")
TEMP_SUCCESS_SCRIPTS+=("002_AEL_DWHSTAGE_TI_6789967_ALLSCRIP.sql|95ef924d079acdbd80009c2387e9cf94")
TEMP_SUCCESS_SCRIPTS+=("200_AEL_DWHSTAGE_TI_67899_sjnlsfl.sql|95ef924d079acdbd80009c2387e9cf94")
TEMP_SUCCESS_SCRIPTS+=("201_JEE_PIXID_TI_9875_INSERT.sql|95ef924d079acdbd80009c2387e9cf94")

log "TEMP_SUCCESS_SCRIPTS : ${#TEMP_SUCCESS_SCRIPTS[@]}"

for script_succed in ${TEMP_SUCCESS_SCRIPTS[@]}
do
	echo "----------$script_succed est valider ---------"

		 mysql --batch mysql -u $username -p$password -N -e "use db5; update scripts set script_state ='valid' where (SELECT INSTR( '$script_succed' , script_name ) !=0) and script_state='succes' and script_handled='traite' ;update execution_plateforme set \`$PLATEFORME\`= 0 where script_id in (select script_id from scripts where (select INSTR( '$script_succed' , script_name ) = 0)) ;"
		  # mysql --batch mysql -u $username -p$password -N -e "use db5; update execution_plateforme set \`$PLATEFORME\`= 0 where script_id in (select script_id from scripts where (select INSTR( '$script_succed' , script_name ) = 0));"

done
for script_succed in ${TEMP_SUCCESS_SCRIPTS[@]}
do
	echo "----------$script_succed est invalid---------"
		  mysql --batch mysql -u $username -p$password -N -e "use db5; update scripts set script_state ='invalid', script_handled ='encour' where (SELECT INSTR( '$script_succed' , script_name ) = 0 and (script_state='succes' or script_state !='valid')  and script_handled='traite'); update execution_plateforme set \`$PLATEFORME\`= 1  where script_id in (select script_id from scripts where (select INSTR( '$script_succed' , script_name ) !=0)) ;"
		 # mysql --batch mysql -u $username -p$password -N -e "use db5; update execution_plateforme set \`$PLATEFORME\`= 1  where script_id in (select script_id from scripts where (select INSTR( '$script_succed' , script_name ) !=0));"


done

	

