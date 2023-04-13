#!/usr/bin/env python3

from flask import Flask, render_template, send_from_directory, request, redirect
import re

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html", invalid=False)

@app.route("/about")
def about():
    return render_template("about.html")

@app.route("/services")
def services():
    return render_template("services.html")

@app.route('/static/<path:path>')
def send_static(path):
    return send_from_directory('static', path)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5050)
    #serve(app, host='0.0.0.0', port=5000)

