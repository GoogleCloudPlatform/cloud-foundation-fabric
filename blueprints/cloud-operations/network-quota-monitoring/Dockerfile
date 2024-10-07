FROM python:3-slim-bookworm

COPY src /app/
RUN pip install -r /app/requirements.txt
RUN chmod 755 /app/main.py

WORKDIR /app

ENTRYPOINT ["./main.py"]
