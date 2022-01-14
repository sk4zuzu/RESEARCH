#!/usr/bin/env groovy

throttle(['throttle_me_that']) {
    node(env.LABEL) {
        println "JOB = ${env.JOB}, NODE_NAME = ${env.NODE_NAME}"
        sh 'uname -a'
        sh 'sleep 5'
        env.node = env.NODE_NAME
    }
}
