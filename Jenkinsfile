pipeline {
  agent { label 'docker-agent-vm' }  // etiqueta del nodo que está online

  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  environment {
    APP_DIR = 'reddit-clone-k8s-ingress-master' // carpeta de la app
    IMAGE_REPO = 'mauriciobatista3099/reddit-clone'
    REGISTRY_URL = 'https://index.docker.io/v1/'
    DOCKER_CREDS = 'docker-hub-creds'// credencial en Jenkins
    AZURE_VM_USER = 'ubuntu' 
    AZURE_VM_IP  = '52.254.9.66' 
    SSH_CRED_ID = 'id_rsa_azure'
    CONTAINER_NAME = 'reddit-app'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Build image') {
      steps {
        script {
          def tag = env.GIT_COMMIT ? env.GIT_COMMIT.take(7) : env.BUILD_NUMBER
          env.IMAGE_TAG = tag
          dir(APP_DIR) {
            docker.build("${IMAGE_REPO}:${tag}")
          }
        }
      }
    }
    stage('Push image') {
      steps {
        script {
          docker.withRegistry(REGISTRY_URL, DOCKER_CREDS) {
            docker.image("${IMAGE_REPO}:${IMAGE_TAG}").push()
            docker.image("${IMAGE_REPO}:${IMAGE_TAG}").push('latest')
          }
        }
      }
    }
  } 
stage('Deploy to Azure VM') {
      steps {
        script {
          // Utiliza sshagent para inyectar la clave privada SSH 'id_rsa_azure'
          sshagent(credentials: [SSH_CRED_ID]) {
            sh """
              echo "1. Pulling image ${IMAGE_REPO}:${IMAGE_TAG}..."
              ssh -o StrictHostKeyChecking=no ${AZURE_VM_USER}@${AZURE_VM_IP} "docker pull ${IMAGE_REPO}:${IMAGE_TAG}"

              echo "2. Stopping and removing old container ${CONTAINER_NAME}..."
              ssh -o StrictHostKeyChecking=no ${AZURE_VM_USER}@${AZURE_VM_IP} "docker stop ${CONTAINER_NAME} || true"
              ssh -o StrictHostKeyChecking=no ${AZURE_VM_USER}@${AZURE_VM_IP} "docker rm ${CONTAINER_NAME} || true"

              echo "3. Starting new container ${CONTAINER_NAME}..."
              # Mapeo de puerto: -p 80:3000 (acceso externo en puerto 80, interno en 3000)
              ssh -o StrictHostKeyChecking=no ${AZURE_VM_USER}@${AZURE_VM_IP} "docker run -d --name ${CONTAINER_NAME} -p 80:3000 ${IMAGE_REPO}:${IMAGE_TAG}"
            """
          }
        }
      }
    }
  }
  post {
    always { sh 'docker image prune -f' }
  }
}