FROM python:3.12-slim
WORKDIR /app
COPY fetch_prices.py fetch_status.py serve_prices.py entrypoint.sh ./
RUN chmod +x entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["./entrypoint.sh"]
