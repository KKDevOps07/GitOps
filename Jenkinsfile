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
                sh '''
                    echo "Downloading and installing Terrascan..."
                    curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | \
                    grep -o -E "https://.+?_Linux_x86_64.tar.gz" | head -n1)" -o terrascan.tar.gz
                    tar -xf terrascan.tar.gz terrascan
                    sudo install terrascan /usr/local/bin/
                    rm terrascan terrascan.tar.gz
                    terrascan version
                '''
            }
        }

        stage('Terrascan Usage') {
            steps {
                echo 'Terrascan is used for static code analysis of Terraform files.'
                sh 'terrascan version'
            }
        }

        stage('Terrascan Scan') {
            steps {
                script {
                    def scanStatus = sh(script: 'terrascan scan -t aws -d .', returnStatus: true)
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