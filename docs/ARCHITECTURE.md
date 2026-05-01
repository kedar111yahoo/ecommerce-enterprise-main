# Ecommerce Enterprise - Architecture & Design

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Angular    │  │   Mobile     │  │  Third-Party │           │
│  │  Frontend    │  │   Apps       │  │  Integrations│           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
└─────────┼────────────────┼─────────────────┼──────────────────────┘
          │                │                 │
          └────────────────┼─────────────────┘
                           │
          ┌────────────────▼──────────────────┐
          │      API Gateway (Port 8000)      │
          │  • Request Routing                │
          │  • Authentication                 │
          │  • Rate Limiting                  │
          │  • Load Balancing                 │
          └────────────┬───────────┬──────────┘
                       │           │
        ┌──────────────┼───────────┼──────────────┬─────────────┐
        │              │           │              │             │
   ┌────▼───┐  ┌──────▼──┐ ┌─────▼───┐ ┌────────▼──┐  ┌──────▼──┐
   │ Auth   │  │ Product │ │ Order   │ │ Payment  │  │ User    │
   │Service │  │ Service │ │ Service │ │ Service  │  │ Service │
   │(8001)  │  │ (8002)  │ │ (8003)  │ │ (8004)   │  │ (8005)  │
   └────┬───┘  └────┬────┘ └────┬────┘ └────┬─────┘  └────┬────┘
        │           │           │           │             │
        └───────────┼───────────┼───────────┼─────────────┘
                    │
        ┌───────────▼───────────┐
        │   Eureka Server       │
        │  (Service Discovery)  │
        └───────────────────────┘
                    │
        ┌───────────▼───────────────────┐
        │      Data/Cache Layer         │
        │ ┌─────────┐  ┌─────┐  ┌─────┐│
        │ │ MySQL   │  │Redis│  │Kafka││
        │ │Database │  │Cache│  │Queue││
        │ └─────────┘  └─────┘  └─────┘│
        └───────────────────────────────┘
```

## Microservices Architecture

### 1. Auth Service (Port 8001)

**Responsibilities:**
- User registration and login
- OAuth2/OpenID Connect integration
- JWT token generation and validation
- Multi-factor authentication
- Password management

**Database Schema:**
```
users
├── id (PK)
├── email (UNIQUE)
├── password (hashed)
├── first_name
├── last_name
├── phone_number
├── role (USER, ADMIN, SELLER)
├── is_active
├── is_email_verified
├── is_mfa_enabled
├── created_at
├── updated_at
└── last_login
```

**Key APIs:**
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh-token` - Token refresh
- `POST /api/auth/logout` - Logout
- `GET /api/auth/validate` - Token validation

### 2. Product Service (Port 8002)

**Responsibilities:**
- Product catalog management
- Inventory management
- Product search and filtering
- Category management
- Price management

**Database Schema:**
```
products
├── id (PK)
├── name
├── description
├── sku
├── category_id (FK)
├── price
├── discount_price
├── quantity_in_stock
├── is_active
├── created_at
└── updated_at
```

### 3. Order Service (Port 8003)

**Responsibilities:**
- Order creation and management
- Order status tracking
- Order history
- Shipping information
- Order notifications

**Database Schema:**
```
orders
├── id (PK)
├── user_id (FK)
├── order_number
├── total_amount
├── status (PENDING, CONFIRMED, SHIPPED, DELIVERED)
├── shipping_address
├── created_at
└── updated_at

order_items
├── id (PK)
├── order_id (FK)
├── product_id (FK)
├── quantity
└── unit_price
```

### 4. Payment Service (Port 8004)

**Responsibilities:**
- Payment processing
- Payment gateway integration
- Transaction management
- Refund processing
- Invoice generation

**Supported Gateways:**
- Stripe
- PayPal
- Square
- Razorpay

### 5. User Service (Port 8005)

**Responsibilities:**
- User profile management
- Address management
- Preferences management
- Notification settings

### 6. API Gateway (Port 8000)

**Responsibilities:**
- Request routing to microservices
- JWT authentication
- Authorization (RBAC)
- Rate limiting
- Request logging
- Load balancing

## Security Architecture

### Authentication Flow

```
1. User Registration
   └─> Auth Service validates & creates user
   └─> Publishes user.registered event
   └─> Sends verification email

2. User Login
   └─> Auth Service validates credentials
   └─> Generates JWT token
   └─> Caches token in Redis
   └─> Returns access & refresh tokens

3. API Request
   └─> Client adds Authorization: Bearer <token>
   └─> API Gateway validates token via Auth Service
   └─> Routes request to microservice
   └─> Microservice processes request

4. Token Refresh
   └─> Client sends refresh token
   └─> Auth Service generates new access token
   └─> Cache updated in Redis
```

### JWT Token Structure

```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "sub": "user-id",
  "email": "user@example.com",
  "role": "USER",
  "iat": 1234567890,
  "exp": 1234571490
}

Signature:
HMACSHA256(base64UrlEncode(header) + "." + base64UrlEncode(payload), secret)
```

### SSL/TLS Certificate Management

