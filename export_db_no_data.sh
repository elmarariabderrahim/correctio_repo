# WORKSPACE=$1
# export username=$2
# export password=$3
# VERSION_NUMBER=$4
# VERSION_NAME="V$4"

# SCRIPT_BASEDIR_PATH=$(dirname "$SCRIPT_PATH")
# . ${SCRIPT_BASEDIR_PATH}/environment_config.sh

# list_script_alredy_succes=( $( mysql --batch mysql -u $username -p$password -N -e "use PIXID; select script_name from scripts where script_handled='encour';"  ) )


# list_database_in_script=()
# flag=""
# Read_DB_Name() {
# 	DB_INSTRUCTION="NODBINSTRUCTIONINTHEFILE"
# 	while read -r line
# 	do
#     	TEMP=$(echo $line | tr '[:lower:]' '[:upper:]')
#     	#echo "line $TEMP"
#     	if [[ $TEMP = *"USE"* ]]; then
    		
#     			DB_INSTRUCTION=$TEMP
    		 
#     			DB_INSTRUCTION=$line
    		
    		
#     	fi
# 	done < "$1"
# 	RESULT=""
# 	if [[ $DB_INSTRUCTION = *"\`"* ]] 
# 		then 
# 		RESULT=$(echo $DB_INSTRUCTION | cut -d"\`" -f2 | xargs)
# 	else
# 		RESULT=$(echo $DB_INSTRUCTION | cut -d" " -f2 | cut -d";" -f1 | xargs)
# 	fi
#   	echo -e "${RESULT}"
# }


# for f in $VERSIONED_GIT_SQL_SCRIPTS_DIRECTORY/*; do
# script_name=$(echo $f| cut -d'/' -f 5)
# if [[ ! ${list_script_alredy_succes[*]} =~ $script_name ]]
# then
# DB_NAME=`Read_DB_Name $f `
# count=${#list_database_in_script[@]}
# flag1=""
# for (( c=0; c<$count; c++ ))
# do 
	
# 				if [[  ${list_database_in_script[$c]} = ${DB_NAME} ]]; then 
# 					flag1=1
# 				else 
# 					flag1=0
# 				fi

# done
# mysql -u$username -p$password -Bse "use PIXID;update scripts set  script_handled ='traite' where script_name='$script_name';"

# 	if [[  $DB_NAME != "NODBINSTRUCTIONINTHEFILE" ]]; then 
# 	 	if [[  $flag1 != 1 ]]; then 
# 						list_database_in_script+=($DB_NAME)

# 				fi

# 	else
# 		echo "la base de donnee n'est pas specifier dans le script $script_name "
# 	fi
# fi
# done
# count=${#list_database_in_script[@]}
# echo "nombre des bases invoquer dans les scripts est" $count	


#  # inportation des bases invoquer dans les scripts
# str=$(docker port test-mysql)
# IFS=':'
# read -ra ADDR <<< "$str"
# docker_mysql_port=${ADDR[1]}

# for d in ${list_database_in_script[@]}; do
# 	echo " ---"+$d
# 	mysqldump -u $username -p$password --no-data $d > $d.sql
# 	mysql -P $docker_mysql_port --protocol=tcp -u $username -p$password -Bse "DROP DATABASE IF EXISTS $d; CREATE DATABASE  $d; "
# 	docker exec -i dadbc6ef4b91  mysql -u $username -p$password  $d < $d.sql
# done
echo "abdo"
