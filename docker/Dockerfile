FROM ubuntu:latest

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y curl tar zip unzip jq git gh && mkdir -p /root/.m2

# Install GitLab CLI (glab)
RUN curl -fsSL https://gitlab.com/gitlab-org/cli/-/releases/v1.74.0/downloads/glab_1.74.0_linux_amd64.tar.gz | tar -xz -C /usr/local/bin bin/glab

# Install SDKMAN!
RUN curl -s "https://get.sdkman.io?ci=true" | bash

RUN source "/root/.sdkman/bin/sdkman-init.sh" && sdk install java 21.0.8-librca && sdk default java 21.0.8-librca && sdk use java 21.0.8-librca

ADD settings.xml /root/.m2/

CMD ["/bin/bash"]