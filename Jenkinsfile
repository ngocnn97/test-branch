pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "Copy_of_CJ2"
    APP_NAME = "Java-Test-CJ2"
  }

  tools {
    maven 'maven-3'
  }

  options {
    timestamps()
  }

  stages {
    stage("build") {
      when {
        not {
          allOf {
            branch 'master'
            triggeredBy 'UserIdCause'
          }
        }
      }

      steps {
        sh 'mvn -B -DskipTests clean package'

      }
    }

    stage("unit test") {
      when {
        not {
          allOf {
            branch 'master'
            triggeredBy 'UserIdCause'
          }
        }
      }

      steps {
        sh 'mvn test'
      }

      post {
        always {
          junit 'target/surefire-reports/*.xml'
        }
      }
    }

    stage('analyze') {
      when {
        not {
          allOf {
            branch 'master'
            triggeredBy 'UserIdCause'
          }
        }
      }

      parallel {
        stage('branch') {
          when {
            anyOf {
              branch 'master'
              branch 'develop'
              branch 'develop/*'
              branch 'release/*'
            }
          }

          steps {
            script {
              scannerHome = tool 'SonarQube'
            }
            withSonarQubeEnv('Sonarqube1') {
              sh "ls ${scannerHome}"
              sh "echo ${scannerHome}"
              sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${APP_NAME} -Dsonar.projectName=${APP_NAME} -Dsonar.branch.name=${env.BRANCH_NAME}"
            }
          }
        }

        stage('pull request') {
          when {
            changeRequest()
          }

          steps {
            script {
              scannerHome = tool 'SonarQube'
            }
            withSonarQubeEnv('Sonarqube1') {
              sh "ls ${scannerHome}"
              sh "echo ${scannerHome}"
              sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${APP_NAME} -Dsonar.projectName=${APP_NAME} \
                                    -Dsonar.branch.name=${env.BRANCH_NAME} \
                                "
            }
          }
        }
      }
    }

    stage("DEV & QA") {
      parallel {
        stage("DEV") {
          when {
            branch 'develop'
            beforeAgent true
          }

          environment {
            ENV_NAME = "dev"
            DOCKER_TAG = "${BUILD_NUMBER}-${ENV_NAME}"
          }

          stages {
            stage("package") {
              steps {
                echo 'sendSlackDeploymentNotification'

                script {
                  sh "docker build . -t ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }

                // vulnerability scan
                echo 'Syft scan DevOps'
                sleep 30
              }

              post {
                success {
                  sh 'echo "post result to dependencyTrack"'
                  sleep 1
                }
              }
            }

            stage("deploy") {
              steps {
                echo "Deploy to AWS"
                sleep 60
              }
            }
          }

          post {
            always {
              echo "sendSlackDeploymentNotification"
            }
          }
        }

        stage("QA") {
          when {
            branch 'release/*'
            beforeAgent true
          }

          environment {
            ENV_NAME = "qa"
            DOCKER_TAG = "${BUILD_NUMBER}-${ENV_NAME}"
          }

          stages {
            stage("package") {
              steps {
                echo 'sendSlackDeploymentNotification'

                script {
                  sh "docker build . -t ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
              }
            }

            stage("deploy") {
              agent {
                docker {
                  image "nexus-docker.df.msb.com.vn/silintl/ecs-deploy"
                  args '--entrypoint='
                  reuseNode true
                }
              }

              steps {
                echo "Deploy to AWS"
                sleep 60
              }
            }
          }

          post {
            always {
              echo 'sendSlackDeploymentNotification'
            }
          }
        }
      }
    }

    stage("package UAT") {
      when {
        branch 'master'
        triggeredBy "BranchEventCause"
        beforeAgent true
      }

      environment {
        ENV_NAME = "uat"
        DOCKER_TAG = "${BUILD_NUMBER}-${ENV_NAME}"
      }

      steps {
        script {
          sh "docker build . -t ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }

        // vulnerability scan
        echo 'Syft scan DevOps'
        sleep 30
      }

      post {
        success {
          echo "post result to dependencyTrack"
          sleep 1
        }

        always {
          echo 'sendSlackDeploymentNotification'
        }
      }
    }

    stage("deployment") {
      when {
        branch 'master'
        triggeredBy "UserIdCause"
        beforeAgent true
      }

      environment {
        DOCKER_REGISTRY = "nexus-docker-msb.df.msb.com.vn"
        DOCKER_REGISTRY_CREDENTIALS = "rb-cc-svc-nexus"
      }

      stages {
        stage('environment input') {
          steps {
            script {
              configInput = [
                parameters: [
                  imageTag(
                    name: 'imageName',
                    image: "${DOCKER_IMAGE}",
                    credentialId: "${DOCKER_REGISTRY_CREDENTIALS}",
                    defaultTag: "uat",
                    filter: '.*uat.*',
                    registry: "https://${DOCKER_REGISTRY}"
                  ),
                  choice(
                    name: 'envName',
                    choices: ['uat', 'prod'],
                  )
                ]
              ]

              buildName "#${BUILD_NUMBER} - deploy ${configInput.imageName} to ${configInput.envName}"
            }
          }
        }

        stage('deploy') {
          parallel {
            stage('UAT') {
              when {
                equals actual: configInput.envName, expected: 'uat'
                beforeAgent true
              }

              environment {
                ENV_NAME = "uat"
              }

              stages {
                stage('deploy: UAT') {
                  steps {
                    echo 'Deploy to AWS'
                  }
                }
              }

              post {
                always {
                  echo 'sendSlackDeploymentNotification'
                }
              }
            }

            stage('PROD') {
              when {
                equals actual: configInput.envName, expected: 'prod'
                beforeAgent true
              }

              environment {
                ENV_NAME = "prod"
                DOCKER_TAG = "${BUILD_NUMBER}-${ENV_NAME}"
              }

              stages {
                stage('approve') {
                  steps {
                    echo 'approve by Ngoc'
                  }
                }

                stage('promote image') {
                  steps {
                    echo 'send Slack notify'

                    echo 'docker uat to prod'
                  }
                }

                stage('backup rds') {
                  steps {
                    echo 'backup RDS'
                  }
                }

                stage('deploy: PROD') {

                  steps {
                    echo ' deploy AWS'
                  }
                }
              }

              post {
                always {
                  echo 'send Slack notify'
                }
              }
            }
          }
        }
      }
    }
  }

  post {
    always {
      cleanWs()
      sh 'docker image prune --all --force --filter "until=24h"'
    }
  }
}