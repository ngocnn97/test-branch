pipeline{
    agent any
    environment{
       Name = "Devsecops_Test"
       Version = "1.0"
       App_Language = "Python"
       Framework = "Django"
    }
    
stages {
        stage('find upstream job') {
                steps {
                    script {
                        def causes = currentBuild.rawBuild.getCauses()
                        for(cause in causes) {
                            if (cause.class.toString().contains("UpstreamCause")) {
                                println "This job was caused by job " + cause.upstreamProject
                            } else {
                                println "Root cause : " + cause.toString()
                            }
                        }
                    }      
                }
            }
        stage ('Test'){
            when {
                triggeredBy "BranchEventCause"
            }
            steps {
                script{
                        echo 'test sussess'
                        }
                }
        }
}
}


