import ccxt
from datetime import datetime
import time

phemex = ccxt.phemex({
    #binance
    # 'apiKey' : 'bcLgJpnXG1NKtwjUhgzSdJUNI5cElC4qh2jWZfdVsmVNiyUNoKV7RoQlvegcJtt3',
    # 'secret' : 'voDsh2xPby6KxXzNpnPao9yAPPIAnAqldPXmdl3sgssNTu26xunLpQI8z1AqCpm3'
    #delta
    'apiKey' : '**********************',
    'secret' : '*********************88'
})

symbol = 'BTCUSDT'
size = 1
go = True
sleep = 10

def get_bid_ask():
    book = phemex.fetch_order_book(symbol)

    bid = book['bids'][0][0]
    ask = book['asks'][0][0]

    print(f'best bid for {symbol} is {bid}')
    print(f'best ask for {symbol} is {ask}')

    return ask, bid

while go == True:

    bid = get_bid_ask()[1]
    ask = get_bid_ask()[0]
    print(bid)

    lowbid = bid  - 20

    #create the order
    phemex.create_limit_buy_order(symbol, size, lowbid)

    print(f'just made an order now sleeping for {sleep} seconds')

    time.sleep(sleep)