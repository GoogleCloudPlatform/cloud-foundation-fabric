FROM python:3.8-slim

RUN apt-get update && \
    apt-get install -y curl iputils-ping dnsutils iperf3 && \
    rm -rf /var/lib/apt/lists/*

# Copy local code to the container image.
WORKDIR /app
COPY . /app

# Install production dependencies.
RUN pip install -r requirements.txt

# Run the web service on container startup.
CMD streamlit run --server.port 8080 --server.enableCORS false src/nettest/__init__.py