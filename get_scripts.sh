
WORKSPACE=$1
export username=$2
export password=$3
VERSION_NUMBER=$4
VERSION_NAME="V$4"

SCRIPT_BASEDIR_PATH=$(dirname "$SCRIPT_PATH")
. ${SCRIPT_BASEDIR_PATH}/environment_config.sh

list_script=( $( mysql --batch mysql -u $username -p$password -N -e "use PIXID; select script_name from scripts;"  ) )
list_checksum=( $( mysql --batch mysql -u $username -p$password -N -e "use PIXID; select CHECKSUM_VALUE from scripts;"  ) )


for f in $VERSIONED_GIT_SQL_SCRIPTS_DIRECTORY/*; do
	script_name=$(echo $f| cut -d'/' -f 5)
	CHECKSUM_VALUE=`md5sum $f | awk '{print $1}'`
	SCRIPT_NAME_UPPERCASE=$(echo $script_name | tr '[:lower:]' '[:upper:]')
	
	if [[ ${list_script[*]} =~ "$script_name" ]] && [[ ${list_checksum[*]} =~ "$CHECKSUM_VALUE" ]]
	then
		echo "le script $script_name est deja dans la base de donnée"
		# exit 1
		
	elif [[ ${list_script[*]} =~ "$script_name" ]] && [[ !(${list_checksum[*]} =~ "$CHECKSUM_VALUE") ]]
	then
		echo "le script $script_name a été modifier  "
		mysql -u$username -p$password -Bse "use PIXID;update scripts set  CHECKSUM_VALUE = '$CHECKSUM_VALUE', script_handled ='encour' where script_name='$script_name';"
	else
		

			echo $DB_NAME_IN_SCRIPT_UPPERCASE $SCRIPT_NAME_UPPERCASE
			mysql -u$username -p$password -Bse "use PIXID;insert into scripts (script_name,script_handled,CHECKSUM_VALUE) values('$script_name','encour','$CHECKSUM_VALUE');"
		
	fi

									
done