```
Certificate Generation
└─> Create self-signed certificate (for dev)
└─> Or use Let's Encrypt (for production)
└─> Store in PKCS12 keystore
└─> Configure in application.yml
└─> Enable HTTPS on server port 8001/8002/etc
```

## Event-Driven Architecture (Kafka)

### Event Topics

```
user.registered
├── Published by: Auth Service
├── Consumed by: Email Service, User Service, Notification Service
└── Payload: userId, email, timestamp

product.created
├── Published by: Product Service
├── Consumed by: Catalog Service, Search Service
└── Payload: productId, name, price, category

order.created
├── Published by: Order Service
├── Consumed by: Payment Service, Inventory Service, Email Service
└── Payload: orderId, userId, totalAmount, items

order.confirmed
├── Published by: Order Service
├── Consumed by: Inventory Service, Shipping Service, Email Service
└── Payload: orderId, status, shippingAddress

payment.completed
├── Published by: Payment Service
├── Consumed by: Order Service, Inventory Service, Email Service
└── Payload: paymentId, orderId, amount, status

payment.failed
├── Published by: Payment Service
├── Consumed by: Order Service, Notification Service
└── Payload: paymentId, orderId, reason

inventory.updated
├── Published by: Product Service
├── Consumed by: Order Service, Catalog Service
└── Payload: productId, quantityChanged
```

## Caching Strategy

### Redis Cache Layers

```
1. Authentication Cache
   Key: auth_token:<user_id>
   Value: JWT Token
   TTL: 24 hours

2. User Cache
   Key: user:<user_id>
   Value: User Profile
   TTL: 1 hour

3. Product Cache
   Key: product:<product_id>
   Value: Product Details
   TTL: 2 hours

4. Session Cache
   Key: session:<session_id>
   Value: Session Data
   TTL: 30 minutes

5. Rate Limit Cache
   Key: rate_limit:<user_id>:<endpoint>
   Value: Request Count
   TTL: 1 minute
```

## Data Flow Example - Order Creation

```
1. User adds product to cart
   Angular Frontend → API Gateway → Product Service

2. User submits order
   Angular Frontend → API Gateway → Order Service
   └─> Creates order in MySQL
   └─> Publishes order.created event to Kafka

3. Event Processing
   Kafka → Payment Service
   ├─> Initiates payment processing
   ├─> Calls Stripe/PayPal API
   └─> Publishes payment.completed event

4. Order Confirmation
   Kafka → Inventory Service
   ├─> Updates product quantities
   └─> Publishes inventory.updated event

5. Notifications
   Kafka → Email Service
   └─> Sends order confirmation email

6. Response to User
   Order Service caches order in Redis
   └─> Returns order confirmation
```

## Database Design

### MySQL Schema

```sql
-- Users
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone_number VARCHAR(20),
  role ENUM('USER', 'ADMIN', 'SELLER') DEFAULT 'USER',
  is_active BOOLEAN DEFAULT TRUE,
  is_email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
);

-- Products
CREATE TABLE products (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  sku VARCHAR(100) UNIQUE NOT NULL,
  category_id BIGINT,
  price DECIMAL(10, 2) NOT NULL,
  discount_price DECIMAL(10, 2),
  quantity_in_stock INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_sku (sku),
  INDEX idx_category (category_id)
);

-- Orders
CREATE TABLE orders (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  order_number VARCHAR(100) UNIQUE NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  status ENUM('PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED') DEFAULT 'PENDING',
  shipping_address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_user (user_id),
  INDEX idx_status (status)
);
```

## Deployment Architecture

### Kubernetes Deployment

```
Namespace: ecommerce
├── Deployments
│   ├── auth-service (2 replicas)
│   ├── product-service (2 replicas)
│   ├── order-service (2 replicas)
│   ├── payment-service (2 replicas)
│   └── api-gateway (2 replicas)
├── Services
│   ├── ClusterIP for internal communication
│   └── LoadBalancer for API Gateway
├── ConfigMaps
│   └── app-config (environment variables)
├── Secrets
│   └── db-credentials (passwords, keys)
├── StatefulSets
│   ├── MySQL
│   └── Redis
└── PersistentVolumes
    ├── mysql-pv (10Gi)
    └── redis-pv (5Gi)
```

## Performance & Scalability

### Horizontal Scaling

Each microservice can be scaled independently:

```yaml
HorizontalPodAutoscaler:
  - minReplicas: 2
  - maxReplicas: 5
  - metrics:
    - CPU > 70%
    - Memory > 80%
```

### Caching Strategy

- Redis for session/token caching
- Database query result caching
- Client-side caching with Angular

### Database Optimization

- Indexing on frequently queried columns
- Connection pooling (HikariCP)
- Read replicas for scaling reads

## Monitoring & Observability

### Metrics Collection

- Prometheus for metrics scraping
- Spring Boot Actuator endpoints
- Custom business metrics

### Logging

- Centralized logging with ELK Stack
- Log aggregation from all services
- Structured logging with JSON

### Distributed Tracing

- Spring Cloud Sleuth for trace generation
- Zipkin for trace visualization
- Correlation IDs across services

---

**Version**: 1.0.0  
**Last Updated**: 2026-05-01
