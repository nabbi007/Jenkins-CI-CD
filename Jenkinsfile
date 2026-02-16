pipeline {
  agent any

  options {
    timestamps()
  }

  parameters {
    string(name: 'EC2_HOST', defaultValue: 'ec2-public-dns-or-ip', description: 'EC2 public DNS/IP')
    string(name: 'EC2_USER', defaultValue: 'ec2-user', description: 'SSH username')
    string(name: 'REGISTRY_REPO', defaultValue: 'nabbi007/jenkins-ci-cd-demo', description: 'Image repo path')
    string(name: 'HOST_PORT', defaultValue: '80', description: 'Port exposed on EC2 host')
  }

  environment {
    APP_CONTAINER = 'jenkins-ci-cd-app'
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    FULL_IMAGE = "${params.REGISTRY_REPO}:${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install/Build') {
      steps {
        sh 'npm ci'
      }
    }

    stage('Test') {
      steps {
        sh 'npm test'
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t ${FULL_IMAGE} -t ${params.REGISTRY_REPO}:latest .'
      }
    }

    stage('Push Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'registry_creds', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh '''
            set -e
            echo "$REG_PASS" | docker login -u "$REG_USER" --password-stdin
            docker push ${FULL_IMAGE}
            docker push ${params.REGISTRY_REPO}:latest
            docker logout
          '''
        }
      }
    }

    stage('Deploy') {
      steps {
        sshagent(credentials: ['ec2_ssh']) {
          sh '''
            chmod +x scripts/deploy-ec2.sh
            IMAGE_NAME=${FULL_IMAGE} \
            APP_CONTAINER=${APP_CONTAINER} \
            EC2_HOST=${params.EC2_HOST} \
            EC2_USER=${params.EC2_USER} \
            HOST_PORT=${params.HOST_PORT} \
            ./scripts/deploy-ec2.sh
          '''
        }
      }
    }
  }

  post {
    success {
      echo 'Pipeline completed: build, test, push, deploy.'
    }
    failure {
      echo 'Pipeline failed. Check stage logs and fix before rerun.'
    }
    always {
      cleanWs()
    }
  }
}
