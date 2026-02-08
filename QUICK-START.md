# Quick Start Guide

Get your microservice deployed with Datadog monitoring in 5 minutes!

## Prerequisites

- Kubernetes cluster (1.24+)
- Helm 3.12+
- Datadog account and API keys
- Datadog Operator installed

## Step 1: Create Your Service Chart (2 min)

Create directory structure:
```bash
mkdir -p my-service/helm
cd my-service/helm
```

Create `Chart.yaml`:
```yaml
apiVersion: v2
name: my-service
version: 1.0.0
appVersion: "1.0.0"
dependencies:
  - name: microservices-base
    version: "1.0.0"
    repository: "file://../../../microservices-base-chart"
```

Create `values.yaml`:
```yaml
microservices-base:
  global:
    environment: "test"
    team: "platform-engineering"
  
  service:
    name: "my-service"
    port: 8080
  
  image:
    repository: "your-registry/my-service"
    tag: "latest"
  
  datadog:
    monitors:
      enabled: true
    notifications:
      slackChannel: "#test-alerts"
```

## Step 2: Install Dependencies (1 min)

```bash
helm dependency update
helm dependency list

# Should show microservices-base as dependency
```

## Step 3: Deploy to Kubernetes (2 min)

```bash
# Dry run first
helm install my-service . --dry-run --debug

# Deploy
helm install my-service . \
  --namespace test \
  --create-namespace

# Verify
kubectl get pods -n test
kubectl get datadogmonitor -n test
```

## Step 4: Verify Monitoring (Bonus)

Check Datadog UI:
1. Navigate to APM → Services
2. Find your service: `my-service`
3. Navigate to Monitors → Manage Monitors
4. Search for: `my-service test`

You should see monitors for:
- Error Rate
- Latency (p99)
- Throughput Anomaly
- Memory Forecast
- CPU Usage

## What You Get

✅ Production-ready Deployment with HPA  
✅ Health checks (liveness, readiness, startup)  
✅ Resource limits and requests  
✅ Service and ClusterIP  
✅ Pod Disruption Budget  
✅ Datadog APM integration  
✅ 5 monitoring alerts:
   - Error rate monitor
   - Latency (p99) monitor
   - Throughput anomaly detection
   - Memory forecast
   - CPU sustained usage

## Next Steps

### Add Configuration

```yaml
microservices-base:
  env:
    DATABASE_URL: "postgres://db:5432/mydb"
    LOG_LEVEL: "INFO"
  
  configMaps:
    app-config:
      data:
        application.yaml: |
          server:
            port: 8080
```

### Add Database Dependency

```yaml
microservices-base:
  dependencies:
    postgres:
      enabled: true
      host: "postgres.database.svc.cluster.local"
      port: 5432
      database: "mydb"
      usernameSecret:
        name: db-credentials
        key: username
      passwordSecret:
        name: db-credentials
        key: password
```

### Enable Ingress

```yaml
microservices-base:
  ingress:
    enabled: true
    className: "nginx"
    hosts:
      - host: my-service.example.com
        paths:
          - path: /
            pathType: Prefix
```

### Customize Monitoring

```yaml
microservices-base:
  datadog:
    monitors:
      errorRate:
        threshold:
          critical: 3.0  # Lower threshold
          warning: 1.0
      
      latency:
        threshold:
          critical: 1000  # More lenient for dev
          warning: 500
      
      businessMetric:
        enabled: true
        metricName: "my_service.orders.success"
        threshold:
          critical: 95.0
```

## Troubleshooting

**Pods not starting**:
```bash
kubectl describe pod -n test
kubectl logs -n test -l app=my-service
```

**Monitors not created**:
```bash
# Check Datadog Operator
kubectl get pods -n datadog

# Check monitor CRDs
kubectl get datadogmonitor -n test

# Check specific monitor
kubectl describe datadogmonitor my-service-error-rate-test -n test
```

**Health checks failing**:
```bash
# Port forward and test
kubectl port-forward -n test deployment/my-service 8080:8080
curl http://localhost:8080/health
```

## Full Example

See `examples/payment-service/` for a complete production-ready configuration.

## Resources

- **Full Documentation**: [README.md](README.md)
- **Migration Guide**: [MIGRATION-GUIDE.md](MIGRATION-GUIDE.md)
- **Examples**: `examples/` directory
- **Values Reference**: `values.yaml` (all options documented)

## Support

- Slack: #platform-engineering
- Email: platform-engineering@company.com
- GitHub Issues: Create an issue in the repository
