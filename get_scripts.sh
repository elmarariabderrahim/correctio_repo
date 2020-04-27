export username=$1
export password=$2


list_script=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select script_name from scripts;"  ) )
list_checksum=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select CHECKSUM_VALUE from scripts;"  ) )


for f in PATT_UTILS/sql/*; do
	script_name=$(echo $f| cut -d'/' -f 3)
	CHECKSUM_VALUE=`md5sum $f | awk '{print $1}'`
	echo $script_name
	echo $CHECKSUM_VALUE
	SCRIPT_NAME_UPPERCASE=$(echo $script_name | tr '[:lower:]' '[:upper:]')
	
	if [[ ${list_script[*]} =~ "$script_name" ]] && [[ ${list_checksum[*]} =~ "$CHECKSUM_VALUE" ]]
	then
		echo "pas de nouveau scripts"
		# exit 1
		
	elif [[ ${list_script[*]} =~ "$script_name" ]] && [[ !(${list_checksum[*]} =~ "$CHECKSUM_VALUE") ]]
	then
		echo "le script $script_name a été modifier  "
		mysql -u$username -p$password -Bse "use db5;update scripts set  CHECKSUM_VALUE = '$CHECKSUM_VALUE', script_handled ='encour' where script_name='$script_name';"
	else
		

			echo $DB_NAME_IN_SCRIPT_UPPERCASE $SCRIPT_NAME_UPPERCASE
			mysql -u$username -p$password -Bse "use db5;insert into scripts (script_name,script_handled,CHECKSUM_VALUE) values('$script_name','encour','$CHECKSUM_VALUE');"
		
	fi

									
done
