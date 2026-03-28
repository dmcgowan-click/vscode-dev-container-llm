# devops
Repo with templates to get developers started on containers and AI

## Features

### Dev Container Setup
- Pre-configured Ubuntu development environment with Docker integration
- GitHub MCP server integration for VS Code
- SSH and Git configuration mounts for seamless authentication
- Optimized for containerized development workflows

### VS Code Skills Framework
- **PR Summary Skill** — Automate PR workflows with AI-generated summaries
  - Generate change summaries from active branches
  - Auto-update README.md based on changes
  - Create or update PRs with standardized formatting
  - Integrated GitHub MCP support

## Quick Start

1. **Open in Dev Container** — VS Code will detect `.devcontainer/devcontainer.json` and prompt to reopen in container
2. **Use Skills** — Invoke skills via VS Code command palette or voice commands (e.g., "produce summary")

## Requirements

- Docker
- VS Code with Dev Containers extension
- GitHub authentication (for PR operations)

## Enhancements

- Need to add supervisord

## Observations and Issues

### The following components MUST be setup in the WSL sub-layer

* Docker Engine
  * Technically this can run on the actual windows host system, but keeping in on WSL provides better compatibility
* Nvidia Container Toolkit
  * nvidia-ctk
  * nvidia-smi

Script `prep-docker-nvidia.sh` will automate this

### The following components MUST be setup in the dev container

UPDATE

### The following must be done manually after all other steps

* Ollama service must be started manually via supervisord
  * `sudo supervisord -c /etc/supervisord.conf`
* Model of choice must be started using OpenCodeAI in order for it to be selectable in VSCode Chat Local
  * EXAMPLE: `ollama launch opencode --model qwen3`
  * Reason for this is unknown

### Known Issues

#### Local model selection doesn't work

* Unable to select multiple models.
  * Observations
    * Starting with desired model works as expected
    * Adding a new model does not impact usage of old model
    * Switching to new model is also successful
    * Once you have selected the new model, not possible to switch back to the old model. Regardless if the desired model is started in opencode
  * Possible causes
    * Copilot might be getting thrown a bit due to ollama not starting automatically
      * Fix this first, then continue investigation
  * Workarounds
    * Just stick to a single model you want. Qwen3 seems to be the best all rounder at the moment. Reading of files works, and its within GPU memory, taking load of CPUs

#### Integration between local filesystem and models doesn't work

* Models claim they have everything the need to analyse the local file system, however many models fail to do this
  * Closer inspection reveals the standard Qwen3 model does this successfully. Others fail
  * 