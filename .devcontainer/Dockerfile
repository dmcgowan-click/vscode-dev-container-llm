#Use Ubuntu as a Base
FROM ubuntu:24.04

#Use this user for all tasks
ARG DEV_USER="ubuntu"

#This allows user to perform a manual build within the .devcontainer folder, and for dev container plugin + .cicd to perform a build from the repos home directory
#Both the dev container plugin and .cicd need to set the DEV_CONTAINER_PATHto .devcontainer
ARG DEV_CONTAINER_PATH=""

#Update and install pre-requisite binaries 
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y sudo nano curl git ca-certificates build-essential python3 jq yq zstd

# Docker Installation Steps
## Add Docker's official GPG key
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to Apt sources
RUN tee /etc/apt/sources.list.d/docker.sources <<EOF > /dev/null
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

## Install Docker packages
RUN apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Gcloud
#IMPORTANT: Public key is not found and packages fail to download UNLESS I add the following "gpg --dearmor". Worked for Hashicorp!
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \ 
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor | tee /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y google-cloud-cli google-cloud-cli-cloud-run-proxy

#Install Ollama for custom model hosting
RUN curl -fsSL https://ollama.com/install.sh | sh

#Configure Docker access for non-root user
RUN groupadd -f docker && usermod -aG docker ${DEV_USER}

# Add non priviledged user but give sudo access
# RUN useradd -m ${DEV_USER} #Keeping for historical reasons, default user of ubuntu is now used
RUN echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${DEV_USER}

#WARNING: All steps below are manadatory for this to work as a dev container ... period. If you miss these steps, you will just get an useless error message

#Set this to the active user
USER ${DEV_USER}

#Prep required mount dirs
RUN mkdir -p \
    /home/${DEV_USER}/.bash_history \
    /home/${DEV_USER}/.local \
    /home/${DEV_USER}/.config/gcloud \
    /home/${DEV_USER}/.ssh \
    /home/${DEV_USER}/.vscode \
    /home/${DEV_USER}/.vscode-server

#Prep required files
RUN touch /home/${DEV_USER}/.gitconfig \
    /home/${DEV_USER}/.bash_history/bash_history

#Ensure bash history is configured
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/home/${DEV_USER}/.bash_history/bash_history" \
    && echo "$SNIPPET" >> "/home/${DEV_USER}/.bashrc"

CMD [ "sleep", "infinity" ]
WORKDIR /home/${DEV_USER}
