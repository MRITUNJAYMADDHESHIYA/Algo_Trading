import ccxt
import pandas as pd
#   import dontshareconfig
import time
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

##############Inputs################
size = 3
symbol = 'uBTCUSD'
perc_from_lh = .35
close_seconds = 60*47
max_lh = 800
timeframe ='1m'
num_bars = 180
max_risk = 1000
sl_perc = 0.1
exit_perc = 0.002
max_tr = 550
quartile = 0.33
time_limit = 60
sleep = 30

##############################

############Account##########
phemex = ccxt.phemex({
    'enableRateLimit':True,
    'apiKey': '**************************',
    'secret': '****************************************'
})

def get_bid_ask():

    #pull order book for BTC
    btc_phe_book = phemex.fetch_order_book('uBTCUSD')
    #print(btc_phe_book)
    btc_phe_bid = btc_phe_book['bids'][0][0]
    btc_phe_ask = btc_phe_book['asks'][0][0]
    #print(f'best bid for BTC is {btc_phe_bid}')
    #print(f'best ask for BTC is {btc_phe_ask}')

    return btc_phe_ask,btc_phe_bid


##work is remaning in this bot
def bot():

    size_kill() # closes position if ever over max_risk

    df2 = pd.DataFrame() #store our trades
    #df2 = pd.read_csv('')

    now = datetime.now()
    dt_string = now.strftime('%m/%d/%Y %H:%M:%S')
    print(dt_string)
    comptime = int(time.time())
    print(comptime)


    #looking at when the last close was, and making sure we dontover trade
    try:
        last_close_time = df2['close_time'].values[-1]
        last_close_time = int(last_close_time)
        print(last_close_time)

    except:
        print('++++++NOTE: we are fine but we had to go 2 close times ago')
        print('This is not a good fix, need to see what happened with df... maybe letter')
        last_close_time = df2['close_time'].values[-2]
        last_close_time = int(last_close_time)
        print(last_close_time)

    bid_ask = get_bid_ask()
    ask = bid_ask[0]
    bid = bid_ask[1]

    open_pos = open_positions()
    activeorders2 = active_order2()
    print(f'sl_n_close_bool, need_sl, need_close_order, already_limt_to_open: {activeorders2}')

    sl_n_close_bool = activeorders2[0]
    need_sl = activeorders2[1]
    need_close_order = activeorders2[2]
    already_limit_to_open = activeorders2[3]

    bars = phemex,fetch_ohlcv(symbol, timeframe=timeframe, limit=num_bars)
    df = pd.DataFrame(bars[:-1], columns=['timestamp','open','high','low','close','volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')

    frame_data = frame(df)

    low = df['low'].min()
    hi = df['high'].max()
    l2h = hi - low
    avg = (hi + low)/2

    print(f'the low is {low}| the high is {hi} | low to hi: {l2h} | avg price: {avg} | max l2h: {max_lh}')
    
    if l2h > max_lh:
      no_trading = True
      print('No trading cuz l2h')
      kill_switch()
    else:
        no_trading = False
        print('no trading is false')

    df_tolist = df['low'].tolist()
    last17 = df_tolist[-17:]

    for num in last17:
        if low >= num:
            no_trading = True
            print(f'the low is bigger than any of the last N bars so no trading = True low {low}')
        elif hi <= num:
            no_trading = True
            print(f'the hi is less than any of the N bars so no trading = True hi: {hi} num:{num}')
        else:
            print(f'no trading wasnt triggered by the last 17 bars meaning we are not making higher high or lower lows low: {low} hi {hi} num {num}')


