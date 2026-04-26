import pika, json, time, psycopg2, os
from datetime import datetime

# Database configuration
DB_CONFIG = {
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
    "database": os.getenv("DB_NAME", "audit_logs"),
    "host": os.getenv("DB_HOST", "postgres"),
}

def log_to_db(request_id, state, status="success"):
    """Log to database using psycopg2 (synchronous)"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO audit_logs (request_id, service_name, state, status, source, logged_at) 
               VALUES (%s, %s, %s, %s, %s, %s)""",
            (request_id, "worker", state, status, "rabbitmq", datetime.now())
        )
        conn.commit()
        cur.close()
        conn.close()
        print(f"📝 DB: {state} for {request_id[:8]}")
    except Exception as e:
        print(f"❌ DB Error: {e}")

def callback(ch, method, properties, body):
    data = json.loads(body)
    request_id = data.get('request_id')
    service = data.get('service')
    source = data.get('from')
    
    print(f"\n📨 Received: {request_id[:8]} from {source}")
    
    # STATE 4: CONSUMED
    log_to_db(request_id, "CONSUMED", "success")
    print(f"✅ CONSUMED: {request_id[:8]}")
    
    # Validate service
    if service != 'api':
        # STATE: FAILED
        log_to_db(request_id, "FAILED", "failed")
        print(f"❌ FAILED: Unauthorized service: {service}")
        ch.basic_ack(delivery_tag=method.delivery_tag)
        return
    
    # STATE 5: PROCESSED
    log_to_db(request_id, "PROCESSED", "success")
    print(f"✅ PROCESSED: {request_id[:8]}")
    
    ch.basic_ack(delivery_tag=method.delivery_tag)

print("Worker starting...")
max_retries = 10
for attempt in range(max_retries):
    try:
        connection = pika.BlockingConnection(pika.ConnectionParameters('rabbitmq'))
        channel = connection.channel()
        channel.queue_declare(queue='tasks', durable=True)
        channel.basic_qos(prefetch_count=1)
        channel.basic_consume(queue='tasks', on_message_callback=callback, auto_ack=False)
        print(" [*] Worker started. Waiting for messages...")
        channel.start_consuming()
        break
    except Exception as e:
        print(f"Connection attempt {attempt + 1} failed: {e}")
        time.sleep(3)
