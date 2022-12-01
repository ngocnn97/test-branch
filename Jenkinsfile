pipeline {
  agent any

  environment {
    //AWS_REGION = "ap-southeast-1"

    //APP_NAME = "rb-cc-web-service"

    //ECS_CLUSTER_NAME = "rb-credit-card"
    //ECS_SERVICE_NAME = "cc-web-service"
    //ECS_SERVICE_TIMEOUT = 300

    DOCKER_IMAGE = "Copy_of_CJ2"

    //SLACK_CHANNEL = "#cj2-notification"
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
              sh "${scannerHome}/bin/sonar-scanner"
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
              sh "${scannerHome}/bin/sonar-scanner -Dsonar.pullrequest.key=${env.CHANGE_ID} \
                                -Dsonar.pullrequest.branch=${env.CHANGE_BRANCH} \
                                -Dsonar.pullrequest.base=${env.CHANGE_TARGET} \
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
              //ROLE_ARN = "arn:aws:iam::183503944727:role/svc.deployment.dev"

              //DOCKER_REGISTRY_PROTOCOL = "https"
              //DOCKER_REGISTRY = "nexus-docker-msb-dev.df.msb.com.vn"
              //DOCKER_REGISTRY_CREDENTIALS = "rb-cc-svc-nexus-dev"
              DOCKER_TAG = "${BUILD_NUMBER}-${ENV_NAME}"

              //SYFT_HOME = tool name: 'syft', type: 'com.cloudbees.jenkins.plugins.customtools.CustomTool'
              //SYFT_REPORT = "syft.cyclonedx"
              //DTRACK_API_KEY = credentials("rb-cc-svc-dtrack")
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
                  sh 'echo "post result to dependencyTrack"'
                  sleep 1
                }
              }

              stage("deploy") {
                echo "Deploy to AWS"
                sleep 60
              }
            }

            post {
              sh 'echo "sendSlackDeploymentNotification"'
            }
          }

          stage("QA") {
            when {
              branch 'release/*'
              beforeAgent true
            }

            environment {
              ENV_NAME = "qa"
              //ROLE_ARN = "arn:aws:iam::183503944727:role/svc.deployment.qa"

              //DOCKER_REGISTRY_PROTOCOL = "https"
              //DOCKER_REGISTRY = "nexus-docker-msb-dev.df.msb.com.vn"
              //DOCKER_REGISTRY_CREDENTIALS = "rb-cc-svc-nexus-dev"
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

                stage("deploy") {
                  cho "Deploy to AWS"
                  sleep 60
                }

                post {
                  echo 'sendSlackDeploymentNotification'
                }
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
      //ROLE_ARN = "arn:aws:iam::346096285157:role/svc.deployment.uat"

      //DOCKER_REGISTRY_PROTOCOL = "https"
      //DOCKER_REGISTRY = "nexus-docker-msb.df.msb.com.vn"
      //DOCKER_REGISTRY_CREDENTIALS = "rb-cc-svc-nexus"
      DOCKER_TAG = "${BUILD_NUMBER}-${ENV_NAME}"

      //SYFT_HOME = tool name: 'syft', type: 'com.cloudbees.jenkins.plugins.customtools.CustomTool'
      //SYFT_REPORT = "syft.cyclonedx"
      //DTRACK_API_KEY = credentials("rb-cc-svc-dtrack")
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
      echo "post result to dependencyTrack"
      sleep 1

      echo 'sendSlackDeploymentNotification'
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
    }

    stages {
      stage('environment input') {
        steps {
          script {
            configInput = [
              id: 'image',
              message: "Deployment Image & Environment",
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
              // ROLE_ARN = "arn:aws:iam::346096285157:role/svc.deployment.uat"

              // DOCKER_REGISTRY = "nexus-docker-msb.df.msb.com.vn"
            }

            stages {
              stage('deploy: UAT') {
                echo 'Deploy to AWS'
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
              // ENV_NAME = "prod"
              // ROLE_ARN = "arn:aws:iam::346096285157:role/svc.deployment.prod"

              // DOCKER_REGISTRY_PROTOCOL = "https"
              // DOCKER_REGISTRY = "nexus-docker-msb.df.msb.com.vn"
              // DOCKER_REGISTRY_CREDENTIALS = "rb-cc-svc-nexus"
              DOCKER_TAG = "${BUILD_NUMBER}-${ENV_NAME}"
            }

            stages {
              stage('approve') {
                steps {
                  sendSlackApprovalRequest groups: ['devops-admins'],
                    fields: [
                      [
                        "key": "Environment",
                        "value": configInput.envName
                      ],
                      [
                        "key": "Artifact",
                        "value": configInput.imageName
                      ]
                    ]
                }
              }

              stage('promote image') {
                steps {
                  echo 'send Slack notify'

                  echo 'docker uat to prod'
                }
              }

              stage('backup rds') {
                echo 'backup RDS'
              }

              stage('deploy: PROD') {
                echo ' deploy AWS'
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
  }

  post {
    always {
      cleanWs()
      sh 'docker image prune --all --force --filter "until=24h"'
    }
  }
}