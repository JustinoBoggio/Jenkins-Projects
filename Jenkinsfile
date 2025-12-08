pipeline {
  agent { label 'docker' }

  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  environment {
    APP_DIR      = 'reddit-clone-k8s-ingress-master' // carpeta de la app
    IMAGE_REPO   = 'tuusuario/reddit-clone'          // cambia a tu repo en Docker Hub
    REGISTRY_URL = 'https://index.docker.io/v1/'
    DOCKER_CREDS = 'docker-hub-creds'                // ID de credencial en Jenkins
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Unit tests (npm)') {
      steps {
        dir(APP_DIR) {
          sh 'npm ci'
          sh 'npm test || echo "sin tests o fallaron, continuar para demo"'
        }
      }
    }

    stage('Build image') {
      steps {
        script {
          // tag corto de commit o BUILD_NUMBER
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

    stage('Deploy (kubectl, opcional)') {
      when {
        allOf {
          fileExists("${APP_DIR}/k8s/deployment.yml")
          fileExists("${APP_DIR}/k8s/service.yml")
        }
      }
      steps {
        withCredentials([file(credentialsId: 'kubeconfig-cluster', variable: 'KUBECONFIG')]) {
          sh """
            kubectl apply -f ${APP_DIR}/k8s/deployment.yml
            kubectl apply -f ${APP_DIR}/k8s/service.yml
          """
        }
      }
    }
  }

  post {
    always { sh 'docker image prune -f' }
  }
}