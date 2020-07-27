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

    stage('Pipeline complete') {
      steps{
        script {
          echo "Pipeline completed!"
        }
      }
    }

  }
}
