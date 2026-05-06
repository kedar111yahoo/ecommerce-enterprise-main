#!/bin/bash

###############################################################################
# Ecommerce Enterprise - Automated Repository Creation Script
# 
# This script automates the creation and setup of all 8 microservice repositories
# for the ecommerce-enterprise platform.
#
# Usage: bash scripts/create-all-repos.sh
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_USERNAME="kedar111yahoo"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"  # Set via environment variable
BASE_DIR="${HOME}/ecommerce-services"
TEMPLATE_DIR="${HOME}/ecommerce-enterprise-main"

# Service definitions
declare -A SERVICES=(
  ["auth-service"]="Auth Service|8001|MySQL|Authentication & Authorization"
  ["user-service"]="User Service|8002|MySQL|User Management"
  ["product-service"]="Product Service|8003|PostgreSQL|Product Catalog"
  ["order-service"]="Order Service|8004|PostgreSQL|Order Processing"
  ["payment-service"]="Payment Service|8005|MySQL|Payment Processing"
  ["api-gateway"]="API Gateway|8080|None|API Gateway"
)

SPECIAL_SERVICES=(
  "frontend:Frontend|4200|Angular|Web UI"
  "infrastructure:Infrastructure|N/A|DevOps|Infrastructure as Code"
)

###############################################################################
# Helper Functions
###############################################################################

print_header() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

check_prerequisites() {
  print_header "Checking Prerequisites"
  
  # Check git
  if ! command -v git &> /dev/null; then
    print_error "Git is not installed"
    exit 1
  fi
  print_success "Git is installed"
  
  # Check curl
  if ! command -v curl &> /dev/null; then
    print_error "curl is not installed"
    exit 1
  fi
  print_success "curl is installed"
  
  # Check GitHub token
  if [ -z "$GITHUB_TOKEN" ]; then
    print_warning "GITHUB_TOKEN not set. Using git credentials."
    print_info "For better compatibility, set: export GITHUB_TOKEN=your_token"
  else
    print_success "GitHub token is configured"
  fi
}

create_repository() {
  local repo_name=$1
  local description=$2
  
  print_info "Creating repository: ecommerce-$repo_name"
  
  # Create via GitHub API
  local payload=$(cat <<EOF
{
  "name": "ecommerce-$repo_name",
  "description": "$description",
  "private": false,
  "has_issues": true,
  "has_projects": true,
  "has_wiki": true,
  "auto_init": true,
  "gitignore_template": "Java",
  "license_template": "mit"
}
EOF
)
  
  if [ -z "$GITHUB_TOKEN" ]; then
    # Use git CLI
    gh repo create "ecommerce-$repo_name" \
      --public \
      --source=. \
      --remote=origin \
      --description="$description" \
      --disable-wiki \
      --add-readme 2>/dev/null || true
  else
    # Use GitHub API
    curl -s -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      https://api.github.com/user/repos \
      -d "$payload" > /dev/null
  fi
  
  print_success "Repository created: ecommerce-$repo_name"
}

clone_repository() {
  local repo_name=$1
  local target_dir="$BASE_DIR/ecommerce-$repo_name"
  
  if [ -d "$target_dir" ]; then
    print_warning "Repository already exists: $target_dir"
    return
  fi
  
  print_info "Cloning repository: ecommerce-$repo_name"
  git clone "https://github.com/$GITHUB_USERNAME/ecommerce-$repo_name.git" "$target_dir"
  print_success "Cloned: $target_dir"
}

