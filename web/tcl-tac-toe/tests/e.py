#!/usr/bin/env python3
import urllib.parse
import requests
import re

# TODO: Change this
baseurl = 'http://localhost:31337'

javascript = requests.get(f'{baseurl}/index.js').content.decode()

signature = re.match(r'.*?signature = "(.*?)"', javascript, re.DOTALL | re.MULTILINE).groups(1)[0]

board = list('-' for _ in range(9))

def send_post_request(url, data):
    headers = {
        'Referer': f'{baseurl}/',
        'Content-Type': 'application/x-www-form-urlencoded',
    }
    # Use %20 for spaces instead of + when urlencoding because the tcl web server thing doesn't support +
    encoded_data = urllib.parse.urlencode(data, quote_via=urllib.parse.quote)
    return requests.post(url, headers=headers, data=encoded_data)

for move in (
    (0, 'T'),
    (4, 'X'),
    (8, 'X'),
    (0, 'X'),
):
    prev_board = board[:]
    print(repr(' '.join(prev_board)))
    board[move[0]] = move[1]
    print(repr(' '.join(board)))
    res = send_post_request(f'{baseurl}/update_board', data={
        'prev_board': ' '.join(prev_board),
        'new_board': ' '.join(board),
        'signature': signature,
    }).content.decode()

    board_str, signature, message = res.split(',')
    board = board_str.split(' ')

print(message.strip())

