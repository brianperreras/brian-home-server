# 09 - Network and Security

## Local network

- Use wired 2.5 GbE.
- Reserve the server IP in the router.
- Use a meaningful hostname.
- Keep Unraid management on the trusted LAN.

## Remote access

Use [Tailscale](https://tailscale.com/download) for initial remote access to:

- Unraid web UI.
- Immich.
- Home Assistant.
- SSH, when needed.

Install docs: https://tailscale.com/kb/1017/install  
Unraid notes: https://tailscale.com/kb/1134/unraid

Avoid router port forwarding until you deliberately deploy a reverse proxy, TLS certificates, authentication controls, logging, and an update process.

## Accounts

- Root is for Unraid administration only.
- Create named SMB users.
- Use unique passwords stored in a password manager.
- Enable MFA in applications that support it.

## SSH

- Disable password SSH and use keys if you enable SSH remotely.
- Restrict SSH to LAN/Tailscale.
- Do not publish port 22 to the internet.

## Secrets

Keep these outside Git:

- `.env`
- database passwords
- API tokens
- Tailscale keys
- Home Assistant `secrets.yaml`
- backup encryption passwords

## Updates

Maintain a simple monthly maintenance window. Critical security fixes can be applied earlier, but still take backups first.
