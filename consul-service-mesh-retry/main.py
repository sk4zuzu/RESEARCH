from sanic import Sanic
from sanic.response import json

import os
import aiohttp

app = Sanic(__name__)

@app.listener("before_server_start")
def before_server_start(app, loop):
    app.aiohttp_session = aiohttp.ClientSession(loop=loop)
    app.url = os.getenv("URL", "http://127.0.0.1:8000/200")

@app.listener("after_server_stop")
def after_server_stop(app, loop):
    loop.run_until_complete(app.aiohttp_session.close())
    loop.close()

@app.route("/<status:int>")
async def status(request, status):
    return json({"status": status}, status=status)

@app.route("/")
async def slash(request):
    async with app.aiohttp_session.get(app.url) as response:
        return json(await response.json())

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, workers=1)
