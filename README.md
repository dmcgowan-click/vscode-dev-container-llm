# Run LLMs Locally - VS Code Dev Container

A ready-to-use development container optimized for running pre-trained LLM models locally using VS Code and Ollama. This repository provides everything you need to run large language models on your machine without relying on cloud APIs. Ollama is pre-installed and will run automatically when you open the dev container.

Now also includes Pulumi code to create a GCP project with an Artifact Registry, allowing you to build and store container images for use in future projects.

## What This Is

This is a containerized development environment designed for developers who want to:
- Run open-source LLM models (like Qwen, Mistral, Llama) locally on their machine
- Use these models directly within VS Code via the Dev Containers extension
- Develop and test applications that integrate with local LLMs
- Leverage GPU acceleration (NVIDIA recommended)

## Prerequisites

This setup is designed for the following operating systems:

- **Ubuntu (Native)** - Fully supported and tested
- **Ubuntu via WSL2** - Fully supported and tested  
- **macOS** - Not tested (YMMV)

Additional requirements:
- [VS Code](https://code.visualstudio.com/)
- Sufficient disk space (LLM models require 5-40GB depending on the model)

## Quick Start

1. **Install Prerequisites**
   - **Docker** - Use the `prep-docker-nvidia.sh` script (see GPU Setup section below) OR follow the [official Docker installation guide](https://docs.docker.com/get-docker/) OR 
   - [VS Code](https://code.visualstudio.com/)
   - [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Open in Dev Container**
   - Open this folder in VS Code
   - Click the green icon in the bottom-left corner
   - Select "Reopen in Container"

3. **Start Using LLMs**
   - Models are available via Ollama (pre-configured in the container)
   - Query models directly or integrate them into your projects

## Features

- **Pre-configured Ubuntu environment** with all LLM tooling installed
- **Ollama integration** for easy model management and serving
- **OpenCode** for terminal-based coding tasks 
- **GPU acceleration support** (NVIDIA Container Toolkit)
- **Node.js/npm** for JavaScript/TypeScript LLM applications
- **Pulumi infrastructure** for deployment automation *(coming soon)*
- **Cloud CLIs** (GCloud, AWS CLI) pre-installed for cloud workflows
- **Development tools** (git, ssh, docker) pre-configured

## GPU Setup (Optional but Recommended)

For significantly faster LLM inference (and easy installation of docker), simply run the environment prep script:

```bash
bash prep-docker-nvidia.sh
```

This script handles everything you need:
- Installs Docker Engine and Docker Compose
- Installs NVIDIA drivers and utilities
- Installs and configures the NVIDIA Container Toolkit
- Sets up Docker runtime to use NVIDIA GPU support

**Note:** This script is the recommended way to set up your environment. It will prepare your Linux system (WSL2 or native) for local LLM development with GPU acceleration. No additional manual Docker or NVIDIA setup is required.

## Infrastructure (Pulumi)

The `pulumi/` directory contains IaC that provisions a GCP project with an Artifact Registry for storing container images. Once deployed, you can build the dev container image and push it to the registry for reuse across future projects.

### What It Creates

- A GCP folder and project (e.g. `cicd-XXXX`)
- An Artifact Registry Docker repository (`devtools`)
- A Cloud Storage bucket for Pulumi state backups (versioned)

### Setup

1. **Authenticate with GCP**

   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Login to Pulumi (local backend)**

   ```bash
   make login_local
   ```

   Or to use a GCS backend:

   ```bash
   PULUMI_GCP_BUCKET=your-bucket make login_gcp
   ```

3. **Configure the stack**

   Edit `pulumi/Pulumi.org.yaml` to set your GCP org ID, billing account, and region.

4. **Preview and deploy**

   ```bash
   make preview
   make up
   ```

5. **Build and push the dev container image**

   ```bash
   make build_push
   ```

   This builds the dev container image and pushes it to the Artifact Registry created by Pulumi. The image is tagged `latest` on the `main` branch, or with the branch name otherwise.

6. **Backup Pulumi state**

   ```bash
   make state_backup
   ```

   Copies the Pulumi state file to the GCS bucket created by the stack.

## Project Structure

```
.devcontainer/     # Dev container configuration
pulumi/            # Infrastructure as code (GCP project, Artifact Registry, state bucket)
  modules/         # Reusable Pulumi components
  index.ts         # Main stack definition
  Pulumi.yaml      # Pulumi project config
  Pulumi.org.yaml  # Stack-specific config (GCP org, billing, region)
Makefile           # Build, deploy, and image push commands
README.md          # This file
```

## Next Steps

- Explore available LLM models on [Ollama's library](https://ollama.ai)
- Check container logs: View output from Ollama service in VS Code terminal
- Build your LLM application within the dev container

## Troubleshooting

- **Models not loading?** Ensure sufficient disk space (models can be 5-40GB)
- **Slow inference?** GPU acceleration recommended for better performance
- **Container won't start?** Check Docker daemon is running and has sufficient resources