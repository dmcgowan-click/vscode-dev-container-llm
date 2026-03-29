# Security Guidelines

## Protecting Your Credentials

This development container mounts credentials from your local machine into the container environment. When using this container, be aware of the following security best practices:

### SSH Keys
The container mounts your `~/.ssh` directory. Ensure your SSH keys are:
- Protected with strong passphrases
- Set with appropriate file permissions (typically `600` for private keys)
- Never committed to version control

### Git Configuration
Your `~/.gitconfig` is mounted into the container. If you use authentication tokens in git config:
- Use SSH keys instead of HTTPS tokens when possible
- Never hardcode credentials in `.gitconfig`
- Use credential helpers (e.g., `git-credential-cache`) for secure token management

### GCP Credentials
If using Google Cloud Platform, the container mounts `~/.config/gcloud`. Ensure:
- Your GCP service account keys are never committed to this repository
- Use GCP Application Default Credentials when available
- Rotate credentials regularly
- Restrict key permissions to least-privilege access

### Environment Variables
When running the container:
- Do not pass sensitive credentials as command-line arguments or environment variables that get logged
- Use credential files with restricted permissions instead
- Consider using secrets management tools (e.g., HashiCorp Vault, AWS Secrets Manager) for production workflows

### Code and Documentation
When contributing to this repository:
- Never commit credentials, tokens, API keys, or private keys
- Never include real AWS account IDs, GCP project IDs, or other identifying information in examples
- Use placeholders like `YOUR_API_KEY`, `your-project-id`, etc. in documentation
- Review your changes for accidentally committed secrets before submitting pull requests

## Detecting Accidental Commits

If you accidentally commit credentials:
1. Immediately revoke the compromised credentials
2. Use `git filter-branch` or `BFG Repo-Cleaner` to remove from history
3. Force push the cleaned history (use with caution on shared repos)
4. Notify repository maintainers

## Reporting Security Issues

If you discover a security vulnerability in this repository or have questions about secure usage:
- Do not open a public issue
- Contact the maintainers directly with details about the vulnerability
- Allow time for a fix before public disclosure

## References

- [GitHub: Removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [OWASP: Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitGuardian: Git security best practices](https://www.gitguardian.com/blog/git-secrets)
