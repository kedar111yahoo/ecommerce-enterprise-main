# Microservice Repositories Setup Guide

Complete step-by-step guide to create and configure all 8 microservice repositories for the ecommerce-enterprise platform.

## Prerequisites
- GitHub account with organization/personal space
- GitHub CLI installed (`gh --version`)
- Git configured locally
- Access to create repositories

## Repository List

| # | Name | Type | Port | Database | Purpose |
|---|------|------|------|----------|---------|
| 1 | `ecommerce-auth-service` | Backend | 8001 | MySQL | Authentication & Authorization |
| 2 | `ecommerce-user-service` | Backend | 8002 | MySQL | User Management |
| 3 | `ecommerce-product-service` | Backend | 8003 | PostgreSQL | Product Catalog |
| 4 | `ecommerce-order-service` | Backend | 8004 | PostgreSQL | Order Processing |
| 5 | `ecommerce-payment-service` | Backend | 8005 | MySQL | Payment Processing |
| 6 | `ecommerce-api-gateway` | Backend | 8080 | None | API Gateway |
| 7 | `ecommerce-frontend` | Frontend | 4200 | None | Angular Web UI |
| 8 | `ecommerce-infrastructure` | DevOps | - | None | K8s, Docker Compose |

## Step 1: Manual Repository Creation (If not using script)

### Via GitHub Web UI:
1. Go to https://github.com/new
2. Fill in repository name: `ecommerce-{service-name}`
3. Description: `{Service} Microservice - Part of ecommerce-enterprise platform`
4. Select: Public (or Private)
5. Initialize with README
6. Add .gitignore: Java
7. Add license: MIT
8. Create repository

### Via GitHub CLI:
```bash
gh repo create ecommerce-auth-service --public --description "Auth Service" --source=. --remote=origin --push
```

## Step 2: Clone All Repositories

```bash
cd ~/projects
mkdir ecommerce-services
cd ecommerce-services

# Clone each repository
git clone https://github.com/kedar111yahoo/ecommerce-auth-service.git
git clone https://github.com/kedar111yahoo/ecommerce-user-service.git
git clone https://github.com/kedar111yahoo/ecommerce-product-service.git
git clone https://github.com/kedar111yahoo/ecommerce-order-service.git
git clone https://github.com/kedar111yahoo/ecommerce-payment-service.git
git clone https://github.com/kedar111yahoo/ecommerce-api-gateway.git
git clone https://github.com/kedar111yahoo/ecommerce-frontend.git
git clone https://github.com/kedar111yahoo/ecommerce-infrastructure.git
```

## Step 3: Initialize Each Backend Microservice

For each backend service (auth, user, product, order, payment, api-gateway):

```bash
cd ecommerce-{service-name}

# Copy pom.xml template
cp ../ecommerce-enterprise-main/microservice-templates/pom.xml .

# Create directory structure
mkdir -p src/main/java/com/ecommerce/{service}
mkdir -p src/main/java/com/ecommerce/{service}/{controller,service,repository,entity,dto,exception,config}
mkdir -p src/main/resources
mkdir -p src/test/java/com/ecommerce/{service}/{controller,service,repository}
mkdir -p src/test/resources
mkdir -p docker
mkdir -p k8s
mkdir -p .github/workflows

# Copy configuration files
cp ../ecommerce-enterprise-main/microservice-templates/application.yml src/main/resources/
cp ../ecommerce-enterprise-main/Dockerfile docker/
cp ../ecommerce-enterprise-main/k8s/*.yaml k8s/

# Copy GitHub Actions workflows
cp ../ecommerce-enterprise-main/.github/workflows/*.yml .github/workflows/

# Update service-specific configurations
# Edit pom.xml - Update <artifactId>, <name>, <description>
# Edit application.yml - Update service name and ports
# Edit docker/Dockerfile - Update service name

# Create .gitignore
cat > .gitignore << 'EOF'
# IDE
.idea/
.vscode/
*.swp
*.swo

# Build
target/
build/
*.jar

# Maven
.m2/
dependency-reduced-pom.xml

# Docker
.DS_Store
node_modules/
dist/

# Environment
.env
.env.local
*.log
EOF

# Make initial commit
git add .
git commit -m "Initial microservice structure setup"
git push origin main
```

## Step 4: Update Service-Specific Configurations

### For Each Service - Update pom.xml

```xml
<groupId>com.ecommerce</groupId>
<artifactId>ecommerce-{service-name}</artifactId>
<name>Ecommerce {Service} Microservice</name>
<description>{Service Description}</description>

<!-- Service-specific dependencies -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<!-- Add MySQL or PostgreSQL driver based on service -->
```

### For Each Service - Update application.yml

```yaml
spring:
  application:
    name: {service-name}
server:
  port: 800X

# Database configuration
spring:
  datasource:
    url: jdbc:mysql://mysql:3306/ecommerce  # or postgresql
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}

# Service discovery
eureka:
  client:
    serviceUrl:
      defaultZone: ${EUREKA_URL}
```

### For Each Service - Update Dockerfile

