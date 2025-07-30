Weather Dashboard Application
A comprehensive weather application that provides real-time weather data and 5-day forecasts for cities worldwide. This application serves a practical purpose by helping users make informed decisions about their daily activities based on current weather conditions.

Features

•	Real-time Weather Data: Get current weather conditions for any city.

•	Location-based Weather: Use your current location to get local weather.

•	5-Day Forecast: View upcoming weather predictions.

•	Multiple Cities: Track weather for multiple cities simultaneously.

•	Unit Conversion: Switch between Celsius, Fahrenheit, and Kelvin.

•	Data Sorting: Sort by city name, temperature, or search time.

•	Data Filtering: Filter and search weather data.

•	Responsive Design: Works on desktop and mobile devices.

•	Error Handling: Graceful handling of API failures and invalid inputs
API Used.

This application uses the OpenWeatherMap API (in demo mode for this assignment):

•	API Documentation: https://openweathermap.org/api.

•	Current Weather API: Provides real-time weather data.

•	5-Day Forecast API: Provides weather predictions.

•	Geocoding API: Converts city names to coordinates.

Note: For demo purposes, this application uses mock data. In production, you would need to:

1.	Sign up for a free API key at OpenWeatherMap.
2.	Replace the demo API key with your actual key
3.	Remove the demo data simulation
Local Development
Prerequisites
•	Modern web browser with JavaScript enabled
•	Optional: Local web server for development
Running Locally
1.	Save the HTML file as index.html
2.	Open directly in a web browser, or
3.	Use a local server: python -m http.server 8000 (Python 3) or python -m SimpleHTTPServer 8000 (Python 2)
4.	Navigate to http://localhost:8000
Docker Deployment
Image Details
•	Docker Hub Repository: christiantuyishime/weather-dashboard
•	Image Tags: v1, latest
•	Base Image: nginx:alpine
•	Exposed Port: 8080
Build Instructions

# Clone the repository
git clone <https://github.com/christiantuyishime01/weather-dashboard-application-api-summative.git>
cd weather-dashboard

# Build the Docker image
docker build -t your-christiantuyishime/weather-dashboard:v1.

# Test locally
docker run -p 8080:8080 christiantuyishime/weather-dashboard:v1

# Verify it works
curl http://localhost:8080
Push to Docker Hub

# Login to Docker Hub
docker login

# Tag the image
docker tag your-dockerhub-username/weather-dashboard:v1 your-dockerhub-username/weather-dashboard:latest

# Push to Docker Hub
docker push christiantuyishime/weather-dashboard:v1
docker push christiantuyishime/weather-dashboard:latest
Web Server Deployment
Deploy on Web01 and Web02

# SSH into web-01
ssh user@web-01

# Pull and run the image
docker pull christiantuyishime/weather-dashboard:v1
docker run -d --name weather-app --restart unless-stopped \
  -p 8080:8080 christiantuyishime/weather-dashboard:v1

# Verify it's running
curl http://localhost:8080/health

# Repeat the same steps on web-02
Load Balancer Configuration (HAProxy)
Update /etc/haproxy/haproxy.cfg on lb-01:
global
    daemon

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend weather_frontend
    bind *:80
    default_backend weather_backend

backend weather_backend
    balance roundrobin
    option httpchk GET /health
    server web01 172.20.0.11:8080 check
    server web02 172.20.0.12:8080 check
Reload HAProxy:
docker exec -it lb-01 sh -c 'haproxy -sf $(pidof haproxy) -f /etc/haproxy/haproxy.cfg'
Testing Load Balancing
Test that traffic is distributed between both servers:
# From your host machine
curl -s http://localhost/health
curl -s http://localhost/health
curl -s http://localhost/health

# Check HAProxy stats (if enabled)
curl http://localhost:8404/stats
You should see responses alternating between web01 and web02.
Environment Variables and Secrets
For production deployment with real API keys:
1.	Environment Variables: Store API keys as environment variables
docker run -d --name weather-app \
  -e OPENWEATHER_API_KEY=your_actual_api_key \
  -p 8080:8080 your-dockerhub-username/weather-dashboard:v1
2.	Docker Secrets: Use Docker secrets for sensitive data
echo "your_api_key" | docker secret create openweather_key -
3.	Kubernetes Secrets: For Kubernetes deployments
apiVersion: v1
kind: Secret
metadata:
  name: weather-api-secret
data:
  api-key: <base64-encoded-key>
