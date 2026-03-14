#Use Ubuntu as a Base
FROM ubuntu:24.04

#Use this user for all tasks
ARG DEV_USER="ubuntu"

#This allows user to perform a manual build within the .devcontainer folder, and for dev container plugin + .cicd to perform a build from the repos home directory
#Both the dev container plugin and .cicd need to set the DEV_CONTAINER_PATHto .devcontainer
ARG DEV_CONTAINER_PATH=""

#Nvidia Container Toolkit Version Argument - Update this as needed to ensure you have the latest version, or to pin to a specific version for stability. Check https://nvidia.github.io/libnvidia-container/ for the latest versions.
ARG export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.2-1

#Update and install pre-requisite binaries 
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y sudo nano curl git ca-certificates build-essential python3 python3-pip jq yq zstd gnupg2 nvidia-utils-590

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

# NVIDIA Container Toolkit Installation Steps
## Add the package repositories
RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

## Install the NVIDIA Container Toolkit packages
RUN apt-get update
RUN apt-get install -y \
    nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

## Configure the NVIDIA Container Toolkit to use the Docker runtime
RUN nvidia-ctk runtime configure --runtime=docker

# Install Gcloud
#IMPORTANT: Public key is not found and packages fail to download UNLESS I add the following "gpg --dearmor". Worked for Hashicorp!
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \ 
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor | tee /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y google-cloud-cli google-cloud-cli-cloud-run-proxy

#Install Ollama for custom model hosting
RUN curl -fsSL https://ollama.com/install.sh | sh

#Install and Configure Supervisor to manage ollama as a dameon
##FUTURE ENHANCEMENTs: 
## * Run under dedicated user
## * Configure port (default is 11434)
RUN mkdir -p /var/log/supervisor \
    && chgrp -R ${DEV_USER} /var/log/supervisor \
    && chmod -R g+rw /var/log/supervisor \
    && pip install supervisor --break-system-packages \
    && echo_supervisord_conf > /etc/supervisord.conf \
    && cat <<EOF >> /etc/supervisord.conf
[program:ollama]
command=/usr/local/bin/ollama serve
directory=/home/ubuntu/.ollama
user=ubuntu
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/ollama.err.log
stdout_logfile=/var/log/supervisor/ollama.out.log
environment=OLLAMA_MAX_LOADED_MODELS="2",OLLAMA_NUM_GPU=1,HOME=/home/ubuntu/
EOF

    # RUN <<EOF > /hello.txt
    # This is line 1.
    # This is line 2.
    # This is line 3.
    # EOF
    # CMD cat /hello.txt
#Configure Docker access for non-root user
RUN groupadd -f docker && usermod -aG docker ${DEV_USER}

# Add non priviledged user but give sudo access
# RUN useradd -m ${DEV_USER} #Keeping for historical reasons, default user of ubuntu is now used
RUN echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${DEV_USER}

#Set this to the active user
USER ${DEV_USER}

#Install Opencode AI for custom model interaction (I think?! I'm new to this!)
#Must be installed under the non priviledged developer user
RUN curl -fsSL https://opencode.ai/install | bash

#WARNING: All steps below are manadatory for this to work as a dev container ... period. If you miss these steps, you will just get an useless error message
#         Ensure all steps run as the non priviledged developer user.

#Prep required mount dirs. There will be corresponding configs to map these to volumes in the devcontainer.json
RUN mkdir -p \
    /home/${DEV_USER}/.bash_history \
    /home/${DEV_USER}/.local \
    /home/${DEV_USER}/.config/gcloud \
    /home/${DEV_USER}/.ssh \
    /home/${DEV_USER}/.vscode \
    /home/${DEV_USER}/.vscode-server \
    /home/${DEV_USER}/.ollama

#Prep required files
RUN touch /home/${DEV_USER}/.gitconfig \
    /home/${DEV_USER}/.bash_history/bash_history

#Ensure bash history is configured
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/home/${DEV_USER}/.bash_history/bash_history" \
    && echo "$SNIPPET" >> "/home/${DEV_USER}/.bashrc"

# #Create and execute startup script to launch supervisor and keep the container alive
# RUN cat <<EOF > /home/${DEV_USER}/startup.sh
# #!/bin/bash
# # Start Supervisor in the background
# sudo supervisord -c /etc/supervisord.conf

# # Keep the container running
# sleep infinity
# EOF
# RUN chmod u+x /home/${DEV_USER}/startup.sh

# CMD ["/home/${DEV_USER}/startup.sh"]
CMD ["sleep","infinity"]
WORKDIR /home/${DEV_USER}
