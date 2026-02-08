# Base Chart Usage Guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Application Charts                         │
│  (payment-service, user-service, checkout-service, etc.)    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ helm dependency
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Microservices Base Chart (Library)              │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Kubernetes  │  │   Datadog    │  │  Security &  │     │
│  │  Resources   │  │  Monitoring  │  │     HA       │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  Templates:                                                  │
│  • Deployment (with Datadog annotations)                    │
│  • Service                                                   │
│  • HPA                                                       │
│  • Ingress                                                   │
│  • ServiceAccount                                            │
│  • ConfigMap                                                 │
│  • Secret                                                    │
│  • PodDisruptionBudget                                       │
│  • NetworkPolicy                                             │
│  • ServiceMonitor                                            │
│  • DatadogMonitor CRDs (5 monitors per service)             │
└─────────────────────────────────────────────────────────────┘
                     │
                     │ creates
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│                                                              │
│  ┌──────────────────────────────────────────────┐           │
│  │  Standard K8s Resources                       │           │
│  │  • Deployment with APM labels                 │           │
│  │  • Service                                    │           │
│  │  • HPA (auto-scaling)                         │           │
│  │  • PDB (high availability)                    │           │
│  └──────────────────────────────────────────────┘           │
│                                                              │
│  ┌──────────────────────────────────────────────┐           │
│  │  Datadog Monitoring (DatadogMonitor CRDs)    │           │
│  │  ├─ Error Rate Monitor                       │           │
│  │  ├─ Latency Monitor (p99)                    │           │
│  │  ├─ Throughput Anomaly Detection (AI)        │           │
│  │  ├─ Memory Forecast                          │           │
│  │  └─ CPU Sustained Usage                      │           │
│  └──────────────────────────────────────────────┘           │
│                     │                                        │
│                     │ syncs to                               │
│                     ▼                                        │
│            ┌──────────────────┐                             │
│            │ Datadog Platform │                             │
│            │  (SaaS)          │                             │
│            └──────────────────┘                             │
└─────────────────────────────────────────────────────────────┘
```

## How It Works

### 1. Library Chart Pattern

The base chart uses Helm's "library chart" pattern:

- **Library Chart**: Contains templates but no values
- **Application Chart**: Depends on library, provides values
- **Result**: Standardized deployments with service-specific configuration

### 2. Template Rendering

When you deploy an application chart:

```bash
helm install payment-service ./payment-service
```

Helm does the following:

1. Reads `Chart.yaml` and finds `microservices-base` dependency
2. Loads templates from `microservices-base`
3. Merges values from both charts (application values override base defaults)
4. Renders templates with merged values
5. Deploys to Kubernetes

### 3. Value Overriding

```yaml
# microservices-base/values.yaml (defaults)
deployment:
  replicaCount: 2
  
# payment-service/values.yaml (override)
microservices-base:
  deployment:
    replicaCount: 5  # Overrides default
```

## Directory Structure

### Base Chart (this repository)

```
microservices-base-chart/
├── Chart.yaml                    # Chart metadata
├── values.yaml                   # Default values (documentation)
├── README.md                     # Complete documentation
├── QUICK-START.md               # 5-minute getting started
├── MIGRATION-GUIDE.md           # Migrate existing services
│
├── templates/                    # Kubernetes resource templates
│   ├── _helpers.tpl             # Template functions
│   ├── deployment.yaml          # Deployment with APM
│   ├── service.yaml             # Service
│   ├── hpa.yaml                 # HorizontalPodAutoscaler
│   ├── ingress.yaml             # Ingress
│   ├── serviceaccount.yaml      # ServiceAccount
│   ├── configmap.yaml           # ConfigMaps
│   ├── secret.yaml              # Secrets
│   ├── poddisruptionbudget.yaml # PDB for HA
│   ├── networkpolicy.yaml       # Network security
│   ├── servicemonitor.yaml      # Prometheus metrics
│   │
│   └── datadog/                 # Datadog monitoring templates
│       ├── monitor-error-rate.yaml
│       ├── monitor-latency.yaml
│       ├── monitor-throughput.yaml
│       ├── monitor-memory.yaml
│       └── monitor-cpu.yaml
│
└── examples/                     # Example application charts
    ├── payment-service/
    ├── user-service/
    └── checkout-frontend/
