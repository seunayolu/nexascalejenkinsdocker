pipeline {
    agent {
        label 'node-01'
    }

    environment {
        InstanceIP = '172.31.44.252'
        ServerName = 'ubuntu'
        AWS_REGION = 'eu-west-2'
        ECR_REPO = 'nexascale_moodle'
        REGISTRY_URL = "442042522885.dkr.ecr.eu-west-2.amazonaws.com"
    }

    stages {
        stage ('fetch_code') {
            steps {
                script {
                    echo "fetching application files from Git Repo"
                    withCredentials([string(credentialsId: 'nexascale_gittoken', variable: 'GIT_TOKEN')]) {
                        git branch: 'master', url: "https://${GIT_TOKEN}@github.com/seunayolu/nexascalejenkinsdocker.git"
                    }
                }
            }
        }

        stage ('docker build') {
            steps {
                script {
                    echo "Building Docker Image"
                    sh "docker build -t ${env.REGISTRY_URL}/${env.ECR_REPO}:${BUILD_NUMBER} ."
                }
            }
        }

        stage ('push_image_to_ecr') {
            steps {
                script {
                    echo "Pushing Image to ECR"
                    withAWS(credentials: 'AWSACCESS', region: "${env.AWS_REGION}") {
                        sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.REGISTRY_URL}"
                        sh "docker push ${env.REGISTRY_URL}/${env.ECR_REPO}:${BUILD_NUMBER}"
                    } 
                }
            }
        }

        stage ('deploy_to_ec2') {
            steps {
                script {
                    echo "deploying docker image to EC2"
                    withAWS(credentials: 'AWSACCESS', region: "${env.AWS_REGION}") {
                        sshagent(['nexascale-sshkey']) {
                            sh """
                                scp -o StrictHostKeyChecking=no compose.yaml ${ServerName}@${InstanceIP}:/home/ubuntu

                                ssh -o StrictHostKeyChecking=no ${ServerName}@${InstanceIP} '
                                    export IMAGE_NAME=${REGISTRY_URL}/${ECR_REPO}:${BUILD_NUMBER}
                                    aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.REGISTRY_URL}
                                    docker compose -f /home/ubuntu/compose.yaml up -d
                                '
                            """

                        }
                    }

                }
            }
        }
    }
}