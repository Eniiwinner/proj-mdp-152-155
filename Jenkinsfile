pipeline {
    agent any
    environment {
        KUBECONFIG = credentials('kubeconfig')
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'project-3', url: 'https://github.com/your-username/proj-mdp-152-155.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("your-dockerhub/calculator-app:${env.BUILD_NUMBER}")
                    docker.withRegistry('', 'dockerhub-creds') {
                        docker.image("your-dockerhub/calculator-app:${env.BUILD_NUMBER}").push()
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl apply -f k8s-deployment.yaml
                    kubectl apply -f k8s-service.yaml
                '''
            }
        }
    }
}
