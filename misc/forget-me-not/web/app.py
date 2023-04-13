#!/usr/bin/env python3

from flask import Flask, render_template, send_from_directory, request, redirect
from questions import questions
import re

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html", invalid=False)

@app.route("/exchange")
def exchange():
    return render_template("exchange.html")

@app.route("/support")
def support():
    return render_template("support.html")

@app.route("/login", methods=['GET', 'POST'])
def login():
    return render_template("login.html", invalid=request.method == 'POST')

def strip_answer(answer):
    # don't care about capitalization or spacing
    return re.sub(r'[^A-Za-z0-9]', '', answer).lower()

def check_answer(attempt, answer_list):
    return strip_answer(attempt) in set(strip_answer(x) for x in answer_list)

@app.route("/forgot_password", methods=['GET', 'POST'])
def show_forgot_password():
    question_data = [{'id': f'question_{i}', 'is_wrong_answer': False, **q} for i, q in enumerate(questions)]
    if request.method == 'POST':
        success = True
        for q in question_data:
            try:
                if not check_answer(request.form[q['id']], q['answers']):
                    q['is_wrong_answer'] = True
                    success = False
                q['attempted_answer'] = request.form[q['id']]
            except KeyError:
                return render_template("borked.html")
        if success:
            with open('flag', 'r') as flag_file:
                return render_template("flag.html", flag=flag_file.read())
    return render_template("forgot_password.html", question_data=question_data)

@app.route('/static/<path:path>')
def send_static(path):
    return send_from_directory('static', path)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
    #serve(app, host='0.0.0.0', port=5000)
