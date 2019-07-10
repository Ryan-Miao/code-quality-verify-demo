node('slave001') {

    properties([gitLabConnection('gitlab-bigdata')])

    stage('Prepare') {
        echo "1.Prepare Stage"

        checkout scm
        updateGitlabCommitStatus name: 'build', state: 'pending'

        project_module = '.'
        pom = readMavenPom file: "${project_module}/pom.xml"
        echo "group: ${pom.groupId}, artifactId: ${pom.artifactId}, version: ${pom.version}"
        script {
            build_tag = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
            build_tag = "${env.BRANCH_NAME}-${build_tag}"
//            if (env.BRANCH_NAME != 'master' && env.BRANCH_NAME != null) {
//                build_tag = "${env.BRANCH_NAME}-${build_tag}"
//            }

            currentBuild.displayName = BUILD_NUMBER + "_" +build_tag
        }
    }

    stage('Compile And UnitTest') {
        echo "2.Compile the code"

        try {
            sh "mvn clean install"
            junit testResults: '**/target/*-reports/TEST-*.xml'
            jacoco()
        } catch(Exception ex){
            updateGitlabCommitStatus name: 'build', state: 'failed'
            throw ex;
        } finally {

        }
        updateGitlabCommitStatus name: 'build', state: 'success'
        updateGitlabCommitStatus name: 'Basic Quality Check', state: 'pending'
    }


    stage('Basic Quality Report') {
        echo "3.Basic quality report"
        sh "mvn site "

        def java = scanForIssues tool: java()
        def javadoc = scanForIssues tool: javaDoc()

        publishIssues id: 'analysis-java', name: 'Java Issues', issues: [java, javadoc]  //, filters: [includePackage('io.jenkins.plugins.analysis.*')]

        def checkstyle = scanForIssues tool: checkStyle(pattern: '**/target/checkstyle-result.xml')
        publishIssues issues: [checkstyle]

        def pmd = scanForIssues tool: pmdParser(pattern: '**/target/pmd.xml')
        publishIssues issues: [pmd]

        def cpd = scanForIssues tool: cpd(pattern: '**/target/cpd.xml')
        publishIssues issues: [cpd]

        def spotbugs = scanForIssues tool: spotBugs(pattern: '**/target/findbugsXml.xml')
        publishIssues issues: [spotbugs]

        def maven = scanForIssues tool: mavenConsole()
        publishIssues issues: [maven]

        publishIssues id: 'analysis-all', name: 'All Issues',
                issues: [checkstyle, pmd, spotbugs] //, filters: [includePackage('io.jenkins.plugins.analysis.*')]
    }

    stage('Basic Quality Check') {
        echo "3.1 Check quality threshold"

        try {
            echo "Just skip check for demo, but should check when work"
            //sh "mvn pmd:check  pmd:cpd  checkstyle:check  findbugs:check"
        } catch(Exception ex){
            updateGitlabCommitStatus name: 'Basic Quality Check', state: 'failed'
            throw ex;
        } finally {

        }
        updateGitlabCommitStatus name: 'Basic Quality Check', state: 'success'
    }


    stage('SonarQube analysis') {

        updateGitlabCommitStatus name: 'SonarQube analysis', state: 'pending'
        def sonarqubeScannerHome = tool name: 'SonarQube Scanner'

        withSonarQubeEnv('SonarQube') {
            sh "${sonarqubeScannerHome}/bin/sonar-scanner -Dproject.settings=./sonar-project.properties"
        }

    }

    // No need to occupy a node
    stage("SonarQube Quality Gate"){
        timeout(time: 1, unit: 'MINUTES') { // Just in case something goes wrong, pipeline will be killed after a timeout
            def qg = waitForQualityGate() // Reuse taskId previously collected by withSonarQubeEnv
            if (qg.status != 'OK') {
                updateGitlabCommitStatus name: 'SonarQube analysis', state: 'failed'
                error "Pipeline aborted due to quality gate failure: ${qg.status}"
            } else {
                updateGitlabCommitStatus name: 'SonarQube analysis', state: 'success'
            }
        }
    }

    if (env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'dev' ) {
        stage("Build Docker Image"){
            echo "build docker image"
            echo "Only dev/master branch can build docker image"
        }

        if(env.BRANCH_NAME == 'dev'){
            stage("Deploy to test"){
                echo "branch dev to deploy to environment test"
            }

            stage("Integration test"){
                echo "test环境集成测试"
            }

        }

        if(env.BRANCH_NAME == 'master'){
            stage("Deploy to prod"){
                echo "branch master to deploy to environment prod"
            }

            stage("Health check"){
                echo "prod检查"
            }

        }
    }


}







