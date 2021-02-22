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
  }

  stages {

    stage('Display environment variables') {
      steps {
        script {
          openshift.withProject() {
            sh """
              set
              echo "openshift.project() is ${openshift.project()}"
            """
          }
        }
      }
    }
    stage('Display environment variables 2') {
      steps {
        script {
          openshift.withProject() {
            sh """
              set
              echo "openshift.project() is ${openshift.project()}"
            """
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
          openshift.withProject() {
            sh """
              set
              echo "openshift.project() is ${openshift.project()}"
            """
          }
        }
      }
    }

    stage('Create image-build ImageStream') {
      steps {
        dir("$WORKSPACE") {
          sh """
            oc process \
                --filename ${OPENSHIFT_RESOURCES_DIRECTORY}/build-imagestream-template.yaml \
                --param=APPLICATION_NAME=${APPLICATION_NAME} \
              | oc apply \
                --namespace ${IMAGE_REGISTRY_NAMESPACE} \
                --filename -
          """
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

    stage('Pipeline complete') {
      steps{
        script {
          echo "Pipeline completed!"
        }
      }
    }

  }
}
