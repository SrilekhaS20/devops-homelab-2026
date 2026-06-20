from flask import Flask
import os, time

app = Flask(__name__)
START = time.time()

@app.route("/")
def home():
    return f"Hello from {os.environ.get('HOSTNAME', 'unknown-pod')}!\n"

@app.route("/healthz")
def healthz():
    return "ok", 200

@app.route("/readyz")
def readyz():
    # simulate slow startup - app isn't ready for first 15s
    if time.time() - START < 15:
        return "not ready", 503
    return "ready", 200

@app.route("/crash")
def crash():
    os._exit(1)  # simulate a crash for CrashLoopBackOff practice

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

