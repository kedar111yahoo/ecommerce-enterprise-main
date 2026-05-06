<!-- Microservice Repository Template -->
# Microservice Repository Structure

This document outlines the standardized repository structure for all microservices in the ecommerce-enterprise platform.

## Repository Naming Convention
- `ecommerce-{service-name}` (all lowercase, hyphenated)
- Examples: `ecommerce-auth-service`, `ecommerce-product-service`

## Directory Structure for Each Microservice

```
ecommerce-{service-name}/
├── .github/
│   └── workflows/
│       ├── build.yml
│       ├── test.yml
│       └── deploy.yml
├── src/
│   ├── main/
│   │   ├── java/com/ecommerce/{service}/
│   │   │   ├── controller/
│   │   │   ├── service/
│   │   │   ├── repository/
│   │   │   ├── entity/
│   │   │   ├── dto/
│   │   │   ├── exception/
│   │   │   ├── config/
│   │   │   └── {ServiceName}Application.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       └── logback.xml
│   └── test/
│       ├── java/com/ecommerce/{service}/
│       │   ├── controller/
│       │   ├── service/
│       │   └── repository/
│       └── resources/
│           └── application-test.yml
├── docker/
│   ├── Dockerfile
│   └── .dockerignore
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── hpa.yaml
├── pom.xml
├── README.md
├── CHANGELOG.md
└── .gitignore
```

## Repository Configuration

### Branch Protection Rules
- `main` branch: Requires 2 pull request reviews before merge
- `main` branch: Requires status checks to pass (CI/CD pipeline)
- `main` branch: Dismiss stale PR approvals when new commits are pushed

### Topics (Tags)
- `ecommerce-platform`
- `microservice`
- `spring-boot`
- `{service-specific-topic}`

### Description
`{Service Name} Microservice - Part of ecommerce-enterprise platform`

### Visibility
- Public (for demonstration) or Private (for production)

## GitHub Actions Workflows

### build.yml
- Run on: push to `main`, `develop`, PR to `main`
- Steps:
  - Checkout code
  - Set up JDK 17
  - Cache Maven dependencies
  - Run Maven clean install
  - Build Docker image
  - Push to Docker Hub
  - Update deployment manifest

### test.yml
- Run on: Every commit
- Steps:
  - Unit tests
  - Integration tests
  - Code coverage reporting
  - SonarQube analysis

### deploy.yml
- Run on: Push to `main`
- Steps:
  - Build and push Docker image
  - Update Kubernetes manifests
  - Deploy to staging/production
  - Health checks and smoke tests

## CI/CD Pipeline

Each microservice includes:
1. **Build Stage**
   - Maven clean install
   - Docker image build
   - Image push to registry

2. **Test Stage**
   - Unit tests with JUnit 5
   - Integration tests
   - Code coverage (JaCoCo) > 80%
   - SonarQube quality analysis

3. **Deploy Stage**
   - Deploy to Kubernetes cluster
   - Run health checks
   - Smoke tests
   - Rollback on failure

## Maven Configuration

### pom.xml Key Dependencies
- Spring Boot 3.1.5
- Spring Cloud 2022.0.4
- Spring Data JPA
- MySQL/PostgreSQL driver (as needed)
- Kafka client
- Redis
- JWT (io.jsonwebtoken)
- Lombok
- MapStruct
- JUnit 5
- Testcontainers

### Build Plugins
- maven-compiler-plugin
- maven-surefire-plugin
- maven-failsafe-plugin
- jacoco-maven-plugin
- dockerfile-maven-plugin
- sonar-maven-plugin

## Docker Configuration

### Dockerfile Best Practices
- Multi-stage builds for optimization
- Non-root user execution
- Health checks
- Resource limits
- Security scanning

### .dockerignore
Exclude unnecessary files and directories

## Kubernetes Manifests

Each microservice includes:
- Deployment (replicas, strategy, resources)
- Service (ClusterIP)
- ConfigMap (configuration)
- HorizontalPodAutoscaler
- PodDisruptionBudget
- ServiceAccount + RBAC

## Code Standards

