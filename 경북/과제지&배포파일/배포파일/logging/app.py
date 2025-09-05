import sys
import logging
from flask import Flask, request

app = Flask(__name__)

request_logger = logging.getLogger("request_logger")
request_logger.setLevel(logging.INFO)

handler = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter(
    fmt='%(asctime)s %(clientip)s:%(clientport)s "%(method)s %(path)s" %(statuscode)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
handler.setFormatter(formatter)
request_logger.addHandler(handler)
request_logger.propagate = False

@app.route('/check')
def check():
    return {"data": "hello"}

@app.route('/health')
def health():
    return {"status": "ok"}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)