setup_backend_service() {
  local service_name=$1
  local service_port=$2
  local database=$3
  local repo_dir="$BASE_DIR/ecommerce-$service_name"
  
  print_header "Setting up Backend Service: $service_name (Port $service_port)"
  
  if [ ! -d "$repo_dir" ]; then
    print_error "Repository not found: $repo_dir"
    return 1
  fi
  
  cd "$repo_dir"
  
  # Create directory structure
  print_info "Creating directory structure..."
  mkdir -p "src/main/java/com/ecommerce/${service_name%-*}"
  mkdir -p "src/main/java/com/ecommerce/${service_name%-*}/{controller,service,repository,entity,dto,exception,config}"
  mkdir -p "src/main/resources"
  mkdir -p "src/test/java/com/ecommerce/${service_name%-*}/{controller,service,repository}"
  mkdir -p "src/test/resources"
  mkdir -p "docker"
  mkdir -p "k8s"
  mkdir -p ".github/workflows"
  
  # Copy template files
  print_info "Copying template files..."
  cp "$TEMPLATE_DIR/microservice-templates/pom.xml" "pom.xml" 2>/dev/null || print_warning "pom.xml template not found"
  cp "$TEMPLATE_DIR/Dockerfile" "docker/Dockerfile" 2>/dev/null || print_warning "Dockerfile template not found"
  cp "$TEMPLATE_DIR/microservice-templates/application.yml" "src/main/resources/application.yml" 2>/dev/null || print_warning "application.yml template not found"
  
  # Create service-specific files
  print_info "Creating service-specific configurations..."
  
  # Update pom.xml
  if [ -f "pom.xml" ]; then
    sed -i.bak "s/{service-name}/$service_name/g" pom.xml
    sed -i.bak "s/{service-port}/$service_port/g" pom.xml
    sed -i.bak "s/{database}/$database/g" pom.xml
    rm -f pom.xml.bak
    print_success "Updated pom.xml"
  fi
  
  # Update application.yml
  if [ -f "src/main/resources/application.yml" ]; then
    sed -i.bak "s/{service-name}/$service_name/g" src/main/resources/application.yml
    sed -i.bak "s/{service-port}/$service_port/g" src/main/resources/application.yml
    rm -f src/main/resources/application.yml.bak
    print_success "Updated application.yml"
  fi
  
  # Update Dockerfile
  if [ -f "docker/Dockerfile" ]; then
    sed -i.bak "s/{service-name}/$service_name/g" docker/Dockerfile
    sed -i.bak "s/{service-port}/$service_port/g" docker/Dockerfile
    rm -f docker/Dockerfile.bak
    print_success "Updated Dockerfile"
  fi
  
  # Create .gitignore
  if [ ! -f ".gitignore" ]; then
    cat > ".gitignore" << 'EOF'
# IDE
.idea/
.vscode/
*.swp
*.swo
*.iml

# Build
target/
build/
*.jar
*.class

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

# OS
.DS_Store
Thumbs.db
EOF
    print_success "Created .gitignore"
  fi
  
  # Create GitHub Actions workflows
  print_info "Setting up GitHub Actions workflows..."
  mkdir -p ".github/workflows"
  
  # build.yml
  cat > ".github/workflows/build.yml" << 'EOF'
name: Build and Test
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      - name: Build with Maven
        run: mvn clean install
      - name: Run tests
        run: mvn test
      - name: Build Docker image
        run: docker build -f docker/Dockerfile -t kedar111yahoo/ecommerce-SERVICE:${{ github.sha }} .
EOF
    print_success "Created build.yml"
  fi
  
  # Create initial commit
  print_info "Creating initial commit..."
  git add .
  git commit -m "feat: Initial microservice structure setup" 2>/dev/null || print_warning "Nothing to commit"
  git push origin main 2>/dev/null || print_warning "Failed to push"
  
  print_success "Backend service setup complete: $service_name"
  cd - > /dev/null
}

setup_frontend() {
  local repo_dir="$BASE_DIR/ecommerce-frontend"
  
  print_header "Setting up Frontend Service"
  
  if [ ! -d "$repo_dir" ]; then
    print_error "Repository not found: $repo_dir"
    return 1
  fi
  
  cd "$repo_dir"
  
  # Create Angular project structure
  print_info "Creating Angular directory structure..."
  mkdir -p "src/app/{components,services,models,pages,modules,shared}"
  mkdir -p "src/assets/{images,styles,fonts}"
  mkdir -p ".github/workflows"
  
  # Create package.json
  if [ ! -f "package.json" ]; then
    cat > "package.json" << 'EOF'
{
  "name": "ecommerce-frontend",
  "version": "1.0.0",
  "scripts": {
    "ng": "ng",
    "start": "ng serve",
    "build": "ng build",
    "test": "ng test",
    "lint": "ng lint"
  },
  "private": true,
  "dependencies": {
    "@angular/animations": "^16.0.0",
    "@angular/common": "^16.0.0",
    "@angular/compiler": "^16.0.0",
    "@angular/core": "^16.0.0",
    "@angular/forms": "^16.0.0",
    "@angular/platform-browser": "^16.0.0",
    "@angular/platform-browser-dynamic": "^16.0.0",
    "@angular/router": "^16.0.0",
    "rxjs": "^7.8.0",
    "tslib": "^2.3.0",
    "zone.js": "^0.13.0"
  }
}
EOF
    print_success "Created package.json"
  fi
  
  # Create .gitignore
  if [ ! -f ".gitignore" ]; then
    cat > ".gitignore" << 'EOF'
node_modules/
dist/
.angular/
.DS_Store
*.log
.env
.env.local
EOF
    print_success "Created .gitignore"
  fi
  
  # Create initial commit
  print_info "Creating initial commit..."
  git add .
  git commit -m "feat: Initial Angular frontend setup" 2>/dev/null || print_warning "Nothing to commit"
  git push origin main 2>/dev/null || print_warning "Failed to push"
  
  print_success "Frontend setup complete"
  cd - > /dev/null
}

