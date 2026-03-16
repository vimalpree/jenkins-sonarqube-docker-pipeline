pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "vimalpree/simple-python-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
    }
    stages {
        stage('Install Python & Test') {
            steps {
                sh '''
                    apt-get update
                    apt-get install -y python3 python3-pip python3-venv
                    ln -s /usr/bin/python3 /usr/bin/python
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt pytest
                    pytest test_app.py -v
                '''
            }
        }
        stage('SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube Server') {
                    sh '''
                        curl -sL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o /tmp/sonar.zip
                        cd /tmp && unzip -o sonar.zip
                        /tmp/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
                          -Dsonar.projectKey=simple-python-app \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=http://15.206.211.77:9000
                    '''
                }
            }
        }
        stage('Quality Gate') { 
            steps { timeout(time: 3, unit: 'MINUTES') { waitForQualityGate abortPipeline: true } }
        }
        stage('Docker Build & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', 
                    usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh '''
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
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

