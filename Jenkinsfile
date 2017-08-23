#!groovy


// Get the AWS prefix if it exists
def aws_env_name() {
  try { if ('' != AWS_ENV_NAME) { return AWS_ENV_NAME } }
  catch (MissingPropertyException e) { return false }
}

// SLACK_CHANNEL resolution is first via Jenkins Build Parameter SLACK_CHANNEL fed in from console,
// then from $DOCKER_TRIGGER_TAG which is sourced from the Docker Hub Jenkins plugin webhook.
def slack_channel() {
  try { if ('' != SLACK_CHANNEL) { return SLACK_CHANNEL } }
  catch (MissingPropertyException e) { return '#ci_cd' }
}


// simplify the generation of Slack notifications for start and finish of Job
def jenkinsSlack(type) {
  channel = slack_channel()
  aws_env_name = aws_env_name()
  def jobInfo = "\n » ${aws_env_name} :: ${JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}|job>) (<${env.BUILD_URL}/console|console>)"

  if (type == 'start'){
    slackSend channel: channel, color: 'blue', message: "build started${jobInfo}"
  }
  if (type == 'finish'){
    def buildColor = currentBuild.result == null? "good": "warning"
    def buildStatus = currentBuild.result == null? "SUCCESS": currentBuild.result
    def msg = "build finished - ${buildStatus}${jobInfo}"
    slackSend channel: channel, color: buildColor, message: "${msg}"
  }
}


def lastBuildResult() {
 def previous_build = currentBuild.getPreviousBuild()
  if ( null != previous_build ) { return previous_build.result } else { return 'UKNOWN' }
}

try {

  node {
    wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm', 'defaultFg': 2, 'defaultBg':1]) {
      cleanWs()
      jenkinsSlack('start')
      checkout scm

      stage('bootstrap') {
        sh "./scripts/bootstrap"
      }

      stage('Build') {
        sh "./scripts/build"
      }

      stage ('Build Network Components') {
        sh "docker run --rm  " +
          "--env-file .env " +
          "rancherlabs/terraform_ha_v2:latest /bin/bash -c \'cd \"\$(pwd)\" && ./scripts/network\'"
      }

      stage ('Build Database Components') {
        sh "docker run --rm  " +
          "--env-file .env " +
          "rancherlabs/terraform_ha_v2:latest /bin/bash -c \'cd \"\$(pwd)\" && ./scripts/database\'"
      }

      stage ('Build Management Components') {
        sh "docker run --rm  " +
          "--env-file .env " +
          "rancherlabs/terraform_ha_v2:latest /bin/bash -c \'cd \"\$(pwd)\" && ./scripts/management\'"
      }

      stage ('Wait until the setup is ready') {
        sh '''
            until $(curl --silent --head --fail https://${AWS_DOMAIN_NAME}); do
            sleep 5
            done
            echo "Rancher HA URL: https://${AWS_DOMAIN_NAME}"
        '''
        }
    } // wrap
  } // node
} catch(err) { currentBuild.result = 'FAILURE' }


jenkinsSlack('finish')
