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
    sed -i '/CONCOURSE_WORKER_RUNTIME: "containerd"/a\      CONCOURSE_ENABLE_ACROSS_STEP: "true"' docker-compose.yml
    sed -i "s|CONCOURSE_EXTERNAL_URL: http://localhost:8080|CONCOURSE_EXTERNAL_URL: $CONCOURSE_EXTERNAL_URL|g" docker-compose.yml
    cat >> docker-compose.yml << 'EOF'

  registry:
    image: registry:2
    ports:
      - "5000:5000"
EOF
    docker compose down
    docker compose up -d
}

shutdown_concourse() {
    docker compose down
}

install_fly() {
  echo "GitHub Token -> $GITHUB_TOKEN"
    until curl 'http://localhost:8080/api/v1/cli?arch=amd64&platform=linux' -o fly; do
        echo "Retrying..."
        sleep 1
    done
    export REGISTRY_IP="$(docker inspect $(docker compose ps -q registry) | grep -i ipaddress | grep -oP '\d+\.\d+\.\d+\.\d+' | tail -1)"
    echo $REGISTRY_IP
    chmod +x ./fly
    ./fly -t advisor-demo login -c http://localhost:8080 -u test -p test -n main
    ./fly -t advisor-demo set-pipeline -n \
            -p advisor-image \
            -c ../pipelines/advisor-image.yml \
            -v maven.username="$MAVEN_USERNAME" \
            -v maven.password="$MAVEN_PASSWORD" \
            -v registry-ip="$REGISTRY_IP"
    ./fly -t advisor-demo unpause-pipeline -p advisor-image
    ./fly -t advisor-demo trigger-job -j advisor-image/cache-binary
    ./fly -t advisor-demo set-pipeline -n \
            -p rewrite-spawner \
            -c ../pipelines/spawner-pipeline.yml \
            -v github_token="$GIT_TOKEN_FOR_PRS" \
            -v github_orgs='["dashaun-demo"]' \
            -v api_base='https://api.github.com'
    ./fly -t advisor-demo unpause-pipeline -p rewrite-spawner

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
