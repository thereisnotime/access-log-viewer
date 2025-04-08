# Use Node.js as the base image
FROM node:16-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy project files
COPY . .

# Build the app
RUN npm run build

# List contents of docs directory (where Vue is configured to output)
RUN ls -la docs

# Install a simple HTTP server to serve the static content
RUN npm install -g http-server

# Expose port
EXPOSE 8080

# Start the HTTP server
CMD ["http-server", "docs", "-p", "8080"] 