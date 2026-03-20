pipeline {
    agent any
    environment {
        SONAR_HOST_URL = 'http://YOUR_SONAR_IP:9000'  // Replace!
        DOCKERHUB_REPO = 'vimalpree/simple-ci-app'
    }
    stages {
        stage('Verify Tools') {
            steps {
                sh '''
                    sonar-scanner --version
                    docker version
                    echo "✓ All tools ready"
                '''
            }
        }
        stage('SonarQube') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=simple-ci-app \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=$SONAR_HOST_URL
                    '''
                }
            }
        }
        stage('Quality Gate') {
            steps { 
                timeout(time: 3, unit: 'MINUTES') { 
                    waitForQualityGate abortPipeline: true 
                } 
            }
        }
        stage('Docker Build & Push') {
            steps {
                script {
                    sh "docker build -t ${DOCKERHUB_REPO}:\${BUILD_NUMBER} ."
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', 
                                                     usernameVariable: 'DH_USER', 
                                                     passwordVariable: 'DH_PASS')]) {
                        sh '''
                            echo $DH_PASS | docker login -u $DH_USER --password-stdin
                            docker push ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                            docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${DOCKERHUB_REPO}:latest
                            docker push ${DOCKERHUB_REPO}:latest
                        '''
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                    docker stop app-container || true
                    docker rm app-container || true
                    docker run -d --name app-container -p 3000:3000 ${DOCKERHUB_REPO}:latest
                '''
            }
        }
    }
    post { always { sh 'docker system prune -f' } }
}
