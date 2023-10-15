FROM python:alpine as builder

RUN apk add g++ linux-headers

COPY src /tmp/src/
RUN cd /tmp/src && \
    python3 -m venv venv && \
    VIRTUAL_ENV="/tmp/venv" PATH="/app/venv/bin:$PATH" pip install wheel && \
    VIRTUAL_ENV="/tmp/venv" PATH="/app/venv/bin:$PATH" python setup.py bdist_wheel && \
    mkdir -p /app && \
    cd /app && \
    python3 -m venv venv && \
    VIRTUAL_ENV="/app/venv" PATH="/app/venv/bin:$PATH" pip install /tmp/src/dist/*.whl waitress

FROM python:alpine
RUN apk add dumb-init curl iperf3 apache2-utils bind-tools
COPY --from=builder /app/ /app/
ENV PATH /app/venv/bin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV VIRTUAL_ENV /app/venv
EXPOSE 8080
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/app/venv/bin/waitress-serve", "--call", "nettest:create_app"]
