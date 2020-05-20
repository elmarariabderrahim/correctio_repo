pipeline {
    agent any 
	 environment {
    		PATH = "C:\\Program Files\\Git\\usr\\bin;C:\\Program Files\\Git\\bin;${env.PATH}"
		 }
		 parameters {
           choice(name: 'CHOIX',
	       choices: ['no_data', 'ddl'],
	       description: '1 : Exportation complete de la DB\n2 : Choix des composants necessaires')
         } 
    stages {
        stage('export_shema') {          
              steps {
		    //withCredentials([
			//		usernamePassword(
			//			credentialsId: '0467c09c-9a30-4e9f-bdc9-6126fd2482d4', 
			//			usernameVariable: 'USERNAME',
			//			passwordVariable: 'PASSWORD'
						
						
			//		)
			//]){
        //script{
			
		//bat "sh  ./get_scripts.sh ${WORKSPACE} ${USERNAME}  ${PASSWORD} ${RELEASE_VERSION_NUMBER_TO_USE} "
                   // if(CHOIX == 'no_data')
                     //   bat "sh  ./export_db_no_data.sh ${WORKSPACE} ${USERNAME}  ${PASSWORD} ${RELEASE_VERSION_NUMBER_TO_USE}"
                    //else
                      bat "sh  ./export_db_no_data.sh"
               // }
		 //   }
      //}
          echo "++++"
        echo "${JOB_NAME}"
		      echo "${workspace}"
          
      }
	 
        }  
        
   }
	 post { 
		failure { 
			script {
		              emailext attachLog: true, body: 'L\'audit Sonar des projets Pixid s\'est arrÃªtÃ© sur une erreur.<BR><BR>Voir le fichier de log en piÃ¨ce jointe ou aller sur . <BR><BR> Equipe CI/CD <BR><BR> Job  <BR><BR>', subject: "Erreurs lors de l'Audit sonar par Jenkins sur l'environnement ", to: 'elmarari.abder@gmail.com'
			}
            }
   	 }
}
