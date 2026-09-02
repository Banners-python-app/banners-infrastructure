pipeline {
    agent any
    options {
        skipDefaultCheckout(true)   // disable automatic checkout so we can control manually
        timestamps()        // show timestamps in console log, ensure plugin is installed
        disableConcurrentBuilds()
    }

    environment {
        AWS_REGION = "us-east-1"
        TF_VERSION = "1.10"
        TARGET_ENV = "${env.BRANCH_NAME == 'prod' : 'dev'}"
    }
    stages {
        stage('STAGE 1: Checkout & setup') {
            steps {
                checkout scm        // checkout repo
                sh '''
                    if ! command -v terraform &> /dev/null; then
                        echo "Kindly install Terraform on Jenkins agents first then try....!
                        exit 1
                    fi
                    echo "Terraform available going to next steps...!"
                   '''
            }
        }
        stage ('STAGE 2: Terraform format check') {
            steps{
                sh "terraform fmt -recursive"       
            // pipeline fail if any issue in tf file, recursive: depply scans all the dir
            }     
        }
        stage ('STAGE 3: Terraform linting') {
            steps{
                sh "tflint -f compact"
            // tflint will check and give result in compact fmt
            }
        }
        stage('STAGE 4: Scanning using checkov') {
            steps{
                sh '''
                    if ! command -v checkov &> /dev/null; then
                        echo "Error: chekov not installed kindly install"
                        exit 1
                    fi
                    checkov -d . --framework=terraform
                   '''
            }
            
        }
        stage('STAGE 5: Terraform plan') {
            sh '''
                cd envs/${TARGET_ENV}
                terraform init
                terraform validate
                terraform plan -no-color -out=tfplan > plan.txt
               ''' 
        }
        stage('STAGE 6: Publish plan and approval') {
            steps{
                script {
                    archiveArtifacts artifact: 'envs/${TARGET_ENV}/plan.txt', allowEmptyArchive: false
                    echo "Plan generated and archived. Waiting for approval...!"

                    timeout(time: 1, unit: 'HOURS') {
                        input message: "Review plan.txt in artifacts. Approve Deployment to Production?",
                              ok: "Deploy Infrastructure",
                              submitter: "admin"       // jenkins username
                    }
                }
            }
        }
        stage('STAGE 7: Terraform apply') {
            steps {
                echo "Applying the terraform apply"
                sh '''
                    cd envs/${TARGET_ENV}
                    terraform apply -no-color tfplan 
                   ''' 
            }
        }
    }
    post{
        success {
            echo "Infra provisioned successfully"
        }
        failure {
            error("Terraform pipeline failed! Check the console logs")
        }
        always {
            sh "rm -f envs/${TARGET_ENV}/tfplan envs/${TARGET_ENV}/plan.txt"
        }
    }
}