### Java Project Structure
```
com.ecommerce.{service}
├── controller/          # REST endpoints
├── service/             # Business logic
├── repository/          # Data access layer
├── entity/              # JPA entities
├── dto/                 # Data transfer objects
├── exception/           # Custom exceptions
├── config/              # Configuration classes
├── util/                # Utility classes
└── mapper/              # Entity <-> DTO mappers
```

### Naming Conventions
- Controllers: `{Entity}Controller`
- Services: `{Entity}Service`, `I{Entity}Service` (interface)
- Repositories: `{Entity}Repository`
- Entities: `{Entity}Entity` or just `{Entity}`
- DTOs: `{Entity}DTO`, `{Entity}Request`, `{Entity}Response`
- Exceptions: `{Custom}Exception`

### Code Quality Requirements
- Minimum 80% code coverage
- SonarQube quality gate passed
- No critical/high priority issues
- Consistent formatting (Spotless/Checkstyle)

## README.md Template

```markdown
# {Service Name} Microservice

Description of the service and its responsibilities.

## Prerequisites
- Java 17+
- Maven 3.8+
- Docker
- Kubernetes (optional)

## Local Development

### Build
\`\`\`bash
mvn clean install
\`\`\`

### Run
\`\`\`bash
mvn spring-boot:run
\`\`\`

### Docker
\`\`\`bash
docker build -f docker/Dockerfile -t kedar111yahoo/ecommerce-{service}:latest .
docker run -p 8XXX:8XXX ecommerce-{service}:latest
\`\`\`

### Kubernetes
\`\`\`bash
kubectl apply -f k8s/
\`\`\`

## API Documentation
- Swagger UI: http://localhost:8XXX/swagger-ui.html
- API Docs: http://localhost:8XXX/v3/api-docs

## Environment Variables
[List all environment variables needed]

## Database Migrations
[Describe flyway or liquibase setup if applicable]

## Testing
\`\`\`bash
mvn test
mvn verify
\`\`\`

## Contributing
[Link to main repo contributing guidelines]

## License
MIT

## Contact
[Owner/team contact information]
```

## Repository Initialization Checklist

- [ ] Create repository with standardized name
- [ ] Add description and topics
- [ ] Clone repository locally
- [ ] Copy microservice template files
- [ ] Update pom.xml with service-specific configuration
- [ ] Update application.yml with service configuration
- [ ] Create GitHub Actions workflows
- [ ] Configure branch protection rules
- [ ] Add team as collaborators
- [ ] Enable required status checks
- [ ] Set up branch deletion protection
- [ ] Configure notification rules
- [ ] Document in main repo

## Service-Specific Details

### ecommerce-auth-service
- **Port**: 8001
- **Database**: MySQL
- **Key Features**: JWT, OAuth2, session management
- **Kafka Topics**: auth.events, auth.commands

### ecommerce-user-service
- **Port**: 8002
- **Database**: MySQL
- **Key Features**: User profile, preferences, admin
- **Kafka Topics**: user.events, user.commands

### ecommerce-product-service
- **Port**: 8003
- **Database**: PostgreSQL
- **Key Features**: Product catalog, inventory, search
- **Kafka Topics**: product.events, product.commands

### ecommerce-order-service
- **Port**: 8004
- **Database**: PostgreSQL
- **Key Features**: Order management, fulfillment
- **Kafka Topics**: order.events, order.commands, order.notifications

### ecommerce-payment-service
- **Port**: 8005
- **Database**: MySQL
- **Key Features**: Payment processing, refunds, PCI compliance
- **Kafka Topics**: payment.events, payment.commands

### ecommerce-api-gateway
- **Port**: 8080
- **Database**: None
- **Key Features**: Routing, authentication, rate limiting
- **Routes**: Auth, User, Product, Order, Payment services

### ecommerce-frontend
- **Port**: 4200
- **Technology**: Angular 16+
- **Key Features**: Web UI, admin dashboard
- **Build**: Node.js, npm

### ecommerce-infrastructure
- **Contents**: Docker Compose, Kubernetes manifests, monitoring
- **Components**: MySQL, PostgreSQL, Redis, Kafka, Prometheus, Grafana, ELK
