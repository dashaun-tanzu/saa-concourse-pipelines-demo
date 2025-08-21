FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl tar zip unzip jq gh

# Install SDKMAN!
RUN curl -s "https://get.sdkman.io?ci=true" | bash
RUN source "/root/.sdkman/bin/sdkman-init.sh" && sdk install java 21.0.2-graalce && sdk default java 21.0.2-graalce

# Install Advisor CLI
RUN curl -s "https://packages.broadcom.com/artifactory/spring-enterprise/com/vmware/tanzu/spring/application-advisor-cli-linux/1.4.0/application-advisor-cli-linux-1.4.0.tar" -o advisor-cli.tar && \
    tar -xf advisor-cli.tar && \
    mv cli-binary/advisor /usr/local/bin/advisor

RUN chmod +x /usr/local/bin/advisor

# Clean up
RUN rm -rf advisor-cli.tar