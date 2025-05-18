pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t calculator-app:${BUILD_NUMBER} .'
                sh 'docker tag calculator-app:${BUILD_NUMBER} calculator-app:latest'
            }
        }
       stage('Run Container') {
    steps {
        sh 'docker stop calculator-container || true'
        sh 'docker rm calculator-container || true'
        sh 'docker run -d -p 8090:8080 --name calculator-container calculator-app:latest'
    } 