```dockerfile
# Update service name and port
FROM openjdk:17-jdk-slim as builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src src
RUN mvn clean package -DskipTests

FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=builder /app/target/ecommerce-{service-name}-*.jar app.jar
EXPOSE 800X
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## Step 5: Configure GitHub Actions Workflows

Create `.github/workflows/` for each service:

### build.yml
```yaml
name: Build and Test
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      - run: mvn clean install
      - run: mvn test
      - name: Build Docker image
        run: docker build -f docker/Dockerfile -t kedar111yahoo/ecommerce-{service}:${{ github.sha }} .
```

## Step 6: Create Kubernetes Manifests

For each service, create `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {service-name}
spec:
  replicas: 2
  # ... configuration specific to service
```

## Step 7: Configure Branch Protection Rules

For each repository:

1. Go to Settings → Branches
2. Add rule for `main` branch
3. Enable:
   - Require pull request reviews (2)
   - Require status checks to pass
   - Require branches to be up to date
   - Dismiss stale pull request approvals
   - Require code review from code owners

## Step 8: Set Up GitHub Secrets

For each repository (Settings → Secrets and variables → Actions):

```
DOCKER_USERNAME = kedar111yahoo
DOCKER_PASSWORD = {docker_password}
REGISTRY_URL = docker.io
KUBE_CONFIG = {base64_encoded_kubeconfig}
DB_USERNAME = ecommerce_user
DB_PASSWORD = {secure_password}
```

## Step 9: Configure Team and Permissions

1. Go to organization settings
2. Add team: `ecommerce-developers`
3. Add repositories to team
4. Set permissions:
   - Maintain: For senior developers
   - Write: For regular developers
   - Triage: For QA/testers

## Step 10: Set Up Topics and Descriptions

For each repository, add:

**Topics:**
- `ecommerce-platform`
- `microservice`
- `spring-boot`
- `docker`
- `kubernetes`
- `{service-specific-topic}`

**Description:**
`{Service Name} Microservice - Part of ecommerce-enterprise platform. Handles {responsibilities}.`

## Step 11: Initial Development

### Create development branch:
```bash
cd ecommerce-{service-name}
git checkout -b develop
git push origin develop
```

### Create feature branches:
```bash
git checkout -b feature/initial-setup
# Make changes
git add .
git commit -m "feat: Initial service setup"
git push origin feature/initial-setup
```

### Create pull request:
- Push to GitHub
- Open PR on main branch
- Get required reviews
- Merge to main

## Automated Setup Script

Save as `scripts/create-all-repos.sh`:

```bash
#!/bin/bash

set -e

SERVICES=(
  "auth-service"
  "user-service"
  "product-service"
  "order-service"
  "payment-service"
  "api-gateway"
)

FRONTEND="frontend"
INFRA="infrastructure"

BASE_DIR="~/projects/ecommerce-services"
TEMPLATE_DIR="~/projects/ecommerce-enterprise-main"

mkdir -p $BASE_DIR
cd $BASE_DIR

# Function to setup backend service
setup_backend_service() {
  local service=$1
  local repo_name="ecommerce-$service"
  
  echo "Setting up $repo_name..."
  
  git clone https://github.com/kedar111yahoo/$repo_name.git
  cd $repo_name
  
  # Copy templates
  cp $TEMPLATE_DIR/microservice-templates/pom.xml .
  cp $TEMPLATE_DIR/Dockerfile docker/
  
  # Create structure
  mkdir -p src/main/java/com/ecommerce/${service%%-*}
  mkdir -p src/main/resources
  mkdir -p src/test/java/com/ecommerce/${service%%-*}
  mkdir -p docker k8s .github/workflows
  
  # Add files
  cp $TEMPLATE_DIR/microservice-templates/application.yml src/main/resources/
  cp $TEMPLATE_DIR/.github/workflows/*.yml .github/workflows/
  
  # Update pom.xml
  sed -i "s/{service-name}/$service/g" pom.xml
  
  # Initial commit
  git add .
  git commit -m "Initial setup: $service microservice"
  git push origin main
  
  cd ..
}

# Setup all backend services
for service in "${SERVICES[@]}"; do
  setup_backend_service "$service"
done

echo "All repositories created and initialized!"
echo "Next steps:"
echo "1. Configure GitHub branch protection rules"
echo "2. Set up secrets in each repository"
echo "3. Invite team members"
echo "4. Start development!"
```

## Verification Checklist

- [ ] All 8 repositories created
- [ ] Each repo has README with setup instructions
- [ ] .gitignore configured for each repo
- [ ] GitHub Actions workflows in place
- [ ] Branch protection rules enabled
- [ ] Secrets configured
- [ ] Team members added
- [ ] Topics and descriptions added
- [ ] Initial commits pushed
- [ ] develop branch created for each service

## Common Issues and Solutions

### Issue: "Failed to push to repository"
**Solution:** 
```bash
git remote set-url origin https://github.com/kedar111yahoo/repo.git
git branch -M main
git push -u origin main
```

### Issue: "Permission denied (publickey)"
**Solution:**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub  # Add to GitHub SSH keys
```

### Issue: "Status check pending"
**Solution:** Wait for GitHub Actions to complete, check workflow logs

## Next Steps

1. **Set up CI/CD pipelines** - Ensure all tests pass
2. **Configure code quality** - SonarQube integration
3. **Set up monitoring** - Add to Prometheus
4. **Document APIs** - Swagger/OpenAPI
5. **Plan development** - Create issues and project boards
6. **Schedule team meeting** - Align on standards and workflows
