FROM debian:trixie-slim
COPY ./setup.sh /app/
RUN sh -eux /app/setup.sh
COPY ./entrypoint.sh /app/
COPY ./ipsec.sh /app/
COPY ./l2tp.sh /app/
COPY ./proxy.sh /app/
EXPOSE 8118
WORKDIR /app
CMD ["sh", "/app/entrypoint.sh"]
