#!/bin/bash

# Weather Dashboard Deployment Script
# This script automates the deployment process for the weather dashboard application

set -e  # Exit on any error

# Configuration
DOCKER_HUB_USERNAME="your-dockerhub-username"
APP_NAME="weather-dashboard"
VERSION="v1"
IMAGE_NAME="${DOCKER_HUB_USERNAME}/${APP_NAME}:${VERSION}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists curl; then
        print_error "curl is not installed. Please install curl first."
        exit 1
    fi
    
    print_status "Prerequisites check passed."
}

# Build Docker image
build_image() {
    print_status "Building Docker image: ${IMAGE_NAME}"
    
    if [ ! -f "Dockerfile" ]; then
        print_error "Dockerfile not found in current directory."
        exit 1
    fi
    
    docker build -t "${IMAGE_NAME}" .
    docker tag "${IMAGE_NAME}" "${DOCKER_HUB_USERNAME}/${APP_NAME}:latest"
    
    print_status "Image built successfully."
}

# Test image locally
test_image() {
    print_status "Testing image locally..."
    
    # Stop any existing container
    docker stop weather-test 2>/dev/null || true
    docker rm weather-test 2>/dev/null || true
    
    # Run test container
    docker run -d --name weather-test -p 8081:8080 "${IMAGE_NAME}"
    
    # Wait for container to start
    sleep 5
    
    # Test health endpoint
    if curl -f http://localhost:8081/health >/dev/null 2>&1; then
        print_status "Local test passed."
    else
        print_error "Local test failed. Container may not be healthy."
        docker logs weather-test
        docker stop weather-test
        docker rm weather-test
        exit 1
    fi
    
    # Cleanup test container
    docker stop weather-test
    docker rm weather-test
}

# Push to Docker Hub
push_image() {
    print_status "Pushing image to Docker Hub..."
    
    if ! docker info | grep -q "Username:"; then
        print_warning "Please login to Docker Hub first:"
        docker login
    fi
    
    docker push "${IMAGE_NAME}"
    docker push "${DOCKER_HUB_USERNAME}/${APP_NAME}:latest"
    
    print_status "Image pushed successfully."
}

# Deploy to web servers
deploy_to_servers() {
    print_status "Deploying to web servers..."
    
    # List of servers to deploy to
    SERVERS=("web-01" "web-02")
    
    for server in "${SERVERS[@]}"; do
        print_status "Deploying to ${server}..."
        
        # Note: In real deployment, you would SSH to these servers
        # For demo purposes, we'll show the commands that would be run
        
        cat << EOF
# Commands to run on ${server}:
ssh user@${server} << 'ENDSSH'
    # Stop existing container
    docker stop weather-app 2>/dev/null || true
    docker rm weather-app 2>/dev/null || true
    
    # Pull latest image
    docker pull ${IMAGE_NAME}
    
    # Run new container
    docker run -d --name weather-app --restart unless-stopped \\
        -p 8080:8080 ${IMAGE_NAME}
    
    # Wait for container to be ready
    sleep 10
    
    # Test health
    curl -f http://localhost:8080/health
    
    echo "Deployment to ${server} completed successfully."
ENDSSH
EOF
    done
}

# Configure load balancer
configure_load_balancer() {
    print_status "Load balancer configuration:"
    
    cat << 'EOF'
# Update /etc/haproxy/haproxy.cfg on lb-01:

backend weather_backend
    balance roundrobin
    option httpchk GET /health
    server web01 172.20.0.11:8080 check
    server web02 172.20.0.12:8080 check

# Reload HAProxy:
docker exec -it lb-01 sh -c 'haproxy -sf $(pidof haproxy) -f /etc/haproxy/haproxy.cfg'
EOF
}

# Test load balancing
test_load_balancing() {
    print_status "Testing load balancing..."
    
    cat << 'EOF'
# Test commands:
# Test multiple requests to see load balancing
for i in {1..6}; do
    echo "Request $i:"
    curl -s http://localhost/health
    sleep 1
done

# Check HAProxy stats (if enabled)
curl http://localhost:8404/stats
EOF
}

# Main deployment function
main() {
    print_status "Starting Weather Dashboard deployment..."
    
    check_prerequisites
    build_image
    test_image
    
    # Ask user if they want to push to Docker Hub
    read -p "Do you want to push the image to Docker Hub? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        push_image
    fi
    
    deploy_to_servers
    configure_load_balancer
    test_load_balancing
    
    print_status "Deployment process completed!"
    print_warning "Note: This script shows the deployment steps. You'll need to:"
    print_warning "1. Actually SSH to your web servers and run the deployment commands"
    print_warning "2. Update the HAProxy configuration on your load balancer"
    print_warning "3. Run the load balancing tests"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
