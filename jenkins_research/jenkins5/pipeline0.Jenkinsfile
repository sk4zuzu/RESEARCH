#!/usr/bin/env groovy

node('built-in') {
    println "NODE_NAME = ${env.NODE_NAME}"
    sh 'uname -a'

    println pwd()

    dir('asd') {
        git url: 'https://github.com/sk4zuzu/RESEARCH.git'
        sh 'pwd && ls -lha'
    }

    stash name: 'asd', includes: 'asd/**'

    tasks = [:]
    names = ['asd']
    names.each { name ->
        tasks[name] = {
            node('agent1') {
                println "NODE_NAME = ${env.NODE_NAME}"
                sh 'uname -a'

                deleteDir()
                unstash name: 'asd'

                dir('asd') {
                    sh 'pwd && ls -lha'
                }
                dir('/a/b/c') {
                    println pwd()
                }
            }
        }
    }

    parallel tasks
    tasks['asd']()
}
