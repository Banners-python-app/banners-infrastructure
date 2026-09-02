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
        TARGET_ENV = "${env.BRANCH_NAME == 'prod' ? 'prod' : 'dev'}"
    }
    stages {
        stage('STAGE 1: Checkout & setup') {
            steps {
                checkout scm        // checkout repo
                sh '''
                    if ! command -v terraform > /dev/null 2>&1; then
                        echo "Kindly install Terraform on Jenkins agents first then try....!"
                        exit 1
                    fi
                    echo "Terraform available going to next steps...!"
                   '''
            }
        }
        // Parallel execution of independent static scans
        stage('STAGE 2: Static Analysis & Security Audits') {
            parallel {
                stage('Terraform Format Check') {
                    steps {
                        sh "terraform fmt -recursive"
                    }
                }

                stage('Terraform Linting') {
                    steps {
                        sh '''
                            if command -v tflint > /dev/null 2>&1; then
                                tflint -f compact
                            else
                                echo "Warning: tflint not installed, skipping."
                            fi
                        '''
                    }
                }

                stage('Security Scan (Checkov)') {
                    // Spin up an ephemeral container specifically for this stage
                    agent {
                        docker {
                            image 'bridgecrew/checkov:3.3.16'
                            // reuseNode ensures it runs on the same EC2 instance and workspace
                            reuseNode true 
                        }
                    }
                    steps {
                        sh '''
                            checkov -d . --framework terraform --compact --quiet
                        '''
                    }
                }
            }
        }
        stage('STAGE 5: Terraform plan') {
            steps {
                sh '''
                cd envs/${TARGET_ENV}
                terraform init
                terraform validate
                terraform plan -no-color -out=tfplan > plan.txt
               ''' 
            }
        }
        stage('STAGE 6: Publish plan and approval') {
            when{
                branch 'prod'
            }
            steps{
                script {
                    archiveArtifacts artifacts: 'envs/${TARGET_ENV}/plan.txt', allowEmptyArchive: false
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
            when{
                branch prod
            }
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
            echo "Terraform pipeline failed! Check the console logs"
        }
        always {
            sh "rm -f envs/${TARGET_ENV}/tfplan envs/${TARGET_ENV}/plan.txt"
        }
    }
}