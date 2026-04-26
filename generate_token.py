import jwt
import time

payload = {
    "service": "api",
    "exp": time.time() + 3600  # 1 hour expiry
}

token = jwt.encode(payload, "supersecret", algorithm="HS256")

print("Generated JWT Token:")
print(token)
print("\nCopy this token for testing:")
print(f"Bearer {token}")
