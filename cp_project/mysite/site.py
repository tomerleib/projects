# Flask based site for getting counters

from flask import Flask
app = Flask(__name__)

counter = 1

@app.route("/")
def index():
    global counter
    counter += 1
    return "Hello Visitors"

@app.route("/counters")
def counters():
    global counter
    TOTAL = str(counter)
    return "Total visitors:"+ str(counter)


if __name__ == "__main__":
    app.run(host='0.0.0.0',port=8000)
