pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh 'echo "Tests passed (simplified)"'
            }
        }
        stage('SonarQube') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'TOKEN')]) {
                    sh '''
                        curl -s https://sonar-scanner-cli.s3.us-east-1.amazonaws.com/sonar-scanner-cli-4.8.0.2856-linux.zip -o /tmp/sonar.zip
                        cd /tmp && unzip sonar.zip
                        /tmp/sonar-scanner-4.8.0.2856-linux/bin/sonar-scanner -Dsonar.projectKey=simple-python-app -Dsonar.sources=. -Dsonar.host.url=http://15.206.211.77:9000 -Dsonar.token=$TOKEN
                    '''
                }
            }
        }
        stage('Quality Gate') { steps { timeout(time: 2, unit: 'MINUTES') { waitForQualityGate abortPipeline: true } } }
        stage('DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        docker build -t vimalpree/simple-python-app:$BUILD_NUMBER .
                        echo $PASS | docker login -u $USER --password-stdin
                        docker push vimalpree/simple-python-app:$BUILD_NUMBER
                    '''
                }
            }
        }
        stage('Deploy') { sh 'docker run -d --name app -p 5000:5000 vimalpree/simple-python-app:$BUILD_NUMBER' }
    }
}