Application Architecture
•	Frontend: HTML5, CSS3, JavaScript (ES6+)
•	Styling: Modern CSS with Flexbox and Grid
•	API Integration: Fetch API for HTTP requests
•	Error Handling: Comprehensive error handling and user feedback
•	Responsive Design: Mobile-first approach
•	State Management: JavaScript objects for data storage
User Experience Features
•	Intuitive Interface: Clean, modern design with clear navigation
•	Real-time Updates: Immediate feedback on user actions
•	Data Persistence: Weather data persists during the session
•	Multiple Views: Grid layout for comparing multiple cities
•	Interactive Elements: Hover effects and smooth animations
•	Accessibility: Semantic HTML and keyboard navigation support
Development Challenges and Solutions
Challenge 1: API Rate Limiting
Solution: Implemented caching mechanism and demo mode for development
Challenge 2: Error Handling
Solution: Comprehensive error handling with user-friendly messages
Challenge 3: Responsive Design
Solution: CSS Grid and Flexbox with mobile-first approach
Challenge 4: Cross-Origin Requests (CORS)
Solution: Server-side proxy or CORS-enabled API endpoints
Challenge 5: Data Synchronization
Solution: Centralized state management with real-time updates
API Credits and Attribution
•	OpenWeatherMap API: https://openweathermap.org/ 
o	Current weather data
o	5-day weather forecast
o	Geocoding services
•	Browser Geolocation API: For location-based weather
•	Fetch API: For HTTP requests
Security Considerations
•	API keys stored as environment variables (not in source code)
•	Input validation and sanitization
•	HTTPS enforcement in production
•	Rate limiting protection
•	No sensitive data in client-side code
Performance Optimizations
•	Lazy loading of forecast data
•	Efficient DOM manipulation
•	CSS animations using transform/opacity
•	Minimal external dependencies
•	Optimized image and asset delivery
Browser Compatibility
•	Chrome 60+
•	Firefox 55+
•	Safari 12+
•	Edge 79+
•	Mobile browsers (iOS Safari, Chrome Mobile)
Testing Strategy
Manual Testing
1.	Test search functionality with various city names
2.	Verify geolocation feature
3.	Test unit conversion between C/F/K
4.	Check sorting and filtering features
5.	Test responsive design on different screen sizes
6.	Verify error handling with invalid inputs
Load Balancer Testing
# Test multiple concurrent requests
for i in {1..10}; do
  curl -s http://localhost/ &
done
wait

# Monitor HAProxy logs
docker logs lb-01 -f

# Check server distribution
curl -s http://localhost/health | grep -o "web0[12]"
Deployment Verification Checklist
•	[ ] Application builds successfully
•	[ ] Docker image runs locally
•	[ ] Image pushed to Docker Hub
•	[ ] Application deployed on web01
•	[ ] Application deployed on web02
•	[ ] HAProxy configured correctly
•	[ ] Load balancing working
•	[ ] Health checks passing
•	[ ] Error handling functional
•	[ ] All features working end-to-end
Monitoring and Maintenance
Health Checks
•	Application health endpoint: /health
•	HAProxy health monitoring
•	Container status monitoring
Logs

# Application logs
docker logs weather-app

# HAProxy logs
docker logs lb-01

# System logs
journalctl -u docker
Updates and Rollbacks

# Update to new version
docker pull your-dockerhub-username/weather-dashboard:v2
docker stop weather-app
docker rm weather-app
docker run -d --name weather-app --restart unless-stopped \
  -p 8080:8080 your-dockerhub-username/weather-dashboard:v2

# Rollback if needed
docker run -d --name weather-app --restart unless-stopped \
  -p 8080:8080 your-dockerhub-username/weather-dashboard:v1
Future Enhancements
•	[ ] User authentication and personal weather profiles
•	[ ] Weather alerts and notifications
•	[ ] Historical weather data visualization
•	[ ] Integration with calendar applications
•	[ ] Severe weather warnings
•	[ ] Multiple language support
•	[ ] Dark/light theme toggle
•	[ ] Weather map integration
•	[ ] Social sharing features
•	[ ] Progressive Web App (PWA) capabilities
Contributing
1.	Fork the repository
2.	Create a feature branch
3.	Make your changes
4.	Test thoroughly
5.	Submit a pull request
License
This project is licensed under the MIT License - see the LICENSE file for details.
Support
For issues and questions:
•	Check the GitHub Issues page
•	Review the API documentation
•	Test with demo data first
•	Verify network connectivity
Version History
•	v1.0: Initial release with core weather functionality
•	v1.1: Added load balancer support and health checks
•	Future: Planned enhancements listed above

