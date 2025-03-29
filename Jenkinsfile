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

      
        // stage('Update Manifest') {
        //     steps {
        //        sh "sed -i 's|image: heyanoop/todo-api:.*|image: heyanoop/todo-api:${BUILD_NUMBER}|' k8s-specifications/result-deployment.yaml"
        //     }
        // }

 
        // stage('Deploy to AKS') {
        //     steps {
        //         withKubeConfig([serverUrl: "https://exampleaks1-0tlmtrhy.hcp.eastus.azmk8s.io", credentialsId: 'cluster-token']) {
        //             sh 'kubectl apply -f k8s-specifications/result-deployment.yaml -n votingapp'
        //         }
        //     }
        // }
        }
    }

    