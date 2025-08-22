FROM ubuntu:latest

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y curl tar zip unzip jq gh

# Install SDKMAN!
RUN curl -s "https://get.sdkman.io?ci=true" | bash

CMD ["/bin/bash"]