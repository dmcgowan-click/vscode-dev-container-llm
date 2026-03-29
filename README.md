# Run LLMs Locally - VS Code Dev Container

A ready-to-use development container optimized for running pre-trained LLM models locally using VS Code and Ollama. This repository provides everything you need to run large language models on your machine without relying on cloud APIs. Ollama is pre-installed and will run automatically when you open the dev container.

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

## Project Structure

```
.devcontainer/     # Dev container configuration
pulumi/            # Infrastructure as code (coming soon)
node_modules/      # Dependencies (auto-installed)
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