```

### Application Chart (your service)

```
payment-service/
├── Chart.yaml                    # Declares dependency on base chart
├── values.yaml                   # Service-specific configuration
├── values-prod.yaml             # Production overrides
├── values-staging.yaml          # Staging overrides
└── values-test.yaml             # Test overrides
```

## Workflow Examples

### Example 1: Deploy New Service

```bash
# 1. Create service directory
mkdir -p my-new-service/helm
cd my-new-service/helm

# 2. Create Chart.yaml
cat > Chart.yaml << 'EOF'
apiVersion: v2
name: my-new-service
version: 1.0.0
dependencies:
  - name: microservices-base
    version: "1.0.0"
    repository: "https://charts.company.com"
EOF

# 3. Create values.yaml
cat > values.yaml << 'EOF'
microservices-base:
  global:
    environment: "prod"
    team: "my-team"
  
  service:
    name: "my-new-service"
    port: 8080
  
  image:
    repository: "registry/my-new-service"
    tag: "1.0.0"
  
  datadog:
    monitors:
      enabled: true
    notifications:
      slackChannel: "#prod-alerts"
EOF

# 4. Update dependencies
helm dependency update

# 5. Deploy
helm install my-new-service . --namespace prod
```

### Example 2: Update Monitoring Thresholds

```bash
# Edit values.yaml
cat >> values.yaml << 'EOF'
microservices-base:
  datadog:
    monitors:
      errorRate:
        threshold:
          critical: 3.0  # Changed from 5.0
          warning: 1.5   # Changed from 2.0
EOF

# Apply changes
helm upgrade my-service . --namespace prod
```

### Example 3: Add Database Dependency

```bash
# Update values.yaml
cat >> values.yaml << 'EOF'
microservices-base:
  dependencies:
    postgres:
      enabled: true
      host: "my-db.postgres.svc.cluster.local"
      port: 5432
      database: "mydb"
      usernameSecret:
        name: db-creds
        key: username
      passwordSecret:
        name: db-creds
        key: password
EOF

# This automatically sets environment variables:
# POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB, 
# POSTGRES_USER, POSTGRES_PASSWORD

# Apply changes
helm upgrade my-service . --namespace prod
```

### Example 4: Enable Ingress

```bash
cat >> values.yaml << 'EOF'
microservices-base:
  ingress:
    enabled: true
    className: "nginx"
    hosts:
      - host: my-service.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: my-service-tls
        hosts:
          - my-service.example.com
EOF

helm upgrade my-service . --namespace prod
```

### Example 5: CI/CD Integration

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to Production
        run: |
          cd helm
          helm dependency update
          helm upgrade --install my-service . \
            --namespace prod \
            --set microservices-base.image.tag=${{ github.sha }} \
            --values values.yaml \
            --values values-prod.yaml
```

## Value Resolution

Values are merged in this order (later overrides earlier):

1. Base chart defaults (`microservices-base-chart/values.yaml`)
2. Application chart values (`my-service/values.yaml`)
3. Environment-specific values (`my-service/values-prod.yaml`)
4. Command-line `--set` flags

Example:

```bash
# Base default
replicaCount: 2

# Application values
microservices-base:
  deployment:
    replicaCount: 3

# Production values
microservices-base:
  deployment:
    replicaCount: 5

# Command line
--set microservices-base.deployment.replicaCount=10

# Result: 10 replicas
```

## Datadog Integration

### Automatic APM Configuration

The base chart automatically configures:

**Pod Labels**:
```yaml
tags.datadoghq.com/env: prod
tags.datadoghq.com/service: my-service
tags.datadoghq.com/version: 1.0.0
```

**Pod Annotations**:
```yaml
ad.datadoghq.com/my-service.logs: '[{"source":"my-service","service":"my-service"}]'
```

**Environment Variables**:
```yaml
DD_ENV: prod
DD_SERVICE: my-service
DD_VERSION: 1.0.0
DD_AGENT_HOST: <node-ip>
DD_LOGS_INJECTION: true
```

