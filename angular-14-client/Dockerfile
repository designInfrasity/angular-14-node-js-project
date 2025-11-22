# Multi-stage build for Angular 14 client with Node.js 18
# Stage 1: Build the Angular application
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./

# Install dependencies (including devDependencies for build)
RUN npm ci

# Copy application source code
COPY . .

# Build the Angular application for production
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy build artifacts from build stage to nginx html directory
COPY --from=build /app/dist/angular-14-crud-example /usr/share/nginx/html

# Expose port 80 for HTTP traffic
EXPOSE 80

# Start nginx (default command from nginx:alpine base image)
CMD ["nginx", "-g", "daemon off;"]
