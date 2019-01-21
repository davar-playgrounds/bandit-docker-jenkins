FROM python:3.6-slim
RUN pip install bandit      && \
    mkdir -p /app_tmp       && \
    chown -R $USER: /app_tmp
RUN chmod +x /app_tmp/.bandit/run_bandit.sh
WORKDIR /app_tmp
CMD ["./app_tmp/.bandit/run_bandit.sh"]