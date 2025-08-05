# Scalr Serverless Agent Pool Infrastructure

This Terraform configuration deploys a complete serverless infrastructure for running Scalr agent pools on AWS, featuring:

- **Secure API Gateway** with Scalr.io IP restrictions
- **Lambda function** for triggering ECS tasks
- **ECS Fargate tasks** with persistent EFS storage for Terraform cache
- **VPC networking** with proper security groups
- **EFS storage** for Terraform provider and module caching

## Architecture

```
Scalr.io Webhook → API Gateway → Lambda → ECS Fargate (with EFS cache)
```

## Features

- ✅ **IP-based security**: Only allows traffic from official Scalr.io IP addresses
- ✅ **API key authentication**: Additional security layer for webhook endpoint
- ✅ **Persistent caching**: EFS storage for Terraform providers and modules
- ✅ **Configurable timeouts**: Lambda and ECS task timeout controls
- ✅ **Auto-scaling**: ECS tasks scale based on webhook triggers
- ✅ **Official IP source**: Automatically fetches Scalr IP allowlist from `scalr.io/.well-known/allowlist.txt`

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Scalr account and API access

## Quick Start

1. **Clone and configure**:
   ```bash
   git clone https://github.com/Scalr/terraform-scalr-aws-serverless
   cd terraform-scalr-aws-serverless
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit variables**:
   ```hcl
   # terraform.tfvars
   aws_region = "us-east-1"
   allow_all_ingress = false  # Enable Scalr IP restrictions
   
   # Customize other variables as needed
   ecs_limit_cpu    = 2048
   ecs_limit_memory = 4096
   ```

3. **Deploy infrastructure**:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

4. **Get webhook URL and API key**:
   ```bash
   tofu output webhook_url
   tofu output api_key
   ```

5. **Configure in Scalr**:
   - Add the webhook URL to your Scalr environment
   - Use the API key for authentication
   - Test the webhook functionality

## Security Configuration

### IP Restrictions

The system automatically uses official Scalr.io IP addresses from their public allowlist:
- **Source**: `https://scalr.io/.well-known/allowlist.txt`
- **Applied to**: API Gateway resource policy
- **Control**: Set `allow_all_ingress = false` to enable restrictions

### Authentication

- **API Key**: Required for all webhook requests
- **IP Filtering**: Only Scalr.io IPs can reach the endpoint
- **VPC Security**: ECS tasks run in isolated VPC subnets

## Persistent Storage

EFS provides persistent caching for:
- **Terraform providers** (`/providers-cache`)
- **Terraform modules** (`/terraform-cache`)

Environment variables automatically configured:
- `TF_PLUGIN_CACHE_DIR=/terraform-cache`
- `TF_DATA_DIR=/providers-cache`

## Configuration Variables

### Core Settings
| Variable            | Description                               | Default       |
|---------------------|-------------------------------------------|---------------|
| `aws_region`        | AWS region for deployment                 | `us-east-1`   |
| `allow_all_ingress` | Disable IP restrictions (not recommended) | `false`       |
| `vpc_name`          | VPC name prefix                           | `scalr-agent` |

### ECS Settings
| Variable                | Description               | Default                     |
|-------------------------|---------------------------|-----------------------------|
| `ecs_limit_cpu`         | ECS task CPU units        | `2048`                      |
| `ecs_limit_memory`      | ECS task memory (MB)      | `4096`                      |
| `ecs_image`             | Container image           | `scalr/agent-runner:latest` |
| `ecs_task_stop_timeout` | Graceful shutdown timeout | `120`                       |

### Lambda Settings
| Variable             | Description              | Default      |
|----------------------|--------------------------|--------------|
| `lambda_timeout`     | Lambda timeout (seconds) | `30`         |
| `lambda_memory_size` | Lambda memory (MB)       | `128`        |
| `lambda_runtime`     | Python runtime version   | `python3.11` |

## Outputs

| Output          | Description                    |
|-----------------|--------------------------------|
| `webhook_url`   | API Gateway webhook endpoint   |
| `api_key`       | Authentication key (sensitive) |
| `agent_pool_id` | Scalr agent pool ID            |
| `agent_token`   | Scalr agent token (sensitive)  |

## Monitoring and Troubleshooting

### Check Security Status
```bash
# View current IP restrictions
tofu output scalr_allowed_ips

# Check API Gateway security
aws logs filter-log-events --log-group-name API-Gateway-Execution-Logs*
```

### Test Webhook
```bash
curl -X POST [webhook_url] \
  -H "x-api-key: [api_key]" \
  -H "Content-Type: application/json" \
  -d '{"test": "webhook"}'
```

### ECS Task Logs
```bash
aws logs filter-log-events --log-group-name /ecs/scalr-agent-pool-cluster
```

## Customization

### Scalr Workspace (Optional)
Uncomment and customize the workspace configuration in `main.tf`:

```hcl
data "scalr_environment" "example" {
  name = "your-environment-name"
}

resource "scalr_workspace" "example" {
  environment_id = data.scalr_environment.example.id
  name           = "your-workspace-name"
  agent_pool_id  = module.agent_pool.agent_pool_id
  # ... other settings
}
```

### Custom Container Image
Build your own image with pre-cached providers:

```dockerfile
FROM scalr/agent-runner:latest
# Add your customizations
COPY providers/ /terraform-cache/
```

## Cost Optimization

- **EFS**: Pay only for storage used
- **Lambda**: Pay per invocation (typically < $1/month)
- **ECS Fargate**: Pay only when tasks are running
- **API Gateway**: Pay per request

Estimated monthly cost for moderate usage: **$5-20**

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

- **Issues**: GitHub Issues
- **Scalr Support**: support@scalr.com
- **AWS Support**: Through your AWS support plan