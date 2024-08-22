//day.1.Hammer
//day.2.Engulfining
//day.3.StarSignal
//day.4.Buy and sell order

#include<Trade/Trade.mqh>

////////////////////////Inputs///////////////
input bool   IsHammer      = true;
input bool   IsEngulfining = false;
input bool   IsStar        = false;

input double Lots        = 0.1;
input int    TpPoints    = 300;
input int    SlPoints    = 100;
////////////////////////////Global variable//////////
CTrade trade;
int totalBars;


//////////////////////Function////////////////////////
int OnInit(){

    totalBars = iBars(_Symbol,PERIOD_CURRENT);

    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}

void OnTick(){

    int bars = iBars(_Symbol, PERIOD_CURRENT);

    if(totalBars < bars){
        totalBars     = bars;

        double ask     = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        double bid     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        ask            = NormalizeDouble(ask,_Digits);
        bid            = NormalizeDouble(bid, _Digits);

        double tpBuy   = ask + TpPoints * _Point;
        double slBuy   = ask - SlPoints * _Point;
        tpBuy          = NormalizeDouble(tpBuy, _Digits);
        slBuy          = NormalizeDouble(slBuy, _Digits);

        double tpSell  = bid - TpPoints * _Point;
        double slSell  = bid + SlPoints * _Point;
        tpSell         = NormalizeDouble(tpSell, _Digits);
        slSell         = NormalizeDouble(slSell, _Digits);
        


        if(IsHammer){
            int hammerSignal      =  getHammerSignal(0.05,0.7);

            if(hammerSignal > 0){
                Print(__FUNCTION__," > New hammer buy signal...");
                trade.Buy(Lots, _Symbol, ask, slBuy, tpBuy, "Hammer");
            }
            else if(hammerSignal < 0){
                Print(__FUNCTION__," > New hammer sell signal...");
                trade.Sell(Lots, _Symbol, bid, slSell, tpSell, "Hammer");
            }
        }

        if(IsEngulfining){
            int engulfiningSignal =  getEngulfingSignal();

            if(engulfiningSignal > 0){
                Print(__FUNCTION__," > New engulfining buy signal...");
                trade.Buy(Lots, _Symbol, ask, slBuy, tpBuy, "Engulfining");
            }
            else if(engulfiningSignal < 0){
                Print(__FUNCTION__," > New engulfining sell signal...");
                trade.Sell(Lots, _Symbol, bid, slSell, tpSell, "Engulfining");
            }
        }

        if(IsStar){
            int starSignal  =  getStarSignal(0.5);

            if(starSignal > 0){
                Print(__FUNCTION__," > New starSignal buy signal...");
                trade.Buy(Lots, _Symbol, ask, slBuy, tpBuy, "MorningStar");
            }
            else if(starSignal < 0){
                Print(__FUNCTION__," > New starSignal sell signal...");
                trade.Sell(Lots, _Symbol, bid, slSell, tpSell, "EveningStar");
            }
        }
    }
}


///////////////////////Custom Function/////////////////
int getStarSignal(double maxMiddleCandleRatio){
    datetime time = iTime(_Symbol, PERIOD_CURRENT, 1);

    double high1   = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low1    = iLow(_Symbol, PERIOD_CURRENT, 1);
    double open1   = iOpen(_Symbol, PERIOD_CURRENT, 1);
    double close1  = iClose(_Symbol, PERIOD_CURRENT, 1);

    double high2   = iHigh(_Symbol, PERIOD_CURRENT, 2);
    double low2    = iLow(_Symbol, PERIOD_CURRENT, 2);
    double open2   = iOpen(_Symbol, PERIOD_CURRENT, 2);
    double close2  = iClose(_Symbol, PERIOD_CURRENT, 2);

    double high3   = iHigh(_Symbol, PERIOD_CURRENT, 3);
    double low3    = iLow(_Symbol, PERIOD_CURRENT, 3);
    double open3   = iOpen(_Symbol, PERIOD_CURRENT, 3);
    double close3  = iClose(_Symbol, PERIOD_CURRENT, 3);

    double size1   = high1 - low1;
    double size2   = high2 - low2;
    double size3   = high3 - low3;

    //Morning star
    if(open1 < close1 && open3 > close3){
        if(size2 < size1*maxMiddleCandleRatio && size2 < size3*maxMiddleCandleRatio){
            createObj(time,low1,200,1,clrGreen,"Morning star");
            return 1;
        }
    }

    //Evening star
    if(open1 > close1 && open3 < close3){
        if(size2 < size1*maxMiddleCandleRatio && size2 < size3*maxMiddleCandleRatio){
            createObj(time,high1,201,-1,clrRed,"Evening star");
            return -1;
        }
    }
    return 0;
}


