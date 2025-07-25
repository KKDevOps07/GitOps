pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION       = "true"
        AWS_ACCESS_KEY_ID      = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY  = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION     = "us-east-1"
    }

    stages {
        stage('Clone Repository') {
            steps {
                git credentialsId: 'Githubaccess', url: 'https://github.com/KKDevOps07/GitOps.git', branch: 'master'
            }
        }

        stage('Install Terrascan') {
            steps {
                sh 'wget https://github.com/tenable/terrascan/releases/latest/download/terrascan_windows_amd64.zip -O terrascan.zip'
                sh 'unzip terrascan.zip -d terrascan_bin'
                sh 'chmod +x terrascan_bin/terrascan.exe'
            }
        }

        stage('Terrascan Usage') {
            steps {
            echo 'Terrascan is used for static code analysis of Terraform files.'
            sh 'terrascan_bin/terrascan.exe version'
            }
        }

        stage('Terrascan Scan') {
            steps {
                script {
                    def scanStatus = sh(script: 'terrascan_bin/terrascan.exe scan -t aws -d .', returnStatus: true)
                    if (scanStatus == 0) {
                        echo 'Terrascan scan successful.'
                    } else {
                        echo 'Terrascan scan failed. Skipping to next stages.'
                    }
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        
        stage('Terraform Fmt') {
            steps {
                sh 'terraform fmt'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }
        
        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }
    }

    post {
        always {
            echo "Terraform apply pipeline complete"
        }
    }
}
