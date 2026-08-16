pipeline {
    agent any

    stages {
        stage('Provision with Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init -input=false'
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        stage('Configure with Ansible') {
            steps {
                dir('ansible') {
                    sh 'ansible-playbook -i inventory.ini playbook.yml'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed: environment provisioned and configured successfully.'
        }
        failure {
            echo 'Pipeline failed — check the stage logs above.'
        }
    }
}
