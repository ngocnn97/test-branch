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
                branch 'master'
            }
            steps {
                script{
                        echo 'This is Master'
                        }
                }
        }

        stage ('Test'){
            when {
                branch 'develop'
            }
            steps {
                script{
                        echo 'This is Develop'
                        }
                }
        }
}
}
