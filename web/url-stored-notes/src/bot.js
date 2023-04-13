// cookie code ripped from ucla's admin bot: https://github.com/uclaacm/lactf-archive
module.exports = async (browser, url) => {
    ctx = await (await browser).createIncognitoBrowserContext();
    const page = await ctx.newPage();
    page.setCookie({
        name: "flag",
        value: process.env.FLAG || "dam{test_flag_not_real_flag_do_not_submit_this_flag}",
        domain: process.env.DOMAIN || "localhost:8080",
        httpOnly: false,
    })
    console.log("[*] Navigating to: ", url);
    await page.setJavaScriptEnabled(true);
    // Debug line below ;P
    // await page.on('console', message => console.log(`${message.type().substr(0, 3).toUpperCase()} ${message.text()}`))
    await page.goto(url, {waitUntil: "domcontentloaded"});
    await page.waitForNetworkIdle({idleTime: 250});
    await page.waitForSelector("#python");
    await page.waitForTimeout(35000);
    console.log("[*] Page loaded");
    await page.close();
    await ctx.close();
    console.log("[*] successfully visited url: ", url)
}