pipeline {
    agent {
        docker {
            image 'python:3.12'
            args '-v /var/run/docker.sock:/var/run/docker.sock --user root'
        }
    }
    environment {
        DOCKER_IMAGE = "vimalpree/simple-python-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
        SONAR_URL = "http://15.206.211.77:9000"
    }
    stages {
        stage('Test') {
            steps {
                sh '''
                    pip install -r requirements.txt pytest
                    pytest test_app.py -v
                '''
            }
        }
        stage('SonarQube') {
            steps {
                sh '''
                    curl -sL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip > /tmp/sonar.zip
                    cd /tmp && unzip -o sonar.zip
                    /tmp/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
                      -Dsonar.projectKey=simple-python-app \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=${SONAR_URL} \
                      -Dsonar.login=PASTE_YOUR_SONAR_TOKEN_HERE
                '''
            }
        }
        stage('Docker Build') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', 
                    usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh '''
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker login -u $DH_USER -p $DH_PASS
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    '''
                }
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                    docker stop app-container || true
                    docker rm app-container || true
                    docker run -d -p 5000:5000 --name app-container ${DOCKER_IMAGE}:latest
                '''
            }
        }
    }
}
