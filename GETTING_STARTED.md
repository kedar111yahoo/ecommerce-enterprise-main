# Getting Started with Ecommerce Enterprise Application

## Prerequisites

Before you begin, ensure you have the following installed:

- **Java 17+** - [Download](https://www.oracle.com/java/technologies/downloads/#java17)
- **Node.js 18+** - [Download](https://nodejs.org/)
- **Docker & Docker Compose** - [Download](https://www.docker.com/products/docker-desktop)
- **Kubernetes (minikube or Docker Desktop)** - [Setup Guide](https://kubernetes.io/docs/setup/)
- **Git** - [Download](https://git-scm.com/)
- **Gradle 8.0+** - (or use wrapper scripts)

## Step 1: Clone All Repositories

```bash
# Create a workspace directory
mkdir ecommerce-workspace
cd ecommerce-workspace

# Clone main repository
git clone https://github.com/kedar111yahoo/ecommerce-enterprise-main.git

# Clone microservice repositories (create them first)
git clone https://github.com/kedar111yahoo/ecommerce-auth-service.git
git clone https://github.com/kedar111yahoo/ecommerce-product-service.git
git clone https://github.com/kedar111yahoo/ecommerce-order-service.git
git clone https://github.com/kedar111yahoo/ecommerce-payment-service.git
git clone https://github.com/kedar111yahoo/ecommerce-user-service.git
git clone https://github.com/kedar111yahoo/ecommerce-api-gateway.git
git clone https://github.com/kedar111yahoo/ecommerce-frontend.git
```

## Step 2: Start Infrastructure (Docker Compose)

From the main repository directory:

```bash
cd ecommerce-enterprise-main

# Start all infrastructure services
docker-compose up -d

# Verify services are running
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

This will start:
- ✅ MySQL Database
- ✅ Redis Cache
- ✅ Apache Kafka
- ✅ Zookeeper
- ✅ RabbitMQ
- ✅ Eureka Server (Service Discovery)

## Step 3: Configure Environment Variables

Create `.env` file in the main directory:

```env
# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=ecommerce
DB_USER=ecommerce_user
DB_PASSWORD=ecommerce_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-super-secret-key-change-in-production-minimum-256-bits-long-key-here
JWT_EXPIRATION=86400000

# SSL
SSL_KEYSTORE_PASSWORD=changeit

# OAuth2
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret

# Stripe
STRIPE_API_KEY=your-stripe-api-key

# PayPal
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-client-secret
```

## Step 4: Build Microservices

### Build Auth Service

```bash
cd ecommerce-auth-service

# Copy templates from main repo
cp ../ecommerce-enterprise-main/microservice-templates/* src/main/java/com/ecommerce/auth/

# Build with Gradle
./gradlew clean build

# Run locally
./gradlew bootRun

# Or run with Docker
docker build -t kedar111yahoo/ecommerce-auth-service:latest .
docker run -p 8001:8001 kedar111yahoo/ecommerce-auth-service:latest
```

### Similar steps for other services:
- Product Service (Port 8002)
- Order Service (Port 8003)
- Payment Service (Port 8004)
- User Service (Port 8005)
- API Gateway (Port 8000)

## Step 5: Build and Run Frontend

```bash
cd ecommerce-frontend

# Install dependencies
npm install

# Copy Angular templates
cp ../ecommerce-enterprise-main/frontend-templates/* src/app/auth/

# Serve locally
ng serve

# Or build for production
ng build --configuration production
```

Access the frontend at: `http://localhost:4200`

## Step 6: Deploy to Kubernetes

### Create namespace and infrastructure

```bash
# Apply namespace, configmaps, secrets, PV, and storage
kubectl apply -f k8s/infrastructure.yaml

# Apply RBAC policies
kubectl apply -f k8s/rbac.yaml

# Apply Auth Service deployment
kubectl apply -f k8s/auth-service-deployment.yaml
```

### Verify deployment

```bash
# Check pods
kubectl get pods -n ecommerce

# Check services
kubectl get svc -n ecommerce

# View logs
kubectl logs -f deployment/auth-service -n ecommerce

# Access dashboard
kubectl port-forward svc/auth-service 8001:8001 -n ecommerce
```

## Step 7: CI/CD Pipeline

The GitHub Actions workflow is pre-configured in `.github/workflows/build-and-deploy.yml`.

### Required GitHub Secrets

Add these to your repository settings:

```
DOCKER_USERNAME         - Your Docker Hub username
DOCKER_PASSWORD         - Your Docker Hub password
KUBECONFIG              - Base64 encoded kubeconfig
SONAR_HOST_URL          - SonarQube URL
SONAR_LOGIN             - SonarQube token
```

Set these secrets:

```bash
# Using GitHub CLI
gh secret set DOCKER_USERNAME --body "your-username"
gh secret set DOCKER_PASSWORD --body "your-password"
gh secret set KUBECONFIG --body "$(cat ~/.kube/config | base64)"
```

## Step 8: Test the Application

### Test Auth Service

```bash
# Register
curl -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "confirmPassword": "password123",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+1234567890"
  }'

# Login
curl -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'

# Validate Token
curl -X GET http://localhost:8001/api/auth/validate \
  -H "Authorization: Bearer <your-token>"
```

### Run Unit Tests

```bash
cd ecommerce-auth-service
./gradlew test
```

### Run Integration Tests

```bash
cd ecommerce-auth-service
./gradlew integrationTest
```

## Step 9: Database Setup

### Initialize Database

```bash
# Connect to MySQL
mysql -h localhost -u root -p

# Create database and user
CREATE DATABASE ecommerce;
CREATE USER 'ecommerce_user'@'localhost' IDENTIFIED BY 'ecommerce_password';
GRANT ALL PRIVILEGES ON ecommerce.* TO 'ecommerce_user'@'localhost';
FLUSH PRIVILEGES;
```

### Run Migrations

Flyway migrations are automatically run on application startup:

```
src/main/resources/db/migration/
├── V1__Initial_schema.sql
├── V2__Add_user_table.sql
└── V3__Add_indexes.sql
```

## Step 10: Monitoring & Logging

### Access Monitoring Dashboards

- **Eureka Service Discovery**: http://localhost:8761
- **Swagger API Docs**: http://localhost:8000/swagger-ui.html
- **Actuator Health**: http://localhost:8001/actuator/health

### View Kafka Topics

```bash
# List topics
docker exec ecommerce-kafka kafka-topics --list --bootstrap-server localhost:9092

# Create topic
docker exec ecommerce-kafka kafka-topics --create --topic user.registered --bootstrap-server localhost:9092

# Consume messages
docker exec -it ecommerce-kafka kafka-console-consumer --topic user.registered --from-beginning --bootstrap-server localhost:9092
```

## 🔒 SSL/TLS Configuration

### Generate Self-Signed Certificate

```bash
keytool -genkey -alias tomcat -keyalg RSA -keysize 2048 \
  -keystore keystore.p12 -validity 365 \
  -storepass changeit -storetype PKCS12 \
  -dname "CN=localhost,OU=IT,O=ecommerce,L=City,S=State,C=US"

# Copy to service resources
cp keystore.p12 ecommerce-auth-service/src/main/resources/
```

### Enable HTTPS in Application

The application is configured to use HTTPS by default. Update `application.yml`:

```yaml
server:
  ssl:
    enabled: true
    key-store: classpath:keystore.p12
    key-store-password: changeit
```

## 📊 API Gateway Configuration

The API Gateway routes requests to microservices:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: auth-service
          uri: http://auth-service:8001
          predicates:
            - Path=/api/auth/**
        
        - id: product-service
          uri: http://product-service:8002
          predicates:
            - Path=/api/products/**
```

## 🛠️ Troubleshooting

### Services Won't Start

```bash
# Check if ports are in use
lsof -i :8001

# Kill process using port
kill -9 <PID>

# Or change port in application.yml
server:
  port: 8001
```

### Database Connection Issues

```bash
# Check MySQL is running
docker ps | grep mysql

# View logs
docker logs ecommerce-mysql

# Connect to MySQL
mysql -h 127.0.0.1 -u ecommerce_user -p ecommerce
```

### Kafka Issues

```bash
# Check Kafka is running
docker ps | grep kafka

# View Kafka logs
docker logs ecommerce-kafka

# Test connectivity
docker exec ecommerce-kafka kafka-broker-api-versions --bootstrap-server localhost:9092
```

## 📖 Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Spring Cloud Documentation](https://spring.io/projects/spring-cloud)
- [Angular Documentation](https://angular.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)

---

**Need Help?** 
- Check logs: `docker-compose logs -f <service-name>`
- Review application properties: Check `application.yml`
- Debug: Enable debug logging by setting `logging.level.com.ecommerce=DEBUG`

