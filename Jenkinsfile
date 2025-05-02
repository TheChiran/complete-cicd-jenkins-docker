pipeline {
    agent any
    
    tools {
        nodejs 'nodejs-22-6-0'
    }

    environment {
        MONGO_URI = credentials('solar-app-mongo-uri')
        WEB_SERVER_IP = credentials('web-server-ip')
        K8S_SERVER_IP = credentials('k8s_server_ip')
        GITLAB_URL = credentials('gitlab-url')
        GITLAB_URL_WITH_TOKEN = credentials('gitlab-url-with-token')
        GITLAB_TOKEN = credentials('gitlab-token')
        // NVD_API_KEY = credentials('nvd-api-key')
    }
    
    options {
        disableResume()
        disableConcurrentBuilds abortPrevious: true
    }

    stages {
        // stage('Installing Dependencies') { // so we can check locally if this works before making / converting into image
        //     steps {
        //         sh 'npm install --no-audit'
        //     }
            
        // }

        stage('Git Information') { // so we can check locally if this works before making / converting into 
            steps {
                sh 'printenv | grep -i branch'
            }
            
        }

        // stage('Dependency Scanning') {
        //     parallel {
        //         stage('NPM Dependency Audit') {
        //             steps {
        //                 sh '''
        //                     npm audit --audit-level=critical
        //                     echo $?
        //                 '''
        //             }
        //         }

        //         // OWASP db is getting error for now
        //         // stage('OWASP Dependency Check') {
        //         //     steps {
        //         //         dependencyCheck additionalArguments: '''--scan \'./\'
        //         //                         --out \'./\'
        //         //                         --format \'ALL\'
        //         //                         --prettyPrint
        //         //                         --nvdApiKey "\\${NVD_API_KEY}"
        //         //                         --nvdApiDelay 180000
        //         //                         --nvdMaxRetryCount 5
        //         //                         --noupdate
        //         //         ''', nvdCredentialsId: 'nvd-api-key', odcInstallation: 'OWASP-DepCheck-12'

        //         //         dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: false
        //         //     }
        //         // }
        //     }
        // }

        // stage('Unit Testing') {
        //    options { retry(2) }
        //    steps {
        //        sh('MONGO_URI=$MONGO_URI npm test')
        //    }
        // }

        // stage('Code Coverage') {
        //     steps {
        //         catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
        //             sh('MONGO_URI=$MONGO_URI npm run coverage')
        //         }
        //     }
        // }

        // stage('Build Docker Image') {
        //     steps {
        //         sh  'printenv'
        //         sh  'bash /usr/bin/remove-unused-solar-system-images.sh' 
        //         sh  'docker build -t chiran97/solar-system:$GIT_COMMIT .'
        //     }
        // }

        // stage('Trivy Vulnerability Scanner') {
        //     steps {
        //         sh  ''' 
        //             trivy image chiran97/solar-system:$GIT_COMMIT \
        //                 --severity LOW,MEDIUM,HIGH \
        //                 --exit-code 0 \
        //                 --quiet \
        //                 --format json -o trivy-image-MEDIUM-results.json

        //             trivy image chiran97/solar-system:$GIT_COMMIT \
        //                 --severity CRITICAL \
        //                 --exit-code 1 \
        //                 --quiet \
        //                 --format json -o trivy-image-CRITICAL-results.json
        //         '''
        //     }
        //     post {
        //         always {
        //             sh '''
        //                 trivy convert \
        //                     --format template --template "/var/lib/jenkins/trivy-templates/html.tpl" \
        //                     --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json 

        //                 trivy convert \
        //                     --format template --template "/var/lib/jenkins/trivy-templates/html.tpl" \
        //                     --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json

        //                 trivy convert \
        //                     --format template --template "/var/lib/jenkins/trivy-templates/junit.tpl" \
        //                     --output trivy-image-MEDIUM-results.xml  trivy-image-MEDIUM-results.json 

        //                 trivy convert \
        //                     --format template --template "/var/lib/jenkins/trivy-templates/junit.tpl" \
        //                     --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json
        //             '''
        //         }
        //     }
        // } 

        // stage('Push Docker Image') {
        //     steps {
        //         withDockerRegistry(credentialsId: 'docker-hub-credentials', url: "") {
        //             sh  'docker push chiran97/solar-system:$GIT_COMMIT'
        //         }
        //     }
        // }

        // stage('Deploy - AWS EC2 / Remote Server / Staging Server') {
        //     when {
        //         branch 'feature/*'
        //     }
        //     steps {
        //         sh 'sleep 5s'
        //         script {
        //                 sshagent(['web_server_cred']) {
        //                     sh  'bash /usr/bin/remove-unused-solar-system-images.sh' // remove previous / not associated with any container images || Optional
        //                     sh '''
        //                         ssh -o StrictHostKeyChecking=no root_user@"$WEB_SERVER_IP" "
        //                             if sudo docker ps -a | grep -q "solar-system"; then
        //                                 echo "Container found. Stopping..."
        //                                 sudo docker stop "solar-system" && sudo docker rm "solar-system"
        //                                 echo "Container stopped and removed."
        //                             fi
        //                             sudo docker run --name solar-system \
        //                                 -e MONGO_URI="$MONGO_URI" \
        //                                 -p 5000:3000 -d chiran97/solar-system:"$GIT_COMMIT"
        //                         "
        //                     '''
        //             }
        //         }
        //     }
            
        // }

        // stage('Integration Testing - AWS EC2') {
        //     when {
        //         branch 'feature/*'
        //     }
        //     steps {
        //         sh  '''
        //             bash integration-testing-ec2.sh
        //         '''

        //     }
        // }

        stage('K8S - Update Image Tag') {
            when {
                expression { env.GIT_BRANCH == 'stagging' }
            }
            steps {
                sh 'echo $PWD'
                sh 'git clone -b main http://192.168.10.164:5050/chiran97/solar-system-gitops'
                sh "echo URL with Token: $GITLAB_URL_WITH_TOKEN"

                dir("solar-system-gitops/solar-system-chart") {
                    sh '''
                        # git checkout main
                        # git checkout -b feature-$GIT_COMMIT
                        # def branchName = "feature-${env.GIT_COMMIT}"

                        git checkout main

                        git checkout -b feature-$BUILD_ID

                        # Assuming your values.yaml has the structure:
                        # container:
                        #   name: solar-system-app
                        #   image: user/solar-system:old-tag
                        #   port: 3000

                        # Construct the regex to find the 'image:' line and replace the tag
                        # OLD_IMAGE=$(yq '.container.image' values.yaml)
                        OLD_IMAGE=$(python3 -c "import yaml, sys; f = open('values.yaml', 'r'); data = yaml.safe_load(f); f.close(); print(data['container']['image'])")
                                    echo "Old Image: '$OLD_IMAGE'"
                        NEW_IMAGE="chiran97/solar-system:$GIT_COMMIT"
                        sed -i "s#${OLD_IMAGE}#${NEW_IMAGE}#g" values.yaml

                        cat values.yaml

                        # Commit and Push to Feature Branch ####
                        git config --global user.email "tonmoychiran449@gmail.com"
                        git remote set-url origin https://chiran97:$GITLAB_TOKEN@http://192.168.10.164:5050/chiran97/solar-system-gitops.git
                        # git remote set-url origin http://$GITEA_TOKEN@64.227.187.25:5555/dasher-org/solar-system-gitops-argocd
                        git add values.yaml
                        git commit -am "Updated docker image tag in values.yaml to $BUILD_ID"
                        git push http://chiran97:$GITLAB_TOKEN@192.168.10.164:5050/chiran97/solar-system-gitops.git/ feature-$BUILD_ID
                        # git push -u origin feature-$BUILD_ID
                    '''
                }
            }
        }

        stage('K8S - Raise PR') {
            when {
                 expression { env.GIT_BRANCH == 'stagging' }
            }
            steps {
                sh """
                    curl -X 'POST' \
                        'http://192.168.10.164:5050/api/v4/projects/chiran97%2Fsolar-system-gitops/merge_requests' \
                        -H 'accept: application/json' \
                        -H 'PRIVATE-TOKEN: $GITLAB_TOKEN' \
                        -H 'Content-Type: application/json' \
                        -d '{
                            "assignee_username": "chiran97",
                            "source_branch": "feature-$BUILD_ID",
                            "target_branch": "main",
                            "description": "Updated docker image in deployment manifest",
                            "title": "Updated Docker Image"
                        }'
                """
            }
        }

        stage('App Deployed?') {
            when {
                expression { env.GIT_BRANCH == 'main' }
            }
            steps {
                timeout(time: 1, unit: 'DAYS') {
                    input message: 'Is the PR Merged and ArgoCD Synced?', ok: 'YES! PR is Merged and ArgoCD Application is Synced'
                }
            }
        }
    }

    post {
        always {
            deleteDir() /* clean up our workspace */
            // script {
            //     if (fileExists('nodejs-app')) {
            //         sh 'rm -rf nodejs-app'
            //     }
                
            //     if (fileExists('nodejs-app/solar-system-gitops/solar-system-chart')) {
            //         sh 'rm -rf nodejs-app/solar-system-gitops/solar-system-chart'
            //     }
            // }

            // junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'
            // junit allowEmptyResults: true, stdioRetention: '', testResults: 'dependency-check-junit.xml' 
            // junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'
            // junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'

            // publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'zap_report.html', reportName: 'DAST - OWASP ZAP Report', reportTitles: '', useWrapperFileDirectly: true])

            // publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'Trivy Image Critical Vul Report', reportTitles: '', useWrapperFileDirectly: true])

            // publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'Trivy Image Medium Vul Report', reportTitles: '', useWrapperFileDirectly: true])

            // publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency Check HTML Report', reportTitles: '', useWrapperFileDirectly: true])

            // publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }

}