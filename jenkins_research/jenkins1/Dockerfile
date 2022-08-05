FROM jenkins/jenkins:2.362-alpine

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

COPY /plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

ENV CASC_JENKINS_CONFIG /var/jenkins_home/jcasc_configs

COPY /jcasc.yaml $CASC_JENKINS_CONFIG/

COPY /jobs.yaml $CASC_JENKINS_CONFIG/jobs/
