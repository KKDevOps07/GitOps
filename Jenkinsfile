pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION       = "true"
        TF_VAR_aws_access_key  = credentials('aws_access_key')    // Jenkins credentials
        TF_VAR_aws_secret_key  = credentials('aws_secret_key')    // Jenkins credentials
        AWS_DEFAULT_REGION     = "us-east-1"
    }

    stages {
        stage('Clone Repository') {
            steps {
                git credentialsId: 'Githubaccess', url: 'https://github.com/KKDevOps07/GitOps.git', branch: 'master'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Fmt') {
            steps {
                sh 'terraform fmt -check'
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
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }

    post {
        always {
            echo "Terraform apply pipeline complete"
        }
    }
}
