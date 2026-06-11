# python:3.12-slim 은 multi-arch 이미지라 OCI Ampere(ARM64)에서 그대로 동작
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# DB 는 볼륨(/data)에 두어 컨테이너를 다시 만들어도 기록이 보존되게 함
ENV DB_PATH=/data/scores.db
EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
