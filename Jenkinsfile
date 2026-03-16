pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "vimalpree/simple-python-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
        SONAR_TOKEN = credentials('sonar-token')  // Your Sonar credential ID
    }
    stages {
        stage('Setup Python') {
            steps {
                sh '''
                    apt-get update
                    apt-get install -y -qq python3 python3-pip python3-venv curl unzip
                    ln -sf /usr/bin/python3 /usr/bin/python
                '''
            }
        }
        stage('Test') {
            steps {
                sh '''
                    python -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt pytest
                    pytest test_app.py -v
                '''
            }
        }
        stage('SonarQube') {
            steps {
                sh '''
                    curl -sL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o sonar.zip
                    unzip -o sonar.zip
                    ./sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
                      -Dsonar.projectKey=simple-python-app \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=http://15.206.211.77:9000 \
                      -Dsonar.token='${SONAR_TOKEN}'
                '''
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Docker') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', 
                    usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        echo $PASS | docker login -u $USER --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
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
    post {
        always {
            sh 'docker ps'
        }
    }
}
