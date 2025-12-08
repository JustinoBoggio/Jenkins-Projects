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

  post {
    always { sh 'docker image prune -f' }
  }
}