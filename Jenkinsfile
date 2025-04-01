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
                withKubeConfig([serverUrl: "https://exampleaks1-0tlmtrhy.hcp.eastus.azmk8s.io", credentialsId: 'cluster-token']) {
                    sh "helm uninstall todo-chart || true"
                    sh "helm install todo-chart helm/todo-chart-${BUILD_NUMBER}.tgz"
                }
            }
        }
    }
    
    post {
        always {
            script {
                sh "./log-rotation.sh"
            }
        }
    }
}