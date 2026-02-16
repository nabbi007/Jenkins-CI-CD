pipeline {
  agent any

  options {
    timestamps()
  }

  parameters {
    string(name: 'EC2_HOST', defaultValue: 'ec2-public-dns-or-ip', description: 'EC2 public DNS/IP')
    string(name: 'EC2_USER', defaultValue: 'ec2-user', description: 'SSH username')
    string(name: 'AWS_REGION', defaultValue: 'eu-west-1', description: 'AWS region for ECR')
    string(name: 'ECR_REPOSITORY', defaultValue: 'jenkins-ci-cd-demo', description: 'ECR repository name')
    string(name: 'AWS_CREDS_ID', defaultValue: 'aws_creds', description: 'Jenkins username/password credential ID (AWS access key and secret)')
    string(name: 'HOST_PORT', defaultValue: '80', description: 'Port exposed on EC2 host')
    string(name: 'HEALTH_PATH', defaultValue: '/health', description: 'Health endpoint path for deployment verification')
  }

  environment {
    APP_CONTAINER = 'jenkins-ci-cd-app'
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

    stage('Resolve ECR') {
      steps {
        withCredentials([usernamePassword(credentialsId: params.AWS_CREDS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          script {
            env.AWS_REGION = params.AWS_REGION
            env.ECR_REPOSITORY = params.ECR_REPOSITORY
            env.AWS_ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
            env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
            env.IMAGE_REPO = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}"
            env.FULL_IMAGE = "${env.IMAGE_REPO}:${env.BUILD_NUMBER}"
          }

          sh '''
            set -e
            aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${AWS_REGION} >/dev/null 2>&1 || \
            aws ecr create-repository --repository-name ${ECR_REPOSITORY} --region ${AWS_REGION} >/dev/null
          '''
        }
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t ${FULL_IMAGE} -t ${IMAGE_REPO}:latest .'
      }
    }

    stage('Push Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: params.AWS_CREDS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            set -e
            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
            docker push ${FULL_IMAGE}
            docker push ${IMAGE_REPO}:latest
            docker logout ${ECR_REGISTRY}
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
            HEALTH_PATH=${params.HEALTH_PATH} \
            AWS_REGION=${AWS_REGION} \
            ECR_REGISTRY=${ECR_REGISTRY} \
            ./scripts/deploy-ec2.sh
          '''
        }
      }
    }
  }

  post {
    success {
      echo 'Pipeline completed: build, test, push to ECR, and deploy.'
    }
    failure {
      echo 'Pipeline failed. Check stage logs and fix before rerun.'
    }
    always {
      cleanWs()
    }
  }
}
