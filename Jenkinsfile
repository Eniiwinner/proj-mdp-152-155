pipeline {
    agent any
    
    environment {
        // Use the exact path from your 'which docker' output
        DOCKER_BINARY = '/opt/homebrew/bin/docker'
        DOCKER_HOST = 'unix:///Users/eniolaabraham/.docker/run/docker.sock'
    }

    stages {
        stage('Verify Docker') {
            steps {
                script {
                    // Check if Docker Desktop is running
                    sh """
                        if ! ${DOCKER_BINARY} ps &>/dev/null; then
                            echo "Starting Docker Desktop..."
                            open -a Docker
                            sleep 30
                        fi
                        
                        ${DOCKER_BINARY} --version
                        ${DOCKER_BINARY} ps
                    """
                }
            }
        }

        stage('Build Image') {
            steps {
                sh "${DOCKER_BINARY} build -t calculator-app:${BUILD_NUMBER} ."
            }
        }
        
        stage('Kubernetes Deploy') {
            steps {
                sh """
                    ${DOCKER_BINARY} push calculator-app:${BUILD_NUMBER}
                    kubectl apply -f k8s/
                """
            }
        }
    }
}