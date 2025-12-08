pipeline {
    agent any
    stages {
        // 1. Checkout del código
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/JustinoBoggio/Jenkins-Projects'
            }
        }
        // 2. Build de la imagen Docker
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("JustinoBoggio/Jenkins-Projects:${env.BUILD_ID}")
                }
            }
        }
        // 3. Push a Docker Hub
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                        docker.image("JustinoBoggio/Jenkins-Projects:${env.BUILD_ID}").push()
                    }
                }
            }
        }
        // 5. Deploy en AKS/Kubernetes
        stage('Deploy to AKS') {
            steps {
                sh 'kubectl apply -f k8s/deployment.yml'  // Asegúrate que Terraform ya creó el cluster
                sh 'kubectl apply -f k8s/service.yml'
            }
        }
    }
}