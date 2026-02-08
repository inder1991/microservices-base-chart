# Microservices Base Helm Chart

A comprehensive, production-ready Helm library chart for deploying microservices on Kubernetes with integrated Datadog observability.

## Overview

This base chart provides:
- **Standard Kubernetes Resources**: Deployment, Service, HPA, Ingress, PDB, NetworkPolicy
- **Datadog Integration**: Unified service tagging, APM, logs, metrics, and monitors
- **Security**: Pod security contexts, network policies, RBAC
- **High Availability**: Pod disruption budgets, anti-affinity, topology spread
- **Observability**: ServiceMonitor for Prometheus, Datadog monitors for errors, latency, throughput
- **Flexibility**: Extensive configuration options with sensible defaults

## Architecture

```
Application Chart (e.g., payment-service)
    │
    ├── Depends on: microservices-base (library chart)
    │   └── Provides templates for:
    │       ├── Deployment (with Datadog annotations)
    │       ├── Service
    │       ├── HPA
    │       ├── Ingress
    │       ├── ServiceAccount
    │       ├── ConfigMap
    │       ├── Secret
    │       ├── PodDisruptionBudget
    │       ├── NetworkPolicy
    │       ├── ServiceMonitor
    │       └── DatadogMonitor CRDs
    │           ├── Error Rate Monitor
    │           ├── Latency Monitor (p99)
    │           ├── Throughput Anomaly Detection
    │           ├── Memory Forecast
    │           └── CPU Sustained Usage
    │
    └── Provides: Service-specific values
```

## Quick Start

### 1. Add Base Chart as Dependency

Create your application chart:

```yaml
# Chart.yaml
apiVersion: v2
name: my-service
version: 1.0.0
dependencies:
  - name: microservices-base
    version: "1.0.0"
    repository: "https://charts.your-company.com"
```

### 2. Configure Service Values

```yaml
# values.yaml
microservices-base:
  global:
    environment: "prod"
    team: "platform-engineering"
    
  service:
    name: "my-service"
    port: 8080
  
  image:
    repository: "your-registry/my-service"
    tag: "1.0.0"
  
  datadog:
    monitors:
      enabled: true
    notifications:
      slackChannel: "#prod-alerts"
```

### 3. Deploy

```bash
# Update dependencies
helm dependency update

# Deploy to production
helm upgrade --install my-service . \
  --namespace production \
  --values values.yaml
```

## Features

### 1. Unified Service Tagging

Automatically configures Datadog unified service tagging for correlation across metrics, traces, and logs:

```yaml
tags.datadoghq.com/env: prod
tags.datadoghq.com/service: my-service
tags.datadoghq.com/version: 1.0.0
```

### 2. APM Auto-Instrumentation

Enables Datadog APM with environment variables:

```yaml
DD_ENV: prod
DD_SERVICE: my-service
DD_VERSION: 1.0.0
DD_AGENT_HOST: <node-ip>
DD_LOGS_INJECTION: true
```

### 3. Intelligent Monitoring

Creates DatadogMonitor CRDs with:
- **Error Rate**: Fires when error percentage exceeds thresholds
- **Latency**: Monitors p99 latency with configurable thresholds
- **Throughput Anomaly**: AI-powered detection with seasonality
- **Resource Forecasting**: Predicts memory/CPU exhaustion
- **Environment-Aware**: Different thresholds for prod/staging/test

### 4. Production-Grade Deployments

- Rolling updates with configurable surge/unavailable
- Pod anti-affinity for high availability
- Topology spread across availability zones
- Pod disruption budgets
- Resource requests and limits
- Health checks (liveness, readiness, startup)

### 5. Security Hardening

- Non-root containers
- Read-only root filesystem
- Dropped capabilities
- Network policies (ingress/egress)
- Service account with minimal permissions

## Configuration

### Global Configuration

```yaml
microservices-base:
  global:
    clusterName: "eks-prod-cluster"      # Kubernetes cluster name
    environment: "prod"                   # prod, staging, test, dev
    team: "platform-engineering"          # Team ownership
    businessUnit: "payments"              # Business unit
    
    datadog:
      enabled: true
      site: "datadoghq.com"
      apm:
        enabled: true
      logs:
        enabled: true
```

### Service Configuration

```yaml
microservices-base:
  service:
    name: "my-service"          # REQUIRED
    type: ClusterIP              # ClusterIP, NodePort, LoadBalancer
    port: 8080
    targetPort: 8080
    protocol: TCP
    
    # Additional ports
    additionalPorts:
    - name: metrics
      port: 9090
      targetPort: 9090
```

### Deployment Configuration

```yaml
microservices-base:
  deployment:
    replicaCount: 2
    
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 1
        maxUnavailable: 0
    
    # Affinity for HA
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - my-service
            topologyKey: kubernetes.io/hostname
```

### Image Configuration

```yaml
microservices-base:
  image:
    repository: "your-registry.azurecr.io/my-service"
    pullPolicy: IfNotPresent
    tag: "1.0.0"
  
  imagePullSecrets:
  - name: registry-secret
```

### Resource Management

```yaml
microservices-base:
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 200m
      memory: 256Mi
  
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

### Health Checks

```yaml
microservices-base:
  livenessProbe:
    enabled: true
    httpGet:
      path: /health
      port: http
    initialDelaySeconds: 30
    periodSeconds: 10
  
  readinessProbe:
    enabled: true
    httpGet:
      path: /health
      port: http
    initialDelaySeconds: 10
    periodSeconds: 5
  
  startupProbe:
    enabled: true
    httpGet:
      path: /health
      port: http
    failureThreshold: 30  # 5 minutes
```

### Environment Variables

```yaml
microservices-base:
  env:
    SPRING_PROFILES_ACTIVE: "prod"
    LOG_LEVEL: "INFO"
    CUSTOM_VAR: "value"
