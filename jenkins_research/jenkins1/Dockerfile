FROM jenkins/jenkins:2.326-alpine

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

COPY /plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

COPY /jcasc.yaml /var/jenkins_home/jcasc.yaml

ENV CASC_JENKINS_CONFIG /var/jenkins_home/jcasc.yaml
