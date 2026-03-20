pipeline {
    agent any
    
    environment {
        // Required: define at least one variable
        DOCKERHUB_REPO = 'vimalpree/simple-ci-app'  // ← YOUR DockerHub repo
        SONAR_PROJECTKEY = 'simple-ci-app'
        SONAR_HOST_URL = 'http://15.206.80.141:9000/'  // ← Replace with your EC2 IP
        SONAR_AUTH_TOKEN = credentials('sonar-token')  // ← Jenkins credential ID
    }
    
    triggers {
        GenericTrigger {
            // GitHub webhook trigger
            token('your-webhook-token')  // Optional secret
            causeString = 'Triggered by GitHub'
        }
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Building ${env.BUILD_ID} on ${env.JENKINS_URL}"
            }
        }
        
        stage('Test & Validate') {
            steps {
                sh '''
                    # Simple test
                    echo "Running tests..."
                    if grep -q "Hello" app.py 2>/dev/null; then
                        echo "✓ Basic validation passed"
                    else 
                        echo "✗ Validation failed"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {  // ← Matches your Jenkins Sonar server name
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=${SONAR_PROJECTKEY} \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_AUTH_TOKEN}
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
                script {
                    def imageTag = "${BUILD_NUMBER}"
                    sh """
                        docker build -t ${DOCKERHUB_REPO}:${imageTag} .
                        docker tag ${DOCKERHUB_REPO}:${imageTag} ${DOCKERHUB_REPO}:latest
                    """
                }
            }
        }
        
        stage('Docker Push') {
            steps {
                script {
                    withDockerRegistry([ 
                        credentialsId: 'dockerhub-creds',  // ← Your Jenkins DockerHub credential ID
                        url: '' 
                    ]) {
                        sh """
                            docker push ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                            docker push ${DOCKERHUB_REPO}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy Local') {
            steps {
                sh '''
                    docker rm -f simple-ci-app || true
                    docker run -d --name simple-ci-app -p 3000:3000 ${DOCKERHUB_REPO}:latest
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f || true'
            echo 'Cleanup complete'
        }
        success {
            echo '🎉 Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
