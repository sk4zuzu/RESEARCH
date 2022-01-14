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

def results = [:]
def builders = [:]
for (item in generate_jobs(8)) {
    def job = item

    builders[job] = {
        node('agents') {
            println "JOB = ${job}, NODE_NAME = ${env.NODE_NAME}"
            sh 'uname -a'
            sh 'date'
            sh 'sleep 5'
            results[job] = [node: env.NODE_NAME]
        }
    }
}

throttle(['throttle_me_that']) {
    parallel builders
}

for (item in results) {
    println "${item.key}: ${item.value}"
}
