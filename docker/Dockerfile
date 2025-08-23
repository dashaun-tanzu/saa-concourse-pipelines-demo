FROM ubuntu:latest

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y curl tar zip unzip jq git gh && mkdir -p /root/.m2

# Install SDKMAN!
RUN curl -s "https://get.sdkman.io?ci=true" | bash

ADD settings.xml /root/.m2/

CMD ["/bin/bash"]