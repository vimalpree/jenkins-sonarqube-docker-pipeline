pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "vimalpree/simple-python-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = "dockerhub-creds"
    }

    triggers {
        GenericTrigger(
            genericVariables: [
                [key: 'ref', value: "$.ref"]
            ],
            causeString: 'GitHub Webhook',
            token: 'your-webhook-secret-token'  // Optional but recommended
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    sh '''
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install -r requirements.txt pytest
                        pytest test_app.py -v
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'  // From Global Tool Config
                    withSonarQubeEnv('SonarQube Server') {  // From Jenkins Config System
                        sh """
                            ${scannerHome}/bin/sonar-scanner \\
                              -Dsonar.projectKey=simple-python-app \\
                              -Dsonar.sources=. \\
                              -Dsonar.python.coverage.reportPaths=coverage.xml \\
                              -Dsonar.host.url=http://localhost:9000
                        """
                    }
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
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: DOCKER_CREDENTIALS_ID,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh '''
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        '''
                    }
                }
            }
        }

        stage('Deploy Locally') {
            steps {
                script {
                    sh '''
                        docker stop simple-app || true
                        docker rm simple-app || true
                        docker run -d --name simple-app -p 5000:5000 ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker images'
            sh 'docker system prune -f'
        }
    }
}
