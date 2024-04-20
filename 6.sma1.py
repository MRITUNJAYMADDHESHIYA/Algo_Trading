#sma7>sma25 then buy
#sma7<sma25 then sell


import pandas as pd
import numpy as np
import asyncio
from binance import BinanceSocketManager
from binance.client import Client

api_key = '**********************************************'
api_secret = '888888888888888888**********************'

client = Client(api_key, api_secret)


st = 7
lt = 25
def gethistoricals(symbol, lt):
    df = pd.DataFrame(client.get_historical_klines(symbol, '1d', str(lt) + 'days ago UTC', '1 day ago UTC'))

    closes = pd.DataFrame(df[4])  #4th column close price
    closes.columns = ['Close']
    closes['st'] = closes.Close.rolling(st-1).sum()
    closes['lt'] = closes.Close.rolling(lt-1).sum()
    closes.dropna(inplace=True)
    return closes

historicals = gethistoricals('BTCUSDT',lt)
print(historicals)


def liveSMA(hist, live):
    liveST = (hist['st'].values + live.Price.values)/ st
    liveLT = (hist['lt'].values + live.Price.values)/ lt

    return liveST, liveLT


#msg from binance into reade-able data
def createframe(msg):
    df = pd.DataFrame([msg])
    df = df.loc[:,['s','E','p']]

    df.columns = ['symbol','Time','Price']
    df.Price = df.Price.astype(float)
    df.Time = pd.to_datetime(df.Time, unit='ms')
    return df

async def main(coin, qty, SL_limit, open_position = False):
    bm = BinanceSocketManager(client)
    ts = bm.trade_socket(coin)

    async with ts as tscm:
        while True:
            res = await tscm.recv() #recive the messege
            if res:
                frame = createframe(res)
                print(frame)
                liveST, liveLT = liveSMA(historicals, frame)


                #place the order
                if liveST > liveLT and not open_position:
                    order = client.create_order(symbol = coin, side='BUY', type='MARKET', quantity=qty)

                    print(order)
                    buyprice = float(order['fills'][0]['price'])  #the order response and converts it to a floating-point number. It seems to be assigning the buy price to the variable buyprice.
                    open_position = True


                #if there is an open position then we have to sell at specifit target or sl
                if open_position:
                    if frame.Price[0] < buyprice * SL_limit or frame.Price[0] > 1.02*buyprice:
                        order = client.create_order(symbol=coin, side='SELL', type='MARKET', quantity=qty)
                        print(order)
                        loop.stop()


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main('BTCUSDT', 0.05, 0.98))



