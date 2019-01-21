def getCommit(){
  return sh(returnStdout: true, script: "git rev-parse HEAD").trim()
}

def getBuildTimestamp(){
  return sh(returnStdout: true, script: "date +'%Y-%m-%dT%H:%M:%SZ'").trim()
}

def getVersion(){
  sh(script: "git fetch --tags")
  return sh(returnStdout: true, script: "git describe --tags --abbrev=0").toString().trim()
}

def run_bandit_test(){
    dir('bandit'){
      return_s= sh(returnStatus:true, script:"bash ${BANDIT_DOCKER_SCRIPT}")
    }
    
    sh "docker rm ${CONTAINER}"
    sh "docker rmi ${BANDIT_IMAGE}:${BANDIT_TAG} "

    if ("${return_s}" != '0') {
      //publish report to build page
      publishHTML (target: [
        allowMissing: false,
        alwaysLinkToLastBuild: false,
        keepAll: true,
        reportDir: './reports',
        reportFiles: 'banditReport.html',
        reportName: "Bandit Report"
      ])
      error "Bandit test failed"
    }
}

pipeline {
  agent any
  environment {
      dir=pwd()
      INIT_GENERATOR_SCRIPT='generate-init-py.sh'
      BANDIT_DOCKER_SCRIPT='bandit_test_docker.sh'
      BANDIT_IMAGE='bandit'
      BANDIT_TAG='python3-alpine'
      CONTAINER='bandit_tests'
    }

  stages {
    stage("init"){
      agent any
      steps{
        echo "this is an init stage"
      }
    }
    stage("Main Pipeline"){
      parallel{
        stage("Initialization") {
          agent any
          steps{
            // set variables and generate files
            sh "bash ${INIT_GENERATOR_SCRIPT}"
          }
        }
        stage("Bandit-Docker") {
          agent any
          steps {
            run_bandit_test()
          }
        }
        stage("Test parallel stage"){
          steps{
            echo "This is a parallel execution - to pass"
          }
        }
      }
    }
  }
  
  // Post in Stage executes at the end of Stage instead of end of Pipeline
  post {
    always{
      deleteDir()
    }
    success {
      echo "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
    }
    unstable {
      echo "UNSTABLE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
    }
    failure {
      echo "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
    }
  }
}

