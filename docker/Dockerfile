FROM ubuntu:latest

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y curl tar zip unzip jq git gh && mkdir -p /root/.m2

# Install SDKMAN!
RUN curl -s "https://get.sdkman.io?ci=true" | bash

RUN source "/root/.sdkman/bin/sdkman-init.sh" && sdk install java 21.0.6-librca && sdk default java 21.0.6-librca && sdk use java 21.0.6-librca

ADD settings.xml /root/.m2/

CMD ["/bin/bash"]