export username=$1
export password=$2

SCRIPT_NAME_REGEXP='^([0-9]){3,4}(_[0-9]){0,1}_([A-Z]){3,4}(_PF([-_](DEV|INT|INT0|INT1|INT2|INT3|INT4|INT5|REC|REC1|REC2|RCT|RCT1|RCT2|TEST|PROD))+){0,1}_(PIXID|DWHSTAGE|DWHTMP|PROVIDER|MISSION){1}_(TI[-_][0-9]{1,10})(_ST[-_][0-9]{1,10})?_([A-Z0-9_-]+)(\.SQL)$'

list_script=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select script_name from scripts;"  ) )
list_checksum=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select CHECKSUM_VALUE from scripts;"  ) )
PIPE="|"
Read_DB_Name() {
	DB_INSTRUCTION="NODBINSTRUCTIONINTHEFILE"
	while read -r line
	do
    	TEMP=$(echo $line | tr '[:lower:]' '[:upper:]')
    	#echo "line $TEMP"
    	if [[ $TEMP = *"USE"* ]]; then
    		if [[ $2 -eq 1 ]]; then
    			DB_INSTRUCTION=$TEMP
    		else 
    			DB_INSTRUCTION=$line
    		fi
    		break
    	fi
	done < "$1"
	RESULT=""
	if [[ $DB_INSTRUCTION = *"\`"* ]] 
		then 
		RESULT=$(echo $DB_INSTRUCTION | cut -d"\`" -f2 | xargs)
	else
		RESULT=$(echo $DB_INSTRUCTION | cut -d" " -f2 | cut -d";" -f1 | xargs)
	fi
  	echo -e "${RESULT}"
}

for f in PATT_UTILS/sql/*; do
	script_name=$(echo $f| cut -d'/' -f 3)
	CHECKSUM_VALUE=`md5sum $f | awk '{print $1}'`
	echo $script_name
	echo $CHECKSUM_VALUE
	SCRIPT_NAME_UPPERCASE=$(echo $script_name | tr '[:lower:]' '[:upper:]')
	DB_NAME_IN_SCRIPT_UPPERCASE=`Read_DB_Name $f 1`
	
	if [[ ${list_script[*]} =~ "$script_name" ]] && [[ ${list_checksum[*]} =~ "$CHECKSUM_VALUE" ]]
	then
		echo "pas de nouveau scripts"
		# exit 1
		
	elif [[ ${list_script[*]} =~ "$script_name" ]] && [[ !(${list_checksum[*]} =~ "$CHECKSUM_VALUE") ]]
	then
		echo "le script $script_name est changer "
		mysql -u$username -p$password -Bse "use db5;update scripts set  CHECKSUM_VALUE = '$CHECKSUM_VALUE', script_handled ='encour' where script_name='$script_name';"
	else
		if [[ $SCRIPT_NAME_UPPERCASE =~ $SCRIPT_NAME_REGEXP ]] || [[ $SCRIPT_NAME_UPPERCASE = *"$DB_NAME_IN_SCRIPT_UPPERCASE"* ]]
		then

			echo $DB_NAME_IN_SCRIPT_UPPERCASE $SCRIPT_NAME_UPPERCASE
			mysql -u$username -p$password -Bse "use db5;insert into scripts (script_name,script_handled,CHECKSUM_VALUE) values('$script_name','encour','$CHECKSUM_VALUE');"
		else
			echo "Le fichier $script_name ne peut etre tester car il est mal nomme ou contient une incoherence au niveau du nom de la base de donnees" 
		fi
	fi

							
done

