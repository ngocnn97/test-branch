pipeline{
    agent any
    environment{
       Name = "Devsecops_Test"
       Version = "1.0"
       App_Language = "Python"
       Framework = "Django"
    }
    
stages {
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


