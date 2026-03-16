import sys
sys.path.append('.')
from app import app

def test_hello():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert "Hello from Jenkins CI/CD on EC2!" in response.data.decode()
