#!/usr/bin/env groovy

def generate_jobs(n) {
    jobs = []
    for (i = 1; i <= n; i++) {
        jobs << "job-${UUID.randomUUID().toString()}"
    }
    jobs
}

node('agents') {
    sh 'sleep 1'
}

def builders = [:]
for (item in generate_jobs(8)) {
    def job = item

    builders[job] = {
        println "JOB = ${job}, NODE_NAME = ${env.NODE_NAME}"

        build job: 'pipeline0', wait: true, parameters: [[
            $class: 'StringParameterValue',
            name: 'JOB',
            value: job,
        ],[
            $class: 'LabelParameterValue',
            name: 'LABEL',
            label: 'agents',
            nodeEligibility: [$class: 'AllNodeEligibility'],
        ]]
    }
}

def results = parallel builders
for (item in results) {
    println "${item.key}: ${item.value.getAbsoluteUrl()} ${item.value.getBuildVariables()}"
}
