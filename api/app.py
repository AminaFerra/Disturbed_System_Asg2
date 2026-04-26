from fastapi import FastAPI, Request, HTTPException
import jwt, pika, json, socket, os, uuid, asyncpg
from datetime import datetime
from contextlib import asynccontextmanager

app = FastAPI()
SECRET = "supersecret"
INSTANCE_NAME = os.getenv("INSTANCE_NAME", socket.gethostname())
db_pool = None

DB_CONFIG = {
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
    "database": os.getenv("DB_NAME", "audit_logs"),
    "host": os.getenv("DB_HOST", "postgres"),
}

@asynccontextmanager
async def lifespan(app):
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(**DB_CONFIG)
        print(f"[{INSTANCE_NAME}] Database connected")
    except Exception as e:
        print(f"[{INSTANCE_NAME}] Database failed: {e}")
    yield
    if db_pool:
        await db_pool.close()

app = FastAPI(lifespan=lifespan)

def verify_token(request: Request):
    auth = request.headers.get("Authorization")
    if not auth:
        raise HTTPException(403, "Missing token")
    try:
        token = auth.split(" ")[1]
        return jwt.decode(token, SECRET, algorithms=["HS256"])
    except:
        raise HTTPException(403, "Invalid token")

async def log_audit(request_id, service, state, status, source):
    if not db_pool:
        return
    async with db_pool.acquire() as conn:
        await conn.execute("""
            INSERT INTO audit_logs (request_id, service_name, state, status, source, logged_at)
            VALUES ($1, $2, $3, $4, $5, $6)
        """, request_id, service, state, status, source, datetime.now())

@app.get("/task")
async def task(request: Request):
    request_id = str(uuid.uuid4())
    hostname = INSTANCE_NAME
    
    # STATE 1: RECEIVED
    await log_audit(request_id, hostname, "RECEIVED", "success", "client")
    
    # STATE 2: AUTHENTICATED
    try:
        payload = verify_token(request)
        await log_audit(request_id, hostname, "AUTHENTICATED", "success", "client")
    except HTTPException as e:
        await log_audit(request_id, hostname, "FAILED", "failed", "client")
        raise e
    
    # STATE 3: QUEUED
    try:
        connection = pika.BlockingConnection(pika.ConnectionParameters('rabbitmq'))
        channel = connection.channel()
        channel.queue_declare(queue='tasks', durable=True)
        channel.basic_publish(exchange='', routing_key='tasks', 
                            body=json.dumps({"request_id": request_id, "service": payload["service"], "from": hostname}))
        connection.close()
        await log_audit(request_id, hostname, "QUEUED", "success", hostname)
    except Exception as e:
        await log_audit(request_id, hostname, "FAILED", "failed", hostname)
        raise HTTPException(500, f"Queue error: {e}")
    
    return {"status": "task sent", "handled_by": hostname, "request_id": request_id}

@app.get("/health")
async def health():
    return {"status": "healthy", "instance": INSTANCE_NAME}
