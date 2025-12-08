from flask import Flask
import socket

app = Flask(__name__)

@app.route("/")
def hello():
    # This message proves the app is running inside the container
    hostname = socket.gethostname()
    return f"<h1>Hello from Jenkins Agent!</h1><p>Container ID: {hostname}</p>"

if __name__ == "__main__":
    # Run on port 5000
    app.run(host='0.0.0.0', port=5000)