import jwt
import time
import warnings
from jwt import InsecureKeyLengthWarning

warnings.filterwarnings("ignore", category=InsecureKeyLengthWarning)
payload = {
    "service": "api",
    "exp": time.time() + 3600
}

token = jwt.encode(payload, "supersecret", algorithm="HS256")
print(token)
