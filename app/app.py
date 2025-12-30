from flask import Flask, jsonify
import os 

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"message" : "Hello from EKS"}), 200

@app.route('/health')
def health():
    return jsonify({"status" : "OK"}), 200  

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8080))
    app.run(host='0.0.0.0', port=port)
