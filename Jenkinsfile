def getCommit(){
  return sh(returnStdout: true, script: "git rev-parse HEAD | head -c 7").trim()
}

def getBuildTimestamp(){
  return sh(returnStdout: true, script: "date +'%Y-%m-%dT%H:%M:%SZ'").trim()
}

def getVersion(){
  //sh(script: "git fetch --tags")
  return sh(returnStdout: true, script: "git describe --tags --abbrev=0").toString().trim()
}

def run_bandit_test(){
    dir('bandit'){
      sh(script:"bash ${BANDIT_DOCKER_SCRIPT}")
    }
    sh(script:"docker exec -i ${CONTAINER} chmod a+x /app_src/bandit/run_bandit.sh")
    return_s= sh(returnStatus:true, script:"docker exec -i ${CONTAINER} /app_src/bandit/run_bandit.sh")
    echo "${return_s}"
    sh "docker rm  -f ${CONTAINER}"
    sh "docker rmi -f ${BANDIT_IMAGE}:${BANDIT_TAG}"

    if ("${return_s}" != '0') {
      //archiveArtifacts artifacts: 'reports/banditReport.html'
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

def getVersioningVariables(){
    //sh "git fetch --tags"
    sh "echo -e \"export GIT_COMMIT=\$(git rev-parse HEAD)\nexport GHE_VERSION=\$(git describe --tags --abbrev=0)\nexport BUILD_TIMESTAMP=\$(date +'%Y-%m-%dT%H:%M:%SZ')\" > .version_vars.conf"
    stash includes: ".version_vars.conf", name:"versionVars"

    sh "echo \$(git rev-parse HEAD | head -c 7)-\$(date +%Y%m%d%H%M%S)  > .docker.tag"
    stash includes: '.docker.tag', name: 'dockerTag'
}

pipeline {
  agent any
  environment {
      GIT_COMMIT=getCommit()
      dir=pwd()
      INIT_GENERATOR_SCRIPT='generate-init-py.sh'
      // Bandit Test
        BANDIT_DOCKER_SCRIPT= 'bandit_test_docker.sh'
        CONTAINER="bandit-test-${GIT_COMMIT}"
        BANDIT_IMAGE="bandit"
        BANDIT_TAG="${GIT_COMMIT}"
    }
    
  stages {
    stage("env"){
      agent any
      steps{
        echo sh(returnStdout: true, script: 'env')
      }
    }
    stage("init"){
      agent any
      steps{
        echo "this is an init stage"
        getVersioningVariables()
      }
    }
    stage("Main Pipeline"){
      parallel{
        stage("Initialization") {
          agent any
          steps{
            unstash "versionVars"
            sh "ls -la"
            sh "cat .version_vars.conf"
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
            unstash "dockerTag"
            sh "ls -la"
            sh "cat .docker.tag"
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

