pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "heyanoop/todo-api:${BUILD_NUMBER}"
    }

    stages {
        stage('Code Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/heyanoop/api-service-todo-list.git'
            }
        }

         stage('Install Dependencies') {
            steps {
                script {
            sh '''
            python -m venv venv
            source venv/bin/activate
            pip install --upgrade pip
            pip install poetry
            poetry install
            '''
        }
            }
        }
        
         stage('SonarQube Analysis') {
            steps {
                script {
                    
                    def scannerHome = tool 'sonar-scanner';

                    withSonarQubeEnv(credentialsId: 'sonarqube-token') {
                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=todo-api-service \
                            -Dsonar.projectName="Todo API Service" \
                            -Dsonar.sources=app.py,protobuf \
                            -Dsonar.exclusions=**/test/**,**/tests/**
                        """
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                withCredentials([string(credentialsId: 'dockerhub-password', variable: 'DOCKER_PASS')]) {
                    sh """
                    docker login -u heyanoop -p ${DOCKER_PASS}
                    docker build -t ${DOCKER_IMAGE} .
                    docker push ${DOCKER_IMAGE}
                    """ 
                }
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh "trivy image --format table ${DOCKER_IMAGE} | tee trivy_scan.log"

                script {
                    echo "🔍 Security Scan Results:"
                    sh "cat trivy_scan.log"
                }
            }
        }
      
        stage('Update manifest') {
            steps {
                sh "sed -i 's|image: heyanoop/todo-api:.*|image: heyanoop/todo-api:${BUILD_NUMBER}|' manifest/api-deployment.yaml"
            }
        }
 
        stage('Helm deploy') {
            steps {
                withKubeConfig([serverUrl: "https://exampleaks1-qmdpoi1f.hcp.southindia.azmk8s.io", credentialsId: 'cluster-token']) {
                    sh "kubectl apply -f manifest/api-deployment.yaml"
                }
            }
        }
        
        stage('Log Rotation') {
            steps {
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-key', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                   
                    sh '''
                    #!/bin/bash
                    
                    LOG_FILE="build-log-$(date +%Y%m%d-%H%M%S).log"
                    
                    cp /var/lib/jenkins/jobs/api-service/builds/${BUILD_NUMBER}/log ./${LOG_FILE}
                    
                    aws s3 cp ${LOG_FILE} s3://jenkins-log-bucket-2025/
                    rm ${LOG_FILE}
                    
                    echo "Log rotation completed"
                    '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline completed with status: ${currentBuild.result}"
        }
    }
}