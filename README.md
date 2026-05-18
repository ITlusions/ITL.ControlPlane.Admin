# ITL Control Plane Admin Portal

![Status](https://img.shields.io/badge/status-alpha-orange?style=flat-square)
![Development](https://img.shields.io/badge/development-in%20progress-yellow?style=flat-square)

> **Alpha** — This project is under active development. APIs, data models, and behaviour may change without notice.

Platform administration portal for ITL Control Plane operators.

## Overview

The Admin Portal provides **full infrastructure access** for platform administrators:

- **Docker/Kubernetes Monitoring**: View containers, pods, services, and deployments
- **Container Management**: Start, stop, restart containers directly from the UI
- **Service Health**: Real-time health status of platform services
- **Activity Logs**: Full audit trail of platform activity
- **Resource Management**: Complete access to all resources across all tenants

## Security Notice

This portal should **ONLY** be accessible to platform operators. It has full access to:
- Docker daemon (can control containers)
- Kubernetes API (can view/manage workloads)
- All tenant resources (unrestricted access)

**DO NOT** expose this portal to end customers. Use the **Customer Portal** instead.

## Quick Start

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run the application
uvicorn main:app --host 0.0.0.0 --port 8091 --reload
```

### Docker

```bash
# Build the image
docker build -t itl-admin-portal .

# Run with Docker socket access (required for infrastructure monitoring)
docker run -d \
  -p 8091:8091 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e API_GATEWAY_URL=http://api-gateway:8080 \
  -e KEYCLOAK_ISSUER=https://sts.itlusions.com/realms/itl \
  -e KEYCLOAK_CLIENT_ID=admin-portal \
  -e KEYCLOAK_CLIENT_SECRET=your-secret \
  itl-admin-portal
```

### Kubernetes

When running in Kubernetes, the Admin Portal automatically:
- Detects the K8s environment via `KUBERNETES_SERVICE_HOST`
- Uses the mounted ServiceAccount token for API access
- Shows pods, services, and deployments instead of Docker containers

Ensure the ServiceAccount has appropriate RBAC permissions:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: admin-portal-role
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "namespaces"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch"]
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `8091` |
| `API_GATEWAY_URL` | ITL API Gateway URL | `http://localhost:8081` |
| `KEYCLOAK_ISSUER` | Keycloak realm URL | (required for auth) |
| `KEYCLOAK_CLIENT_ID` | OIDC client ID | (required for auth) |
| `KEYCLOAK_CLIENT_SECRET` | OIDC client secret | (required for auth) |
| `SECRET_KEY` | Session encryption key | `dev-secret-key` |

## Features

### Infrastructure Monitoring

- Real-time Docker/Kubernetes status
- Container health and uptime tracking
- Port mappings and network configuration
- Container logs with auto-refresh

### Platform Management

- All ITL.Core resources (tenants, subscriptions, resource groups)
- Management group hierarchy visualization
- Activity log with scope-based filtering
- Resource dependency graph

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Admin Portal (8091)                   │
│         Full infrastructure + resource access           │
└───────────────┬─────────────────────────────────────────┘
                │
        ┌───────┴───────┐
        │               │
   ┌────▼────┐   ┌──────▼──────┐
   │ Docker  │   │ Kubernetes  │
   │ Daemon  │   │    API      │
   └─────────┘   └─────────────┘
```

## Differences from Customer Portal

| Feature | Admin Portal | Customer Portal |
|---------|--------------|-----------------|
| Docker access | ✅ Yes | ❌ No |
| Kubernetes access | ✅ Yes | ❌ No |
| Container management | ✅ Yes | ❌ No |
| Service health | ✅ Yes | ❌ No |
| All tenant access | ✅ Yes | ❌ Scoped |

## Related Projects

- [ITL.ControlPlane.Portal](../ITL.ControlPlane.Portal) - Customer-facing portal
- [ITL.ControlPlane.Dashboard](../ITL.ControlPlane.Dashboard) - Original combined dashboard
- [ITL.ControlPlane.Api](../ITL.ControlPlane.Api) - API Gateway