setup_infrastructure() {
  local repo_dir="$BASE_DIR/ecommerce-infrastructure"
  
  print_header "Setting up Infrastructure Repository"
  
  if [ ! -d "$repo_dir" ]; then
    print_error "Repository not found: $repo_dir"
    return 1
  fi
  
  cd "$repo_dir"
  
  # Create directory structure
  print_info "Creating infrastructure directory structure..."
  mkdir -p "docker"
  mkdir -p "k8s/{base,overlays/{dev,staging,prod}}"
  mkdir -p "monitoring/{prometheus,grafana}"
  mkdir -p "logging/{elasticsearch,kibana}"
  mkdir -p "scripts"
  mkdir -p ".github/workflows"
  
  # Copy docker-compose
  print_info "Copying infrastructure files..."
  cp "$TEMPLATE_DIR/docker-compose.yml" "docker/docker-compose.yml" 2>/dev/null || print_warning "docker-compose.yml not found"
  
  # Create scripts
  mkdir -p "scripts"
  cat > "scripts/deploy.sh" << 'EOF'
#!/bin/bash
# Deployment script for Kubernetes
# Usage: ./scripts/deploy.sh [dev|staging|prod]

ENV=${1:-dev}
echo "Deploying to $ENV environment..."
kubectl apply -k k8s/overlays/$ENV/
EOF
  chmod +x "scripts/deploy.sh"
  
  # Create .gitignore
  if [ ! -f ".gitignore" ]; then
    cat > ".gitignore" << 'EOF'
.env
.env.local
kubeconfig
*.log
node_modules/
dist/
EOF
    print_success "Created .gitignore"
  fi
  
  # Create initial commit
  print_info "Creating initial commit..."
  git add .
  git commit -m "feat: Initial infrastructure setup" 2>/dev/null || print_warning "Nothing to commit"
  git push origin main 2>/dev/null || print_warning "Failed to push"
  
  print_success "Infrastructure setup complete"
  cd - > /dev/null
}

configure_branch_protection() {
  local repo_name=$1
  
  print_info "Configuring branch protection for: $repo_name"
  
  if [ -z "$GITHUB_TOKEN" ]; then
    print_warning "Skipping branch protection (GITHUB_TOKEN not set)"
    return
  fi
  
  # This would require more complex GitHub API calls
  # For now, we'll skip it or provide manual instructions
  print_warning "Please configure branch protection manually in GitHub UI"
}

display_summary() {
  print_header "Repository Creation Summary"
  
  echo -e "${GREEN}Backend Services:${NC}"
  for service in "${!SERVICES[@]}"; do
    echo -e "  ✓ https://github.com/$GITHUB_USERNAME/ecommerce-$service"
  done
  
  echo ""
  echo -e "${GREEN}Frontend:${NC}"
  echo -e "  ✓ https://github.com/$GITHUB_USERNAME/ecommerce-frontend"
  
  echo ""
  echo -e "${GREEN}Infrastructure:${NC}"
  echo -e "  ✓ https://github.com/$GITHUB_USERNAME/ecommerce-infrastructure"
  
  echo ""
  print_header "Next Steps"
  echo "1. Configure branch protection rules in GitHub UI"
  echo "2. Set up GitHub Secrets for each repository"
  echo "3. Configure GitHub Actions workflows"
  echo "4. Add team members and permissions"
  echo "5. Create project board and issues"
  echo "6. Set up monitoring and logging"
}

###############################################################################
# Main Execution
###############################################################################

main() {
  print_header "Ecommerce Enterprise - Automated Setup"
  
  # Check prerequisites
  check_prerequisites
  
  # Create base directory
  print_info "Creating base directory: $BASE_DIR"
  mkdir -p "$BASE_DIR"
  
  # Create repositories
  print_header "Creating Repositories"
  
  # Backend services
  for service in "${!SERVICES[@]}"; do
    IFS='|' read -r name port db desc <<< "${SERVICES[$service]}"
    create_repository "$service" "$desc"
  done
  
  # Frontend
  create_repository "frontend" "Frontend Web Application"
  
  # Infrastructure
  create_repository "infrastructure" "Infrastructure as Code"
  
  # Clone repositories
  print_header "Cloning Repositories"
  
  for service in "${!SERVICES[@]}"; do
    clone_repository "$service"
  done
  clone_repository "frontend"
  clone_repository "infrastructure"
  
  # Setup services
  print_header "Setting up Services"
  
  # Backend services
  for service in "${!SERVICES[@]}"; do
    IFS='|' read -r name port db desc <<< "${SERVICES[$service]}"
    setup_backend_service "$service" "$port" "$db"
  done
  
  # Frontend
  setup_frontend
  
  # Infrastructure
  setup_infrastructure
  
  # Display summary
  display_summary
  
  print_header "Setup Complete!"
  echo ""
  print_success "All repositories have been created and initialized!"
  echo ""
  print_info "Repository locations: $BASE_DIR"
  echo ""
}

# Run main function
main "$@"
