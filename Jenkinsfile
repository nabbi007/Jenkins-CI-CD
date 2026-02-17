pipeline {
  agent any

  options {
    timestamps()
  }

  parameters {
    string(name: 'AWS_REGION', defaultValue: 'eu-west-1', description: 'AWS region for ECR')
    string(name: 'ECR_REPOSITORY', defaultValue: 'jenkins-ci-cd-demo', description: 'ECR repository name')
    string(name: 'AWS_CREDS_ID', defaultValue: 'aws_creds', description: 'Jenkins username/password credential ID (AWS access key and secret)')
    string(name: 'HOST_PORT', defaultValue: '80', description: 'Port exposed on localhost')
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
      agent {
        docker {
          image 'node:18-alpine'
          reuseNode true
        }
      }
      steps {
        sh 'npm ci'
      }
    }

    stage('Test') {
      agent {
        docker {
          image 'node:18-alpine'
          reuseNode true
        }
      }
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
        withCredentials([usernamePassword(credentialsId: params.AWS_CREDS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            set -e
            
            # Verify Docker is running
            docker ps >/dev/null 2>&1 || { echo "Docker not accessible"; exit 1; }
            
            # Authenticate to ECR
            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
            
            # Remove old container
            docker rm -f ${APP_CONTAINER} 2>/dev/null || true
            
            # Run new container
            docker run -d \
              --name ${APP_CONTAINER} \
              --restart unless-stopped \
              -p ${HOST_PORT}:3000 \
              ${FULL_IMAGE}
            
            # Clean up old images
            docker image prune -af >/dev/null 2>&1 || true
            
            # Health check
            echo "Waiting for app to be healthy..."
            for attempt in 1 2 3 4 5 6 7 8 9 10; do
              if curl -fsS "http://localhost:${HOST_PORT}${HEALTH_PATH}" >/dev/null 2>&1; then
                echo "✓ Deployment verified at http://localhost:${HOST_PORT}${HEALTH_PATH}"
                docker logout ${ECR_REGISTRY} 2>/dev/null || true
                exit 0
              fi
              sleep 2
            done
            
            echo "✗ Health check failed after deployment"
            docker logs --tail 50 ${APP_CONTAINER} || true
            docker logout ${ECR_REGISTRY} 2>/dev/null || true
            exit 1
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
