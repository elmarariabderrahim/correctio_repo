#!/bin/bash
export username=$1
export password=$2
#list des scripts qui est passé par succès
results_of_succeed_scripts=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select script_name from scripts where script_state='succes';"  ) )
# list des scripts échoué
results_of_failed_scripts=( $( mysql --batch mysql -u $username -p$password -N -e "use db5; select script_name from scripts where script_state='failed';"  ) )

str=$(docker port test-mysql)
IFS=':'
read -ra ADDR <<< "$str"
docker_mysql_port=${ADDR[1]}
echo ${docker_mysql_port}

flag=""
#récupération des scripts 
for f in PATT_UTILS/sql/*; do
	
script_name=$(echo $f| cut -d'/' -f 3)

  # script type (<200 ou >=200)
script_type=$(echo $script_name| cut -d'_' -f 1)
  
	
# verification 
	if [[ ! ${results_of_succeed_scripts[*]} =~ "$script_name" ]] 
	then

		flag="0"
		# echo "$script_name n'est pas encore testé"
		 
	else 
		flag="1"
		# echo "$script_name est deja testé"
		
	fi
	
		if [[ $flag -eq 0 ]] && [[ $script_type < 200 ]] ; then	
                input="./$f"
				varrr=""	 
				while IFS= read -r line
				do
				    varrr="${varrr}$line"
				done < "$input" 

				
				mysql -P $docker_mysql_port --protocol=tcp -u$username -p$password -Bse "$varrr" 


				if [ "$?" -eq 0 ]; then
						if [[ ${results_of_failed_scripts[*]} =~ "$script_name" ]] 
						then
							mysql -u$username -p$password -Bse "use db5;update scripts set  script_state = 'succes' where script_name='$script_name';"
							echo " le script $script_name est passer avec succes"
						else
							echo " le script $script_name est passer avec succes"
							mysql -u$username -p$password -Bse "use db5;update scripts set script_state = 'succes' where script_name='$script_name';;"
						fi
				else
						if [[ ${results_of_failed_scripts[*]} =~ "$script_name" ]] 
						then
						echo " le script $script_name n'a pas été corrigé"
						else
						echo " le script ${script_name} a échoué"
						 
						mysql -u$username -p$password -Bse "use db5;update scripts set script_state = 'failed' where script_name='$script_name';"
						fi
				fi 
		elif [ $flag -eq 0 ] && (( $script_type >= 200 )) 
		then	
				 input="./$f"
				varrr=""	 
				while IFS= read -r line
				do
					if [[ $line != *"commit;"* ]]; then
					varrr="${varrr}$line"
					fi
				    
				done < "$input" 
				
				# mysql -P $docker_mysql_port --protocol=tcp -uroot -ppixid123 -Bse " START TRANSACTION;"
				mysql -u$username -p$password -Bse " START TRANSACTION;"
				
				# mysql -P $docker_mysql_port --protocol=tcp -uroot -ppixid123 -Bse "SET AUTOCOMMIT=0; $varrr commit;" 
				mysql  -u$username -p$password -Bse "SET AUTOCOMMIT=0; $varrr " 

				if [ "$?" -eq 0 ]; then
					echo "l'insertion est passer par succes dans $script_name"
					# mysql -P $docker_mysql_port --protocol=tcp -uroot -ppixid123 -Bse "commit;"
					mysql  -u$username -p$password -Bse "ROLLBACK;"

					if [[ ${results_of_failed_scripts[*]} =~ "$script_name" ]] 
						then
							mysql -u$username -p$password -Bse "use db5;update scripts set  script_state = 'succes' where script_name='$script_name';"
					else
						
							mysql -u$username -p$password -Bse "use db5;update scripts set script_state = 'succes' where script_name='$script_name';"
					fi
					
				else
					
					# mysql -P $docker_mysql_port --protocol=tcp -uroot -ppixid123 -Bse "ROLLBACK;"
					mysql  -u$username -p$password -Bse "ROLLBACK;"
					if [[ ${results_of_failed_scripts[*]} =~ "$script_name" ]] 
						then
							echo " le script $script_name n'a pas été corrigé"
					else
						echo " l'insertion  a échoué dans $script_name "
							mysql -u$username -p$password -Bse "use db5;update scripts set script_state = 'failed' where script_name='$script_name';"
					fi
				fi
		else
				echo "le script $script_name est deja tester "
		fi
done
