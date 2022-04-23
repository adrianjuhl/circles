pipeline{
  agent {
    label 'maven'
  }
  environment{
    //Use Pipeline Utility Steps plugin to read information from pom.xml into env variables
    MVN_ARTIFACT_ID = readMavenPom().getArtifactId()
    MVN_VERSION = readMavenPom().getVersion()
    GIT_COMMIT_ID = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
    BUILD_DTTM = sh(returnStdout: true, script: 'date +%Y%m%d%H%M%S').trim()
    OPENSHIFT_RESOURCES_DIRECTORY = "cicd/resources/ocp"
    APPLICATION_NAME = "circles"
  }

  stages {

    stage('Display environment variables') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject() {
              sh """
                set
                echo "openshift.project() is ${openshift.project()}"
              """
            }
          }
        }
      }
    }
    stage('Display environment variables 2') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject() {
              sh """
                set
                echo "openshift.project() is ${openshift.project()}"
              """
            }
          }
        }
      }
    }
    stage('mvn clean package') {
      steps {
        dir("$WORKSPACE") {
          sh """
            whoami
            pwd
            ls -al ~
            ls -al ~/.m2
            ls -al
            mvn help:effective-settings
            mvn clean
            mvn clean package
            #mvn --settings=cicd/maven-settings.xml clean package
            ls -al target
          """
        }
      }
    }
    stage('Display environment variables 3') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject() {
              sh """
                set
                echo "openshift.project() is ${openshift.project()}"
              """
            }
          }
        }
      }
    }

    stage('Create image-build ImageStream') {
      steps {
        dir("$WORKSPACE") {
          script {
            openshift.withCluster() {
              openshift.withProject() {
                sh """
                  oc process \
                      --filename ${OPENSHIFT_RESOURCES_DIRECTORY}/build-imagestream-template.yaml \
                      --param=APPLICATION_NAME=${APPLICATION_NAME} \
                    | oc apply \
                      --namespace ${openshift.project()} \
                      --filename -
                """
              }
            }
          }
        }
      }
    }

    stage('Create image-build BuildConfig') {
      steps {
        dir("$WORKSPACE") {
          sh """
            oc process \
                --filename ${OPENSHIFT_RESOURCES_DIRECTORY}/build-buildconfig-template.yaml \
                --param=APPLICATION_NAME=${APPLICATION_NAME} \
                --param=GIT_COMMIT_ID=${GIT_COMMIT_ID} \
                --param=MVN_VERSION=${MVN_VERSION} \
                --param=BUILD_DTTM=${BUILD_DTTM} \
              | oc apply \
                --namespace ${IMAGE_REGISTRY_NAMESPACE} \
                --filename -
          """
        }
      }
    }

    stage('Build image') {
      steps {
        sh """
          echo "*********************************************************************"
          echo Build image
          echo "*********************************************************************"
          ls -al
          ls -al target
          oc start-build ${APPLICATION_NAME} \
              --namespace ${IMAGE_REGISTRY_NAMESPACE} \
              --from-file=target/${MVN_ARTIFACT_ID}.jar \
              --follow
        """
      }
    }

    stage('Create application-deployment DeploymentConfig') {
      steps {
        dir("$WORKSPACE") {
          sh """
            oc get istag ${APPLICATION_NAME}:latest --namespace ${IMAGE_REGISTRY_NAMESPACE} -o template --template='{{ .image.metadata.name }}'
            LATEST_BUILD_IMAGE_SHA256=\$(oc get istag ${APPLICATION_NAME}:latest --namespace ${IMAGE_REGISTRY_NAMESPACE} -o template --template='{{ .image.metadata.name }}')
            echo LATEST_BUILD_IMAGE_SHA256 is \${LATEST_BUILD_IMAGE_SHA256}
            oc process \
                --filename ${OPENSHIFT_RESOURCES_DIRECTORY}/deployment-deployconfig-template.yaml \
                --param=APPLICATION_NAME=${APPLICATION_NAME} \
                --param=IMAGE_REGISTRY_NAMESPACE=${IMAGE_REGISTRY_NAMESPACE} \
                --param=APPLICATION_VERSION=${MVN_VERSION}_${BUILD_DTTM} \
                --param=GIT_COMMIT_ID=${GIT_COMMIT_ID} \
                --param=APPLICATION_IMAGE_SHA256=\${LATEST_BUILD_IMAGE_SHA256} \
                --param=SPRING_APPLICATION_JSON="`cat config/dev.json`" \
              | oc apply \
                    --namespace ${DEVELOPMENT_ENVIRONMENT_NAMESPACE} \
                    --filename -
          """
        }
      }
    }

    stage('Create application-deployment Service') {
      steps {
        dir("$WORKSPACE") {
          sh """
            oc process \
                --filename ${OPENSHIFT_RESOURCES_DIRECTORY}/deployment-service-template.yaml \
                --param=APPLICATION_NAME=${APPLICATION_NAME} \
              | oc apply \
                  --namespace ${DEVELOPMENT_ENVIRONMENT_NAMESPACE} \
                  --filename -
          """
        }
      }
    }

    stage('Create application-deployment Route') {
      steps {
        dir("$WORKSPACE") {
          sh """
            oc process \
                --filename ${OPENSHIFT_RESOURCES_DIRECTORY}/deployment-route-template.yaml \
                --param=APPLICATION_NAME=${APPLICATION_NAME} \
              | oc apply \
                    --namespace ${DEVELOPMENT_ENVIRONMENT_NAMESPACE} \
                    --filename -
          """
        }
      }
    }

    stage('Rollout to Development environment and wait for rollout...') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject("${DEVELOPMENT_ENVIRONMENT_NAMESPACE}") {
              def result = null
              deploymentConfig = openshift.selector("deploymentconfig", "${APPLICATION_NAME}")
              deploymentConfig.rollout().latest()
              timeout(10) {
                result = deploymentConfig.rollout().status("-w")
              }
              if (result.status != 0) {
                error(result.err)
              }
            }
          }
        }
      }
    }

    stage('Pipeline complete') {
      steps{
        script {
          echo "Pipeline completed!"
        }
      }
    }

  }
}