```

### ConfigMaps & Secrets

```yaml
microservices-base:
  configMaps:
    app-config:
      data:
        application.yaml: |
          server:
            port: 8080
  
  # In production, use external-secrets-operator
  secrets:
    app-secrets:
      type: Opaque
      stringData:
        api-key: "xxx"
```

### Datadog Monitoring

```yaml
microservices-base:
  datadog:
    monitors:
      enabled: true
      
      errorRate:
        enabled: true
        threshold:
          critical: 5.0
          warning: 2.0
        evaluationWindow: "5m"
        minRequestVolume: 100
      
      latency:
        enabled: true
        percentile: "p99"
        threshold:
          critical: 500
          warning: 300
      
      throughput:
        enabled: true
        anomalyDetection: true
        deviationThreshold: 3.0
        seasonality: "weekly"
      
      businessMetric:
        enabled: false
        metricName: "custom.success_rate"
        threshold:
          critical: 90.0
      
      memory:
        enabled: true
        threshold:
          critical: 90
          warning: 80
        forecast: true
      
      cpu:
        enabled: true
        threshold:
          critical: 85
          warning: 70
    
    notifications:
      slackChannel: "#prod-alerts"
      pagerdutyServiceKey: "PD_SERVICE_KEY"
      renotifyInterval: 60
```

### Network Policy

```yaml
microservices-base:
  networkPolicy:
    enabled: true
    policyTypes:
      - Ingress
      - Egress
    
    ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
        ports:
        - protocol: TCP
          port: 8080
    
    egress:
      - to:
        - namespaceSelector: {}
        ports:
        - protocol: TCP
          port: 443  # HTTPS
```

### Ingress

```yaml
microservices-base:
  ingress:
    enabled: true
    className: "nginx"
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    
    hosts:
      - host: my-service.example.com
        paths:
          - path: /
            pathType: Prefix
    
    tls:
      - secretName: my-service-tls
        hosts:
          - my-service.example.com
```

## Examples

See `examples/` directory for complete working examples:

- `examples/payment-service/` - Full production configuration
- `examples/user-service/` - Basic service configuration
- `examples/frontend/` - Service with Ingress

## Datadog Monitor Alert Severity

Monitors automatically set priorities based on environment:

| Environment | Error Rate | Latency | Throughput | Memory | CPU |
|-------------|------------|---------|------------|--------|-----|
| Production  | P1         | P2      | P2         | P2     | P2  |
| Staging     | P2         | P3      | P3         | P3     | P3  |
| Test        | P3         | P3      | P3         | P3     | P3  |

## Best Practices

### 1. Use Dependency Management

```bash
# Update base chart version
helm dependency update

# Verify dependencies
helm dependency list
```

### 2. Environment-Specific Values

```
my-service/
├── Chart.yaml
├── values.yaml           # Default values
├── values-prod.yaml      # Production overrides
├── values-staging.yaml   # Staging overrides
└── values-test.yaml      # Test overrides
```

Deploy:
```bash
helm upgrade --install my-service . \
  -f values.yaml \
  -f values-prod.yaml
```

### 3. Use CI/CD for Image Tags

```yaml
# values.yaml - don't hardcode
image:
  tag: ""  # Set in CI/CD

# In CI/CD pipeline
helm upgrade my-service . \
  --set microservices-base.image.tag=${CI_COMMIT_SHA}
```

### 4. External Secrets

Use [external-secrets-operator](https://external-secrets.io/) instead of inline secrets:

```yaml
# Don't do this in production
secrets:
  app-secrets:
    stringData:
      password: "hardcoded"  # BAD

# Do this instead
# Create ExternalSecret resource separately
```

### 5. Monitor Health

```bash
# Check deployment
kubectl get deployment -l app=my-service

# Check monitors
kubectl get datadogmonitor -l service=my-service

# Check monitor status
kubectl get datadogmonitor my-service-error-rate-prod -o yaml
```

## Troubleshooting

### Monitors Not Created

```bash
# Check if Datadog Operator is installed
kubectl get pods -n datadog

# Check CRD status
kubectl get datadogmonitor my-service-error-rate-prod -o yaml

# Check operator logs
kubectl logs -n datadog deployment/datadog-operator
```

### Deployment Failed

```bash
# Check pod status
kubectl get pods -l app=my-service

# Check pod logs
kubectl logs -l app=my-service

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Health Checks Failing

```bash
# Test health endpoint
kubectl port-forward deployment/my-service 8080:8080
curl http://localhost:8080/health

# Check probe configuration
kubectl describe pod <pod-name>
```

## Integration with Existing Repos

To migrate your existing services to use this base chart:

1. **Backup existing chart**:
   ```bash
   cp -r helm helm.backup
   ```

2. **Update Chart.yaml**:
   ```yaml
   dependencies:
     - name: microservices-base
       version: "1.0.0"
       repository: "file://../../microservices-base-chart"
   ```

3. **Migrate values.yaml**:
   ```yaml
   # Old
   replicaCount: 2
   image:
     repository: my-image
   
   # New
   microservices-base:
     deployment:
       replicaCount: 2
     image:
       repository: my-image
   ```

4. **Remove old templates**:
   ```bash
   rm -rf helm/templates/*
   ```

5. **Test**:
   ```bash
   helm dependency update
   helm template . --debug
   helm install my-service . --dry-run
   ```

## Contributing

1. Make changes in base chart
2. Update version in Chart.yaml
3. Update application dependencies
4. Test with example applications

## Support

For issues or questions:
- Create GitHub issue
- Contact Platform Engineering team
- Check documentation: docs/

## License

Internal use only - Emirates NBD Platform Engineering
# microservices-base-chart
