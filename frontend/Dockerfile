# Use a specific, stable NGINX Alpine image for reproducibility and minimalism.
# Using '1.25.4-alpine' pins to a specific patch version. You could also use
# 'stable-alpine' if you prefer to get minor updates more frequently, but
# '1.25.4-alpine' offers more control over the NGINX version.
FROM nginx:1.29.0-alpine3.22


# Remove default NGINX configuration file. 
RUN rm -f /etc/nginx/conf.d/default.conf


# Copy NGINX configuration file into the container.
COPY frontend/site-nginx.conf /etc/nginx/conf.d/default.conf


WORKDIR /usr/share/nginx/html


# Remove default content from base image's web root.
RUN rm -rf ./* 


# Copy site content into the web root.
COPY frontend/site-files/ /usr/share/nginx/html/


# Set correct ownership for the NGINX user.
# Set appropriate file and directory permissions
# - Directories (type d) get 755: owner has rwx, group/others have rx (execute for traversal).
# - Files (type f) get 644: owner has rw, group/others have r (read-only for serving).
RUN chown -R nginx:nginx . && \
    find . -type d -exec chmod 755 {} \; && \
    find . -type f -exec chmod 644 {} \;


# Expose port 80. Kubernetes Service/Ingress
# will forward external traffic to this port internally.
EXPOSE 80


# "nginx -g 'daemon off;'" runs NGINX in a Docker container
# so it stays in the foreground and Docker can manage its lifecycle.
CMD ["nginx", "-g", "daemon off;"]
