pipeline {
    agent any
    
    environment {
        // Use TCP connection to Docker Desktop (more reliable on macOS)
        DOCKER_HOST = 'tcp://localhost:2375'
        DOCKER_IMAGE = "calculator-app:${env.BUILD_NUMBER}"
        KUBE_NAMESPACE = 'calculator-app'
    }

    stages {
        // Stage 1: Checkout Code
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // Stage 2: Build Docker Image (using Docker Desktop)
        stage('Build Docker Image') {
            steps {
                script {
                    // Ensure Docker Desktop is running (macOS specific)
                    sh '''
                        if ! docker ps >/dev/null 2>&1; then
                            echo "Starting Docker Desktop..."
                            open -a Docker
                            sleep 60  # Wait for Docker to initialize
                        fi
                    '''
                    
                    // Build with BuildKit for better performance
                    sh "docker build --pull --no-cache -t ${DOCKER_IMAGE} ."
                }
            }
        }

        // Stage 3: Push to Container Registry (Optional)
        stage('Push to Registry') {
            when {
                expression { env.BRANCH_NAME == 'project-3' }
            }
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        // Stage 4: Deploy to Kubernetes
        stage('Kubernetes Deployment') {
            steps {
                script {
                    // Apply Kubernetes manifests
                    sh """
                        kubectl config set-context --current --namespace=${KUBE_NAMESPACE}
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                        kubectl rollout status deployment/calculator-app
                    """
                    
                    // Get LoadBalancer URL
                    def LB_URL = sh(
                        script: "kubectl get service calculator-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'",
                        returnStdout: true
                    ).trim()
                    echo "Application available at: http://${LB_URL}"
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed! Sending notification...'
            // Add notification logic here
        }
        success {
            echo 'Pipeline succeeded! Application deployed to Kubernetes'
        }
    }
}