FROM nginx:1.29.0-alpine3.22


# Remove default NGINX configuration file. 
RUN rm -f /etc/nginx/conf.d/default.conf


# Copy NGINX configuration file into the container.
COPY nginx.conf /etc/nginx/conf.d/default.conf


WORKDIR /var/www/html


# Remove default content from base image's web root.
RUN rm -rf ./* 


# Copy site content into the web root.
COPY site-files/ /var/www/html


# Set correct ownership, file and directory permissions for the NGINX user.
RUN chown -R nginx:nginx . && \
    find . -type d -exec chmod 755 {} \; && \
    find . -type f -exec chmod 644 {} \;


# Open port 80. 
EXPOSE 80


# Run NGINX in container
CMD ["nginx", "-g", "daemon off;"]
