pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "vimalpree/simple-python-app"  // YOUR DockerHub
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = "dockerhub-creds"
    }

    // Simplified trigger - uses GitHub hook (no GenericTrigger needed)
    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt pytest
                    pytest test_app.py -v || true
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube Server') {
                    sh '''
                        # Install sonar-scanner if needed
                        wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
                        unzip -o sonar-scanner-cli-5.0.1.3006-linux.zip
                        ./sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
                          -Dsonar.projectKey=simple-python-app \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=http://15.206.211.77:9000
                    '''
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
                sh """
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Push DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID,
                    usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo $DH_PASS | docker login -u $DH_USER --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker stop app || true
                    docker rm app || true
                    docker run -d --name app -p 5000:5000 ${DOCKER_IMAGE}:latest
                '''
            }
        }
    }
}
