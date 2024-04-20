import pandas as pd
from tqdm import tqdm
from binance.client import Client

client = Client()

info = client.get_exchange_info()
#print(info)

symbols = [x['symbol'] for x in info['symbols']]
print(len(symbols))


exclude = ['UP','DOWN','BEAR','BULL']
non_leverage = [symbol for symbol in symbols if all(excludes not in symbol for excludes in exclude)]
print(len(non_leverage))


relevent = [symbol for symbol in non_leverage if symbol.endswith('USDT')]
print(len(relevent))


klines = {}
for symbol in tqdm(relevent):
    klines[symbol] = client.get_historical_klines(symbol, '1m', '1 hour ago UTC')
print(klines)


returns, symbols = [], []
for symbol in relevent:
    if len(klines[symbol]) > 0:
        cumret = (pd.DataFrame(klines[symbol])[4].astype(float).pct_change()+1).prod()-1
        returns.append(cumret)
        symbols.append(symbol)


retdf = pd.DataFrame(returns, index=symbols, columns=['ret'])
print(retdf)
print(retdf.ret.nlargest(10))