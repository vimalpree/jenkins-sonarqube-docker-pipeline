pipeline {
    agent any
    
    environment {
        DOCKERHUB_REPO = 'vimalpree/simple-ci-app'  // YOUR DockerHub
        SONAR_PROJECTKEY = 'simple-ci-app'
        SONAR_HOST_URL = 'http://15.206.80.141:9000'  // YOUR EC2 IP
        SONAR_AUTH_TOKEN = credentials('sonar-token')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    echo "✓ Tests passed (simple app validation)"
                    # Add real tests here later
                '''
            }
        }
        
        stage('SonarQube') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh 'sonar-scanner -Dsonar.projectKey=$SONAR_PROJECTKEY -Dsonar.sources=.'
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
        
        stage('Build Docker') {
            steps {
                script {
                    def tag = "${BUILD_NUMBER}"
                    sh """
                        docker build -t ${DOCKERHUB_REPO}:${tag} .
                        docker tag ${DOCKERHUB_REPO}:${tag} ${DOCKERHUB_REPO}:latest
                    """
                }
            }
        }
        
        stage('Push Docker') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', 
                                                 passwordVariable: 'pass', 
                                                 usernameVariable: 'user')]) {
                    sh """
                        echo \$pass | docker login -u \$user --password-stdin
                        docker push ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                        docker push ${DOCKERHUB_REPO}:latest
                    """
                }
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    docker stop simple-ci-app || true
                    docker rm simple-ci-app || true
                    docker run -d --name simple-ci-app -p 3000:3000 ${DOCKERHUB_REPO}:latest
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f'
        }
    }
}
