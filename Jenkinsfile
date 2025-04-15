pipeline {
    agent any
    
    tools {
        nodejs 'nodejs-22-6-0'
    }

    environment {
        MONGO_URI = credentials('solar-app-mongo-uri')
        WEB_SERVER_IP = credentials('web-server-ip')
    }
    
    options {
        disableResume()
        disableConcurrentBuilds abortPrevious: true
    }

    stages {
        stage('Installing Dependencies') { // so we can check locally if this works before making / converting into image
            steps {
                sh 'npm install --no-audit'
            }
            
        }

        stage('Dependency Scanning') {
            parallel {
                stage('NPM Dependency Audit') {
                    steps {
                        sh '''
                            npm audit --audit-level=critical
                            echo $?
                        '''
                    }
                }

                // OWASP db is getting error for now
                // stage('OWASP Dependency Check') {
                //     steps {
                //         dependencyCheck additionalArguments: '''--scan \'./\'
                //                         --out \'./\'
                //                         --format \'ALL\'
                //                         --prettyPrint
                //                         --nvdApiKey "\\${NVD_API_KEY}"
                //                         --nvdApiDelay 180000
                //                         --nvdMaxRetryCount 5
                //                         --noupdate
                //         ''', nvdCredentialsId: 'nvd-api-key', odcInstallation: 'OWASP-DepCheck-12'

                //         dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: false
                //     }
                // }
            }
        }

        stage('Unit Testing') {
           options { retry(2) }
           steps {
               sh('MONGO_URI=$MONGO_URI npm test')
           }
        }

        stage('Code Coverage') {
            steps {
                catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
                    sh('MONGO_URI=$MONGO_URI npm run coverage')
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh  'printenv'
                sh  'bash /tmp/remove-unused-solar-system-images.sh' // remove previous / not associated with any container images
                sh  'docker build -t chiran97/solar-system:$GIT_COMMIT .'
            }
        }

        stage('Trivy Vulnerability Scanner') {
            steps {
                sh  ''' 
                    trivy image chiran97/solar-system:$GIT_COMMIT \
                        --severity LOW,MEDIUM,HIGH \
                        --exit-code 0 \
                        --quiet \
                        --format json -o trivy-image-MEDIUM-results.json

                    trivy image chiran97/solar-system:$GIT_COMMIT \
                        --severity CRITICAL \
                        --exit-code 1 \
                        --quiet \
                        --format json -o trivy-image-CRITICAL-results.json
                '''
            }
            post {
                always {
                    sh '''
                        trivy convert \
                            --format template --template "/var/lib/jenkins/trivy-templates/html.tpl" \
                            --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json 

                        trivy convert \
                            --format template --template "/var/lib/jenkins/trivy-templates/html.tpl" \
                            --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json

                        trivy convert \
                            --format template --template "/var/lib/jenkins/trivy-templates/junit.tpl" \
                            --output trivy-image-MEDIUM-results.xml  trivy-image-MEDIUM-results.json 

                        trivy convert \
                            --format template --template "/var/lib/jenkins/trivy-templates/junit.tpl" \
                            --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json
                    '''
                }
            }
        } 

        stage('Push Docker Image') {
            steps {
                withDockerRegistry(credentialsId: 'docker-hub-credentials', url: "") {
                    sh  'docker push chiran97/solar-system:$GIT_COMMIT'
                }
            }
        }

        stage('Deploy - AWS EC2 / Remote Server / Staging Server') {
            // when {
            //     branch 'feature/*'
            // }
            steps {
                sh 'sleep 5s'
                script {
                        sshagent(['web_server_cred']) {
                            sh  'bash /tmp/remove-unused-solar-system-images.sh' // remove previous / not associated with any container images
                            sh '''
                                ssh -o StrictHostKeyChecking=no root_user@"$WEB_SERVER_IP" "
                                    if sudo docker ps -a | grep -q "solar-system"; then
                                        echo "Container found. Stopping..."
                                        sudo docker stop "solar-system" && sudo docker rm "solar-system"
                                        echo "Container stopped and removed."
                                    fi
                                    sudo docker run --name solar-system \
                                        -e MONGO_URI="$MONGO_URI" \
                                        -p 5000:3000 -d chiran97/solar-system:"$GIT_COMMIT"
                                "
                            '''
                    }
                }
            }
            
        }

        stage('Integration Testing - AWS EC2') {
            // when {
            //     branch 'feature/*'
            // }
            steps {
                sh 'printenv | grep -i branch'
                sh  '''
                    bash integration-testing-ec2.sh
                '''

            }
        }
    }

    post {
        always {
            script {
                if (fileExists('nodejs-app')) {
                    sh 'rm -rf nodejs-app'
                }
            }

            junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'
            // junit allowEmptyResults: true, stdioRetention: '', testResults: 'dependency-check-junit.xml' 
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'

            // publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'zap_report.html', reportName: 'DAST - OWASP ZAP Report', reportTitles: '', useWrapperFileDirectly: true])

            // publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'Trivy Image Critical Vul Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'Trivy Image Medium Vul Report', reportTitles: '', useWrapperFileDirectly: true])

            // publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency Check HTML Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }

}