pipeline {
    agent {
        docker {
            image 'docker:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock -v /tmp:/tmp --network host'
        }
    }
    
    environment {
        REGISTRY = "localhost:5000"
        IMAGE_NAME = "calculator-app"
        TAG = "${env.BUILD_NUMBER}"
        K8S_NAMESPACE = "default"
        DEPLOYMENT_FILE = "k8s-deployment.yaml"
        SERVICE_PORT = 8080
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "### Checking out code ###"
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/project-3']],
                    extensions: [[$class: 'CleanBeforeCheckout']],
                    userRemoteConfigs: [[url: 'https://github.com/Eniiwinner/proj-mdp-152-155.git']]
                ])
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "### Building Docker image ###"
                script {
                    try {
                        sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${TAG} --no-cache ."
                    } catch (Exception e) {
                        error "Build failed: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Push Image') {
            steps {
                echo "### Pushing to registry ###"
                script {
                    // Verify local registry is running
                    sh """
                        if ! docker ps | grep registry; then
                            docker run -d -p 5000:5000 --name registry registry:2
                        fi
                    """
                    retry(3) {
                        sh "docker push ${REGISTRY}/${IMAGE_NAME}:${TAG}"
                    }
                }
            }
        }
        
        stage('Kubernetes Deploy') {
            steps {
                echo "### Deploying to Kubernetes ###"
                script {
                    // Verify kubectl is available
                    sh "which kubectl || { echo 'kubectl not found'; exit 1; }"
                    
                    // Apply deployment with health checks
                    sh """
                        kubectl apply -f ${DEPLOYMENT_FILE} -n ${K8S_NAMESPACE}
                        kubectl rollout status deployment/${IMAGE_NAME} -n ${K8S_NAMESPACE} --timeout=120s
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo "### Verifying deployment ###"
                script {
                    // Get pod status
                    sh "kubectl get pods -n ${K8S_NAMESPACE} -o wide"
                    
                    // Verify service endpoint
                    sh """
                        POD_NAME=\$(kubectl get pods -n ${K8S_NAMESPACE} -l app=${IMAGE_NAME} -o jsonpath='{.items[0].metadata.name}')
                        kubectl port-forward \$POD_NAME ${SERVICE_PORT}:${SERVICE_PORT} -n ${K8S_NAMESPACE} &
                        sleep 10  # Wait for port-forward to stabilize
                        curl -sSf http://localhost:${SERVICE_PORT} || { pkill -f 'port-forward'; exit 1; }
                        pkill -f 'port-forward'
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "### Pipeline cleanup ###"
            script {
                // Clean up Docker resources
                sh "docker system prune -f || true"
                sh "docker rmi ${REGISTRY}/${IMAGE_NAME}:${TAG} || true"
                
                // Archive important files
                archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
                junit '**/target/surefire-reports/*.xml'
            }
        }
        
        success {
            echo "### Deployment successful! ###"
            slackSend color: 'good', message: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        
        failure {
            echo "### Pipeline failed - investigating ###"
            script {
                // Capture debug info
                sh """
                    kubectl describe deployment/${IMAGE_NAME} -n ${K8S_NAMESPACE} || true
                    kubectl logs -l app=${IMAGE_NAME} -n ${K8S_NAMESPACE} --tail=50 || true
                    docker ps -a || true
                """
                slackSend color: 'danger', message: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            }
        }
        
        unstable {
            echo "### Pipeline unstable - tests failed ###"
        }
    }
}