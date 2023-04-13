// The greatest express server of all time
// I am such a good web developer.
const express = require('express')
const path = require('path')
const bodyParser = require('body-parser');
const bot = require('./bot.js');
const puppeteer = require('puppeteer');
require('dotenv').config();

const app = express()
const port = 8080
let browser = undefined;

// Set up the middleware
app.use(bodyParser.urlencoded({ extended: false }));

app.use(express.static('static'))

app.get("/edit", (req, res) => {
  res.sendFile(path.join(__dirname, "static", "edit.html"))
})

app.get("/admin", (req, res) => {
  res.sendFile(path.join(__dirname, "static", "admin.html"))
})

function validateURL(url){
  const [origin, data] = url.split("#")
  return origin.startsWith('https://' + process.env.DOMAIN) || origin.startsWith('http://' + process.env.DOMAIN)
}

app.post('/report', (req, res) => {
  const url = req.body.url;
  if (!validateURL(url)){
    res.send("Invalid URL.  Please only report URLs from: "+process.env.DOMAIN)
    return;
  }
  res.send(`Sending admin bot to URL: ${url}`);
  bot(browser, url).catch((err) => {
	console.log("[*] puppeteer errored: ", err);
  });
});

// setup admin-bot stuff:
(async () => {
  browser = await puppeteer.launch({
    executablePath: '/usr/bin/google-chrome',
    args:["--no-sandbox", "--disable-setuid-sandbox", "--enable-experimental-webassembly-features", "--enable-experimental-webassembly-stack-switching", "--enable-webassembly-baseline", "--enable-javascript-harmony", "--enable-future-v8-vm-features"],
    pipe: true
  })
  //browser = await puppeteer.launch({ pipe: true })
  console.log("[*] instantiated puppeteer")
  app.listen(port, () => {
    console.log(`[*] Note sharing app listening on port ${port}`)
  })
})();