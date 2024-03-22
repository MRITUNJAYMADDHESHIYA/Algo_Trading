#liquidity is one of the best strategy.
#Liquidation HeatMap: In short, it predicts the price levels at which large-scale liquidation events may occur.
#positions are going to be squareoff 

import asyncio
import json
import os
from websockets import connect

websocket_url = 'wss://fstream.binance.com/ws/!forceOrder@arr'
filename = 'binance.csv'  #saving the result

if not os.path.isfile(filename):
    with open(filename, "W") as f:
        f.write(','.join(['symbol','side','order_type','time_in_force','original_quantity',
                          'price','average_price','order_status','order_last_filles_quantity',
                          'order_filled_accumalated_quantity','order_trade_time']) + '\n')
        



async def binance_liqudations(url, filename):
    async for websocket in connect(url):
        try:
            while True:
                msg = await websocket.recv()  #waiting for messege
                print(msg)
                msg = json.loads(msg)['o']  #string to python dic
                msg = [str(x) for x in list(msg.values())]
                with open(filename, 'a') as f:
                    f.write(','.join(msg) + "\n")
        except Exception as e:
            print(e)
            continue

asyncio.run(binance_liqudations(websocket_url, filename))