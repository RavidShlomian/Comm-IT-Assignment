# use the official nginx base image
FROM nginx:latest

# remove the default nginx configuration file so it will use the new one i createdd
RUN rm /etc/nginx/conf.d/default.conf

# copy the custom nginx configuration file into the containerSdE
COPY nginx.conf /etc/nginx/nginx.conf

# expose port 80 to access the web server again with corrected it yesd trigger itd afiaefh
EXPOSE 80