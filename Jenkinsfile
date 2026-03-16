pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh 'docker run --rm -v $(pwd):/app -w /app python:3.12 sh -c "pip install -r requirements.txt pytest && pytest test_app.py -v"'
            }
        }
        stage('SonarQube') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'TOKEN')]) {
                    sh 'docker run --rm -e SONAR_TOKEN=$TOKEN -v $(pwd):/usr/src sonarsource/sonar-scanner-cli:latest -Dsonar.projectKey=simple-python-app -Dsonar.sources=. -Dsonar.host.url=http://15.206.211.77:9000'
                }
            }
        }
        stage('Quality Gate') {
            steps { timeout(time: 3, unit: 'MINUTES') { waitForQualityGate abortPipeline: true } }
        }
        stage('DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        docker build -t vimalpree/simple-python-app:$BUILD_NUMBER .
                        docker login -u $USER -p $PASS
                        docker push vimalpree/simple-python-app:$BUILD_NUMBER
                    '''
                }
            }
        }
        stage('Deploy') {
            steps { sh 'docker run -d --name app -p 5000:5000 vimalpree/simple-python-app:$BUILD_NUMBER' }
        }
    }
}
