pipeline {
    agent any

    environment {
        DOCKERHUB_REPO   = "vimalpree/simple-ci-app"
        SONAR_PROJECTKEY = "simple-ci-app"
    }

    triggers {
        githubPush()
    }

    tools {
        // uses the configured SonarQube Scanner
        // if using 'withSonarQubeEnv', tool is auto-selected
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate') {
            steps {
                sh 'chmod +x test_app.sh'
                sh './test_app.sh'
            }
        }

        stage('SonarQube Analysis') {
            environment {
                // name must match Sonar server configuration
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh """
                        sonar-scanner \
                          -Dsonar.projectKey=${SONAR_PROJECTKEY} \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_AUTH_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def imageTag = "${env.BUILD_NUMBER}"
                    sh "docker build -t ${DOCKERHUB_REPO}:${imageTag} ."
                    sh "docker tag ${DOCKERHUB_REPO}:${imageTag} ${DOCKERHUB_REPO}:latest"
                }
            }
        }

        stage('Docker Login & Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                                     usernameVariable: 'DOCKER_USER',
                                                     passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                          echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                          docker push ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                          docker push ${DOCKERHUB_REPO}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy (Local Docker)') {
            steps {
                script {
                    sh """
                      docker rm -f simple-ci-app || true
                      docker run -d --name simple-ci-app -p 3000:3000 ${DOCKERHUB_REPO}:latest
                    """
                }
            }
        }
    }

    post {
        always {
            sh "docker image prune -f || true"
        }
    }
}