### Monitor Creation

For each service, creates 5 monitors:

1. **Error Rate**: Fires when errors exceed threshold
2. **Latency (p99)**: Tracks response time degradation
3. **Throughput Anomaly**: AI-powered traffic anomaly detection
4. **Memory Forecast**: Predicts memory exhaustion
5. **CPU Sustained**: Detects sustained high CPU usage

Monitors are environment-aware:

| Monitor     | Prod Threshold | Staging Threshold | Test Threshold |
|-------------|----------------|-------------------|----------------|
| Error Rate  | 5%             | 7%                | 10%            |
| Latency p99 | 500ms          | 700ms             | 1000ms         |
| Memory      | 90%            | 92%               | 95%            |
| CPU         | 85%            | 87%               | 90%            |

## Best Practices

### 1. Version Pinning

Always pin base chart version:

```yaml
# Chart.yaml
dependencies:
  - name: microservices-base
    version: "1.0.0"  # Exact version, not "~1.0.0"
```

### 2. Environment-Specific Files

Use separate values files:

```
values.yaml         # Common across all environments
values-prod.yaml    # Production-specific
values-staging.yaml # Staging-specific
values-test.yaml    # Test-specific
```

Deploy:
```bash
helm upgrade my-service . \
  -f values.yaml \
  -f values-prod.yaml
```

### 3. Secret Management

Use External Secrets Operator:

```yaml
# Don't do this
microservices-base:
  secrets:
    app-secrets:
      stringData:
        password: "hardcoded"  # BAD

# Do this instead
# Create ExternalSecret resource separately
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  secretStoreRef:
    name: vault
  data:
    - secretKey: password
      remoteRef:
        key: app/password
```

### 4. Resource Sizing

Start conservative, scale up:

```yaml
# Initial deployment
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

# After load testing
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### 5. Gradual Rollouts

Use HPA behavior for safe scaling:

```yaml
autoscaling:
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min
      policies:
      - type: Percent
        value: 50  # Max 50% reduction
        periodSeconds: 60
    
    scaleUp:
      stabilizationWindowSeconds: 60   # Quick scale up
      policies:
      - type: Percent
        value: 100  # Double capacity if needed
        periodSeconds: 30
```

## Troubleshooting

### Common Issues

**1. Values Not Applied**

Problem: Changes to values.yaml not reflected

Solution: Check nesting
```yaml
# WRONG
service:
  port: 8080

# RIGHT
microservices-base:
  service:
    port: 8080
```

**2. Monitors Not Created**

Problem: DatadogMonitor CRDs not appearing

Solutions:
```bash
# Check Datadog Operator
kubectl get pods -n datadog

# Verify monitors enabled
microservices-base:
  datadog:
    monitors:
      enabled: true

# Check CRD status
kubectl describe datadogmonitor my-service-error-rate-prod
```

**3. Template Errors**

Problem: Helm template fails

Solution:
```bash
# Debug output
helm template . --debug 2>&1 | less

# Validate required values
helm template . --debug | grep -i "required"
```

## Updating Base Chart

When base chart updates are released:

```bash
# 1. Update version in Chart.yaml
vim Chart.yaml
# Change: version: "1.0.0" to version: "1.1.0"

# 2. Update dependencies
helm dependency update

# 3. Review changes
helm dependency list

# 4. Test in non-prod
helm upgrade my-service . \
  --namespace test \
  --dry-run --debug

# 5. Deploy to environments
helm upgrade my-service . --namespace test
# Validate, then:
helm upgrade my-service . --namespace staging
# Validate, then:
helm upgrade my-service . --namespace prod
```

## Support Resources

- **Documentation**: [README.md](README.md)
- **Quick Start**: [QUICK-START.md](QUICK-START.md)
- **Migration**: [MIGRATION-GUIDE.md](MIGRATION-GUIDE.md)
- **Examples**: `examples/` directory
- **Values Reference**: `values.yaml` (fully documented)

## Getting Help

- **Slack**: #platform-engineering
- **Email**: platform-engineering@company.com
- **Office Hours**: Tuesdays 2-4 PM
- **GitHub Issues**: Create issue in repository
