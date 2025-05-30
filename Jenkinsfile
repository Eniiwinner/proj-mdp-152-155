pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:5000'  // Change to your registry
        IMAGE_NAME = 'calculator-app'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        KUBECONFIG = '/var/jenkins_home/.kube/config'  // Path to your kubeconfig
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "### Checking out code ###"
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "### Building Docker image ###"
                    def image = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}")
                    
                    // Also tag as latest
                    sh "docker tag ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
                    
                    echo "### Image built successfully ###"
                }
            }
        }
        
        stage('Push Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'project-3'
                }
            }
            steps {
                script {
                    echo "### Pushing image to registry ###"
                    sh "docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
                    sh "docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
                }
            }
        }
        
        stage('Check kubectl') {
            steps {
                script {
                    echo "### Checking kubectl installation ###"
                    sh '''
                        if ! command -v kubectl &> /dev/null; then
                            echo "kubectl not found. Installing..."
                            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            sudo mv kubectl /usr/local/bin/ || mv kubectl /tmp/
                            export PATH="/tmp:$PATH"
                        fi
                        kubectl version --client
                    '''
                }
            }
        }
        
        stage('Kubernetes Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'project-3'
                }
            }
            steps {
                script {
                    echo "### Deploying to Kubernetes ###"
                    
                    // Create namespace
                    sh '''
                        kubectl create namespace calculator-ns --dry-run=client -o yaml | kubectl apply -f -
                    '''
                    
                    // Create deployment
                    sh '''
                        cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: calculator-app
  namespace: calculator-ns
spec:
  replicas: 2
  selector:
    matchLabels:
      app: calculator-app
  template:
    metadata:
      labels:
        app: calculator-app
    spec:
      containers:
      - name: calculator-app
        image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - calculator-app
              topologyKey: kubernetes.io/hostname
---
apiVersion: v1
kind: Service
metadata:
  name: calculator-service
  namespace: calculator-ns
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: calculator-app
EOF
                    '''
                    
                    // Wait for deployment
                    sh 'kubectl rollout status deployment/calculator-app -n calculator-ns --timeout=300s'
                    
                    // Get service info
                    sh 'kubectl get services -n calculator-ns'
                }
            }
        }
        
        stage('Verify Deployment') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'project-3'
                }
            }
            steps {
                script {
                    echo "### Verifying deployment ###"
                    sh '''
                        echo "Pods in calculator-ns:"
                        kubectl get pods -n calculator-ns
                        
                        echo "Services in calculator-ns:"
                        kubectl get svc -n calculator-ns
                        
                        echo "Deployment status:"
                        kubectl get deployment calculator-app -n calculator-ns
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "### Pipeline completed ###"
            sh '''
                docker images | grep calculator-app || echo "No calculator-app images found"
            '''
        }
        success {
            echo "### Pipeline succeeded! ###"
            script {
                sh '''
                    echo "Application deployed successfully!"
                    if kubectl get svc calculator-service -n calculator-ns &> /dev/null; then
                        echo "Service URL:"
                        kubectl get svc calculator-service -n calculator-ns -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo "LoadBalancer IP pending..."
                    fi
                '''
            }
        }
        failure {
            echo "Pipeline failed - checking logs..."
            sh '''
                docker ps -a
                if command -v kubectl &> /dev/null; then
                    kubectl get pods -n calculator-ns || echo "No pods found"
                    kubectl logs -n calculator-ns -l app=calculator-app --tail=50 || echo "No logs available"
                fi
            '''
        }
    }
}