# Use the official lightweight Python image.
# https://hub.docker.com/_/python
FROM python:3.10-slim

# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./

# Install dependencies.
RUN pip install --no-cache-dir -r requirements.txt

# Run the web service on container startup.
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "-p", "8080"]