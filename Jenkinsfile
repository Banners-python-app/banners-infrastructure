pipeline {
    agent any
    options {
        skipDefaultCheckout(true)   // disable automatic checkout so we can control manually
        timestamps()        // show timestamps in console log, ensure plugin is installed
        disableConcurrentBuilds()
    }

    parameters{
        choice(name: 'TF_ACTION', choices: ['apply', 'destroy'], description: 'Select the Terraform action to execute')
    }

    environment {
        AWS_REGION = "us-east-1"
        TF_VERSION = "1.10"
        TARGET_ENV = "${env.BRANCH_NAME == 'prod' ? 'prod' : 'prod'}"
    }
    stages {
        /*
        stage('STAGE 0: Safety for prod') {
            steps{
                script {
                    if (params.TF_ACTION == 'destroy' && env.BRANCH_NAME == 'prod') {
                        error("FATAL: Terraform destroy is strictly forbidden on the Production branch.")
                    }
                }
            }
        }
        */

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
                            // Override the hardcoded entrypoint so Jenkins can inject 'cat'
                            args '--entrypoint=""' 
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
                script {
                    def planFlag = (params.TF_ACTION == 'destroy') ? '-destroy' : ''

                    sh """
                    cd envs/${TARGET_ENV}
                    terraform init
                    terraform validate
                    terraform plan ${planFlag} -input=false -no-color -out=tfplan

                    terraform show -no-color tfplan > plan.txt
                    """ 
                }
            }
        }
        stage('STAGE 6: Publish plan and approval') {
            when {
                anyOf {
                    branch 'prod'
                    expression {params.TF_ACTION == 'destroy'}
                }
            }
            steps{
                script {
                    archiveArtifacts artifacts: "envs/${TARGET_ENV}/plan.txt", allowEmptyArchive: false
                    echo "Plan generated and archived. Waiting for approval...!"

                    if (params.TF_ACTION == 'destroy') {
                        def confirm = input(
                            message: "WARNING: Review plan.txt. You are about to DESTROY ${TARGET_ENV}. Type 'DESTROY' to confirm.",
                            parameters: [string(name: 'CONFIRM', description: 'Type DESTROY here')]
                        )
                        if (confirm != 'DESTROY') {
                        error("Destruction aborted by user")
                        }
                    } else {
                        timeout(time: 1, unit: 'HOURS') {
                            input message: "Review plan.txt in artifacts. Approve Deployment to Production?",
                                ok: "Deploy Infrastructure",
                                submitter: "admin"       // jenkins username
                        }
                    }    
                }
            }
        }
        stage('STAGE 7: Terraform apply') {
            when {
                anyOf {
                    branch 'prod'
                    expression {params.TF_ACTION == 'destroy'} 
                } 
            }
            steps {
                script {
                    if (params.TF_ACTION == 'destroy') {
                        echo "Executing Pre-Destroy Cleanup and Terraform Destroy on ${TARGET_ENV}..."
                        sh """
                            # Authenticate EKS cluster
                            aws eks update-kubeconfig --region ${AWS_REGION} --name ban-cluster

                            # Deleting ArgoCD applications
                            echo "Deleting ArgoCD applications"
                            kubectl delete applications --all -n argocd --wait=false || true
                            sleep 15

                            echo "Terminating Karpenter EC2 Instances..."
                            kubectl delete nodepool --all --wait=false || true
                            kubectl delete ec2nodeclass --all --wait=false || true
                            sleep 20

                            echo "Clearing stubborn finalizers..."
                            kubectl get namespace argocd -o json | jq '.spec.finalizers=[]' | kubectl replace --raw /api/v1/namespaces/argocd/finalize -f - || true

                            echo "Executing Terraform Destroy using the approved plan..."
                            cd envs/${TARGET_ENV}
                            terraform apply -no-color tfplan
                            
                            echo "Teardown Complete."
                           """
                        } else {
                            echo "Applying the terraform apply"
                            sh """
                                cd envs/${TARGET_ENV}
                                terraform apply -no-color tfplan 
                            """
                        }
                    }
                }   
            }
        }

    post{
        success {
            echo "Infrastructure operation (${params.TF_ACTION}) completed successfully for ${TARGET_ENV}."
        }
        failure {
            echo "Terraform pipeline failed! Check the console logs"
        }
        always {
            sh "rm -f envs/${TARGET_ENV}/tfplan envs/${TARGET_ENV}/plan.txt"
        }
    }
}