int getEngulfingSignal(){
    
    datetime time = iTime(_Symbol, PERIOD_CURRENT, 1);

    double high1   = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low1    = iLow(_Symbol, PERIOD_CURRENT, 1);
    double open1   = iOpen(_Symbol, PERIOD_CURRENT, 1);
    double close1  = iClose(_Symbol, PERIOD_CURRENT, 1);

    double high2   = iHigh(_Symbol, PERIOD_CURRENT, 2);
    double low2    = iLow(_Symbol, PERIOD_CURRENT, 2);
    double open2   = iOpen(_Symbol, PERIOD_CURRENT, 2);
    double close2  = iClose(_Symbol, PERIOD_CURRENT, 2);

    //bullish engulfing formation
    if(open1 < close1 && open2 > close2){
        if(high1 > high2 && low1 < low2){
            if(close1 > open2 && open1 < close2){
                createObj(time,low1,217,1,clrGreen,"Engulfing"); //for arrow search wing
                return 1;
            }
        }
    }

    //bearish engulfing formation
    if(open1 > close1 && open2 < close2){
        if(high1 > high2 && low1 < low2){
            if(close1 < open2 && open1 > close2){
                createObj(time,high1,218,-1,clrRed,"Engulfing");
                return -1;
            }
        }
    }
    return 0;
}


int getHammerSignal(double maxRatioShortShadow, double minRatioLongShadow){

    datetime time = iTime(_Symbol, PERIOD_CURRENT, 1);
    double high   = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low    = iLow(_Symbol, PERIOD_CURRENT, 1);
    double open   = iOpen(_Symbol, PERIOD_CURRENT, 1);
    double close  = iClose(_Symbol, PERIOD_CURRENT, 1);

    double candleSize = high - low;

    //green hammer buy
    if(open < close){
        if(high - close < candleSize*maxRatioShortShadow){
            if(open - low > candleSize*minRatioLongShadow){
                createObj(time,low,233,1,clrGreen,"Hammer");
                return 1;
            }
        }
    }

    //red hammer buy
    if(open > close){
        if(close - low > candleSize*minRatioLongShadow){
            if(high - open < candleSize*maxRatioShortShadow){
                createObj(time,low,233,1,clrGreen,"Hammer");
                return 1;
            }
        }
    }

    //green hammer sell
    if(open < close){
        if(high - close > candleSize*minRatioLongShadow){
            if(open - low < candleSize*maxRatioShortShadow){
                createObj(time,high,234,-1,clrRed,"Hammer");
                return -1;
            }
        }
    }

    //red hammer sell
    if(open > close){
        if(close - low < candleSize*maxRatioShortShadow){
            if(high - open > candleSize*minRatioLongShadow){
                createObj(time,high,234,-1,clrRed,"Hammer");
                return -1;
            }
        }
    }

    return 0;
}


//create an objet for hammer candle (arrow + text)
void createObj(datetime time, double price, int arrowCode, int direction, color clr, string txt){

    string objName = "";
    StringConcatenate(objName,"Signal@",time,"at",DoubleToString(price,_Digits),"(",arrowCode,")");
    if(ObjectCreate(0,objName,OBJ_ARROW,0,time,price)){
        ObjectSetInteger(0,objName,OBJPROP_ARROWCODE,arrowCode);
        ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
        if(direction > 0) ObjectSetInteger(0,objName, OBJPROP_ANCHOR,ANCHOR_TOP);
        if(direction < 0) ObjectSetInteger(0, objName, OBJPROP_ANCHOR,ANCHOR_BOTTOM);
    }
    string objNameDesc = objName+txt;
    if(ObjectCreate(0,objNameDesc,OBJ_TEXT,0,time,price)){
        ObjectSetString(0,objNameDesc,OBJPROP_TEXT," "+txt);
        ObjectSetInteger(0,objNameDesc,OBJPROP_COLOR,clr);
        if(direction > 0) ObjectSetInteger(0,objNameDesc, OBJPROP_ANCHOR,ANCHOR_TOP);
        if(direction < 0) ObjectSetInteger(0, objNameDesc, OBJPROP_ANCHOR,ANCHOR_BOTTOM);
    }
}


