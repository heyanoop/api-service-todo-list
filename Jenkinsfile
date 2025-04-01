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
                sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}"
                sh "trivy image --format table ${DOCKER_IMAGE} | tee trivy_scan.log"

                script {
                    echo "🔍 Security Scan Results:"
                    sh "cat trivy_scan.log"
                }
            }
        }
      
        stage('Update package and push helm') {
            steps {
                sh "sed -i 's|apiservice: heyanoop/todo-api:.*|apiservice: heyanoop/todo-api:${BUILD_NUMBER}|' helm/todo-chart/Chart.yaml"
                sh "helm package helm/todo-chart --version ${BUILD_NUMBER}"
            }
        }
 
        stage('Helm deploy') {
            steps {
                withKubeConfig([serverUrl: "https://exampleaks1-qmdpoi1f.hcp.southindia.azmk8s.io", credentialsId: 'cluster-token']) {
                    sh "helm uninstall todo-chart || true"
                    sh "helm install todo-chart helm/todo-chart-${BUILD_NUMBER}.tgz || echo 'Helm install failed'"
                }
            }
        }
        
       
        stage('Log Rotation') {
            steps {
                script {
                   
                    sh '''
                    #!/bin/bash
                    
                    LOG_FILE="build-log-$(date +%Y%m%d-%H%M%S).log"
                    
                    cp /var/lib/jenkins/jobs/api-service/builds/${BUILD_NUMBER}/log ./${LOG_FILE}
                    
                    aws s3 cp ${LOG_FILE} s3://jenkins-log-bucket-2025/ || echo "S3 upload failed"
                    
                    rm ${LOG_FILE}
                    
                    echo "Log rotation completed"
                    '''
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