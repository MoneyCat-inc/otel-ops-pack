# Local GitLab Remote for C:\rimbots (Docker)

Run GitLab CE locally in Docker and use it as the remote for the `C:\rimbots` repo.
On Windows, prefer Docker Desktop (WSL2 backend) with 8-12 GB RAM allocated.

## 1) Create a local GitLab container (compose)

Create `C:\gitlab-local\docker-compose.yml`:

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab-local
    restart: unless-stopped
    hostname: gitlab.local
    shm_size: "256m"
    ports:
      - "8929:8929"   # HTTP
      - "2224:22"     # SSH
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost:8929'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
        # Optional: reduce resource footprint slightly
        puma['worker_processes'] = 2
        sidekiq['max_concurrency'] = 10
    volumes:
      - gitlab_config:/etc/gitlab
      - gitlab_logs:/var/log/gitlab
      - gitlab_data:/var/opt/gitlab

volumes:
  gitlab_config:
  gitlab_logs:
  gitlab_data:
```

Start the container:

```powershell
cd C:\gitlab-local
docker compose up -d
```

Wait for first boot to finish (can take a few minutes). Then open:

- `http://localhost:8929`

Get the initial root password:

```powershell
docker exec -it gitlab-local cat /etc/gitlab/initial_root_password
```

Log in as `root`, then set a new password.

## 2) Create the rimbots project in GitLab

In the UI:

- New project -> Create blank project
- Name: `rimbots`
- Visibility: Private

## 3) Point C:\rimbots at this local remote

In `C:\rimbots`:

```powershell
cd C:\rimbots
git init
git add .
git commit -m "chore: initial import"
git remote add origin http://localhost:8929/root/rimbots.git
git push -u origin main
```

If you prefer SSH instead of HTTP:

```powershell
git remote set-url origin ssh://git@localhost:2224/root/rimbots.git
```

Add your SSH key in GitLab user settings if you use SSH.

## Optional: add a local GitLab Runner (pipelines)

This needs a runner registration token from your GitLab instance
(Admin area -> Runners).

Quick runner (docker executor):

```powershell
docker run -d --name gitlab-runner --restart unless-stopped `
  -v /var/run/docker.sock:/var/run/docker.sock `
  -v gitlab_runner_config:/etc/gitlab-runner `
  gitlab/gitlab-runner:latest
```

Register it:

```powershell
docker exec -it gitlab-runner gitlab-runner register
```

Use:

- URL: `http://gitlab-local/` (inside Docker network)
- Or: `http://host.docker.internal:8929` (from runner container)
- Token: from GitLab UI
- Executor: `docker`

## About "add this repo to your responsibilities"

This runbook can document steps, but responsibilities do not persist outside a
chat session. If you open `C:\rimbots` as the workspace, follow-up tasks can be
implemented directly, such as:

- a `README.md` describing the local GitLab remote
- a `.gitlab-ci.yml` aligned to BossCat lanes (security / gate / docs)
- templates (MR checklist, decision cards, evidence logging)

If you want that, note whether the `rimbots` codebase is Python, Node, or .NET,
and whether GitLab should build/push Docker images (registry) or just run checks.
