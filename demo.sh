#!/usr/bin/env bash

TEMP_DIR="upgrade-example"

# Function definitions
check_dependencies() {
    local tools=("vendir" "http")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "$tool not found. Please install $tool first."
            exit 1
        fi
    done
}

talking_point() {
    wait
    clear
}

init() {
    rm -rf "$TEMP_DIR"
    mkdir "$TEMP_DIR"
    cd "$TEMP_DIR" || exit
    clear
}

install_concourse() {
    curl -O https://concourse-ci.org/docker-compose.yml
    echo '      CONCOURSE_ENABLE_ACROSS_STEP: "true"' >> docker-compose.yml
    echo '      CONCOURSE_ENABLE_PIPELINE_INSTANCES: "true"' >> docker-compose.yml
    sed -i 's/image: concourse\/concourse$/image: concourse\/concourse:7.14.1/' docker-compose.yml
    sed -i "s|CONCOURSE_EXTERNAL_URL: http://localhost:8080|CONCOURSE_EXTERNAL_URL: $CONCOURSE_EXTERNAL_URL|g" docker-compose.yml
    sed -i 's/8\.8\.8\.8/1.1.1.1/g' docker-compose.yml
    sed -i 's/tutorial/dashaun-tanzu/g' docker-compose.yml
    sed -i 's/overlay/naive/g' docker-compose.yml

    docker compose down --remove-orphans
    docker compose up -d
}

shutdown_concourse() {
    docker compose down
}

install_fly() {
    until curl 'http://localhost:8080/api/v1/cli?arch=amd64&platform=linux' -o fly; do
        echo "Retrying..."
        sleep 1
    done
#    export REGISTRY_IP="$(docker inspect $(docker compose ps -q registry) | grep -i ipaddress | grep -oP '\d+\.\d+\.\d+\.\d+' | tail -1)"
#    echo $REGISTRY_IP
    chmod +x ./fly
    ./fly -t advisor-demo login -c http://localhost:8080 -u test -p test -n main

    orgs=$(echo "$GITHUB_ORGS" | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g')
    IFS=',' read -ra ORG_ARRAY <<< "$orgs"
    for org in "${ORG_ARRAY[@]}"; do
        ./fly -t advisor-demo set-team --team-name "$org" --local-user test --non-interactive
    done

    ./fly -t advisor-demo set-pipeline --non-interactive \
            -p rewrite-spawner \
            -c ../pipelines/spawner-pipeline.yml \
            -v github_token="$GIT_TOKEN_FOR_PRS" \
            -v github_orgs="$GITHUB_ORGS" \
            -v api_base='https://api.github.com' \
            -v maven_password="$MAVEN_PASSWORD" \
            -v docker-hub-username="$DOCKER_USER" \
            -v docker-hub-password="$DOCKER_PASS" > /dev/null
    ./fly -t advisor-demo unpause-pipeline -p rewrite-spawner
    ./fly -t advisor-demo trigger-job -j rewrite-spawner/discover-and-spawn
}

rewrite_application() {
    displayMessage "Spring Application Advisor"
    advisor build-config get
    advisor upgrade-plan get
    advisor upgrade-plan apply
}

displayMessage() {
    echo "#### $1"
    echo
}

# Main execution flow

main() {
    check_dependencies
    vendir sync
    source ./vendir/demo-magic/demo-magic.sh
    export TYPE_SPEED=100
    export DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
    export PROMPT_TIMEOUT=5

    init
    install_concourse
    install_fly
}

main
