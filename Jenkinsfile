pipeline {
    agent any
    
    environment {
        DOCKER_BINARY = '/opt/homebrew/bin/docker'
        DOCKER_HOST = 'unix:///Users/eniolaabraham/.docker/run/docker.sock'
        BUILD_TAG = "calculator-app:${BUILD_NUMBER}"
        KUBE_NAMESPACE = 'calculator-ns'
    }

    stages {
        stage('Verify Environment') {
            steps {
                script {
                    sh '''
                        echo "### SYSTEM INFO ###"
                        echo "PATH: $PATH"
                        echo "Docker path: ''' + DOCKER_BINARY + '''"
                        echo "Docker version: $(''' + DOCKER_BINARY + ''' --version || echo "Not available")"
                        echo "Kubectl version: $(kubectl version --short 2>/dev/null || echo "Not available")"
                    '''
                }
            }
        }

        stage('Start Docker') {
            steps {
                script {
                    sh """
                        # Check if Docker is running
                        if ! ${DOCKER_BINARY} ps &>/dev/null; then
                            echo "Starting Docker Desktop..."
                            open -a Docker
                            # Wait with increasing timeout
                            for i in {1..6}; do
                                sleep 10
                                if ${DOCKER_BINARY} ps &>/dev/null; then
                                    echo "Docker started after \$((i*10)) seconds"
                                    break
                                fi
                                if [ \$i -eq 6 ]; then
                                    echo "ERROR: Docker failed to start after 60 seconds"
                                    exit 1
                                fi
                            done
                        fi
                    """
                }
            }
        }

        stage('Configure Docker') {
            steps {
                sh """
                    # Clean up any existing credentials configuration
                    mkdir -p ~/.docker
                    echo '{"credsStore":""}' > ~/.docker/config.json
                    chmod 600 ~/.docker/config.json
                    
                    # Verify Docker can pull images
                    ${DOCKER_BINARY} pull tomcat:9.0-jdk11 || echo "Warning: Failed to pull Tomcat image"
                """
            }
        }

        stage('Build Image') {
            steps {
                script {
                    try {
                        sh """
                            ${DOCKER_BINARY} build \\
                                --no-cache \\
                                --build-arg BUILD_NUMBER=${BUILD_NUMBER} \\
                                -t ${BUILD_TAG} .
                        """
                    } catch (Exception e) {
                        echo "Build failed, retrying with network host..."
                        sh """
                            ${DOCKER_BINARY} build \\
                                --network host \\
                                --no-cache \\
                                --build-arg BUILD_NUMBER=${BUILD_NUMBER} \\
                                -t ${BUILD_TAG} .
                        """
                    }
                }
            }
        }
        
        stage('Push Image') {
            when {
                expression { env.BRANCH_NAME == 'project-3' }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        ${DOCKER_BINARY} login -u $DOCKER_USER -p $DOCKER_PASS
                        ${DOCKER_BINARY} push ${BUILD_TAG}
                    """
                }
            }
        }

        stage('Kubernetes Deploy') {
            steps {
                script {
                    sh """
                        # Create namespace if not exists
                        kubectl create namespace ${KUBE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        
                        # Deploy application
                        kubectl config set-context --current --namespace=${KUBE_NAMESPACE}
                        kubectl apply -f k8s/
                        
                        # Wait for rollout
                        kubectl rollout status deployment/calculator-app --timeout=120s
                        
                        # Get LB URL
                        echo "Application URL:"
                        kubectl get service calculator-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
                    """
                }
            }
        }
    }

    post {
        always {
            echo "### Pipeline completed ###"
            sh "${DOCKER_BINARY} images | grep calculator-app"
        }
        success {
            echo "Deployment successful!"
        }
        failure {
            echo "Pipeline failed - checking logs..."
            sh """
                ${DOCKER_BINARY} ps -a
                kubectl get pods -n ${KUBE_NAMESPACE}
                kubectl describe deployment/calculator-app -n ${KUBE_NAMESPACE}
            """
        }
    }
}