pipeline {
    agent {
        label "jenkins-python"
    }
    environment {
      ORG               = 'danielhartnell'
      APP_NAME          = 'sso-dashboard'
      CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    }
    stages {
      stage('CI Build and push snapshot') {
        when {
          branch 'PR-*'
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          container('python') {
            sh "git clone https://github.com/ansible/ansible-container.git"

            sh "cd ansible-container"

            sh "pip install --upgrade pip"

            sh "pip install -e ./ansible-container[docker]"

            sh "cd ansible-container && ansible-container build --with-volumes ../:/dashboard"

            sh "python -m unittest"

            sh 'export VERSION=$PREVIEW_VERSION && skaffold build -f skaffold.yaml'

            sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
          }

          dir ('./charts/preview') {
           container('python') {
             sh "make preview"
             sh "jx preview --app $APP_NAME --dir ../.."
           }
          }
        }
      }
      stage('Build Release') {
        when {
          branch 'master'
        }
        steps {
          container('python') {
            // ensure we're not on a detached head
            sh "git checkout master"
            sh "git config --global credential.helper store"

            sh "jx step git credentials"
            // so we can retrieve the version in later steps
            sh "echo \$(jx-release-version) > VERSION"
          }
          dir ('./charts/sso-dashboard') {
            container('python') {
              sh "make tag"
            }
          }
          container('python') {
            sh "git clone https://github.com/ansible/ansible-container.git"

            sh "pip install --upgrade setuptools"

            sh "pip install -e ./ansible-container[docker]"

            sh "yum install iptables-services -y && systemctl start iptables"

            sh "systemctl restart docker"

            sh "cd ansible && ansible-container build --with-volumes ../:/dashboard --roles-path './roles/dashboard'"

            sh "python -m unittest"

            sh 'export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml'

            sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
          }
        }
      }
      stage('Promote to Environments') {
        when {
          branch 'master'
        }
        steps {
          dir ('./charts/sso-dashboard') {
            container('python') {
              sh 'jx step changelog --version v\$(cat ../../VERSION)'

              // release the helm chart
              sh 'jx step helm release'

              // promote through all 'Auto' promotion Environments
              sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)'
            }
          }
        }
      }
    }
    post {
        always {
            cleanWs()
        }
    }
  }
