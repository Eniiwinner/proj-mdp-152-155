pipeline {
    agent {
        docker {
            image 'docker:latest'  // Uses official Docker image
            args '-v /var/run/docker.sock:/var/run/docker.sock -v /tmp:/tmp'  // Gives Docker-in-Docker access
        }
    }
    environment {
        REGISTRY = "localhost:5000"
        IMAGE_NAME = "calculator-app"
        TAG = "11"
    }
    stages {
        stage('Checkout') {
            steps {
                echo "### Checking out code ###"
                checkout scm  // Checks out your GitHub repo
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "### Building Docker image ###"
                sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${TAG} ."
            }
        }
        
        stage('Push Image') {
            steps {
                echo "### Pushing to local registry ###"
                sh "docker push ${REGISTRY}/${IMAGE_NAME}:${TAG}"
            }
        }
        
        stage('Kubernetes Deploy') {
            steps {
                echo "### Deploying to Kubernetes ###"
                sh """
                    kubectl apply -f k8s-deployment.yaml
                    kubectl rollout status deployment/calculator-app
                """
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo "### Verifying deployment ###"
                sh "kubectl get pods -o wide"
                sh "curl http://localhost:8080"  // Adjust port as needed
            }
        }
    }
    post {
        always {
            echo "### Pipeline completed ###"
            sh "docker images | grep ${IMAGE_NAME}"
        }
        failure {
            echo "### Pipeline failed - check logs ###"
            sh "docker ps -a"
        }
    }
}