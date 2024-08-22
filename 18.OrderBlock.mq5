


#include<Trade/Trade.mqh>
#include<Trade/PositionInfo.mqh>

/////////////////////Inputs//////////////////////////////////
input group " ==== General ==== "
static input long       InpMagicnumber     = 251516;        //magic number
static input double     InpLotSize         = 0.01;          //lot size
input group " ==== Trading ==== "
input ENUM_TIMEFRAMES   InpTimeframe       = PERIOD_M5;     //time frame
input int               InpStreak          = 3;             //canlde streak
input int               InpSizeFilter      = 0;             //size filter in points(0=off)
input int               InpTakeProfit      = 400;           //take profit in points
input int               InpStopLoss        = 200;           //stop loss in points
input group " ==== Trailing SL/closeSignal ==== " 
input bool              InpTrailingSL      = true;          //trailing sl(off = false)
input bool              InpCloseSignal     = true;          //close trade by opposition signal(off = false)

////////////////////////Global variable///////////////////////
CTrade trade;
MqlTick currentTick, previousTick;
CPositionInfo position;

///////////////////////////Function////////////////////////////
int OnInit(){

    /////////////check inputs//////////////////////
    if(!CheckInputs()){return INIT_PARAMETERS_INCORRECT;}

    //////////////////set magic number//////////////
    trade.SetExpertMagicNumber(InpMagicnumber);

    return(INIT_SUCCEEDED);
}


void Deinit(const int reason){
}


void OnTick(){

    //check current tick is a bar open tick
    if(!IsNewBar()){return;} 

    //get current tick(returns current prices of a specified symbol in a variable of the MqlTick type.)
    if(!SymbolInfoTick(_Symbol,currentTick)){
        Print("Fails to get current tick");
        return;
    }

    //count open position
    int cntBuy = 0, cntSell = 0;
    if(!CountOpenPositions(cntBuy,cntSell)){
        Print("Failed to count position");
        return;
    }

    //check for new buy position
    if(cntBuy == 0 && CheckCondition(true)){
        Print("Buy position");

        ///close the opposite position
        //if(InpCloseSignal){if(!ClosePositions(2)){return;}}  ///close sell = 2

        //sl and tp
        double sl = InpStopLoss == 0 ? 0:currentTick.bid - InpStopLoss * _Point;
        double tp = InpTakeProfit == 0 ? 0:currentTick.bid + InpTakeProfit * _Point;

        //normalization
        if(!NormalizePrice(sl)){return;}
        if(!NormalizePrice(tp)){return;}

        //open buy position
        trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, currentTick.ask, sl, tp, "Order Block");
    }


    //check for new sell position
    if(cntSell == 0 && CheckCondition(false)){
        Print("Sell position");

        ///close the opposite position
        //if(InpCloseSignal){if(!ClosePositions(1)){return;}}  ///close buy = 1

        //sl and tp
        double sl = InpStopLoss == 0 ? 0:currentTick.ask + InpStopLoss * _Point;
        double tp = InpTakeProfit == 0 ? 0:currentTick.ask - InpTakeProfit * _Point;

        //normalization
        if(!NormalizePrice(sl)){return;}
        if(!NormalizePrice(tp)){return;}

        //open buy position
        trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLotSize, currentTick.bid, sl, tp, "StreakEA");
    }

    //update stoploss
    if(InpStopLoss>0 && InpTrailingSL){
        UpdateStopLoss(InpStopLoss*_Point);
    }

}


///////////////////////////Custom function//////////////////
bool CheckInputs(){
    if(InpMagicnumber <= 0){
        Alert("Wrong input: magic number <= 0");
        return false;
    }
    if(InpLotSize <= 0){
        Alert("Wrong input: lot size <= 0");
        return false;
    }
    if(InpTimeframe == PERIOD_CURRENT){
        Alert("Wrong input: time frame can't be current period");
        return false;
    }
    if(InpStreak <= 0){
        Alert("Wrong input: streak <= 0");
        return false;
    }
    if(InpSizeFilter < 0){
        Alert("Wrong input: size filter < 0");
        return false;
    }
    if(InpStopLoss < 0){
        Alert("Wrong input: stop loss < 0");
        return false;
    }
    if(InpTakeProfit < 0){
        Alert("Wrong input: take profit < 0");
        return false;
    }

    return true;
}


//check if we have a new bar open tick
bool IsNewBar(){

    static datetime previousTime = 0;
    datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(previousTime != currentTime){
        previousTime = currentTime;
        return true;
    }
    return false;
}

///////////////////////Count Open position///////////////////////////
bool CountOpenPositions(int &cntBuy, int &cntSell){

    cntBuy  = 0;
    cntSell = 0;
    int total = PositionsTotal();
    for(int i=total-1; i>=0; i--){
        ulong ticket = PositionGetTicket(i);
        if(ticket < 0){Print("Failed to get position ticket"); return false;}
        if(!PositionSelectByTicket(ticket)){Print("Failed to select position"); return false;}
        long magic;
        if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position magicnumber"); return false;}

        if(magic == InpMagicnumber){
            long type;
            if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type"); return false;}
            if(type==POSITION_TYPE_BUY){cntBuy++;}
            if(type==POSITION_TYPE_SELL){cntSell++;}
        }
    }
    return true;
}


//Normalization of price(sl/tp)
bool NormalizePrice(double &price){

    double tickSize = 0;
    if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize)){
        Print("Failed to get tick size");
        return false;
    }
    price = NormalizeDouble((price/tickSize)*tickSize, _Digits);

    return true;
}


//////////////////Condition for buy and sell////////////////////
bool CheckCondition(bool buy_sell){

    datetime time = iTime(_Symbol, PERIOD_M5, 1);

    double high1   = iHigh(_Symbol, PERIOD_M5, 1);
    double low1    = iLow(_Symbol, PERIOD_M5, 1);
    double open1   = iOpen(_Symbol, PERIOD_M5, 1);
    double close1  = iClose(_Symbol, PERIOD_M5, 1);

    double high2   = iHigh(_Symbol, PERIOD_M5, 2);
    double low2    = iLow(_Symbol, PERIOD_M5, 2);
    double open2   = iOpen(_Symbol, PERIOD_M5, 2);
    double close2  = iClose(_Symbol, PERIOD_M5, 2);

    double high3   = iHigh(_Symbol, PERIOD_M5, 3);
    double low3   = iLow(_Symbol, PERIOD_M5, 3);
    double open3   = iOpen(_Symbol, PERIOD_M5, 3);
    double close3  = iClose(_Symbol, PERIOD_M5, 3);

    double high4   = iHigh(_Symbol, PERIOD_M5, 4);
    double low4   = iLow(_Symbol, PERIOD_M5, 4);
    double open4   = iOpen(_Symbol, PERIOD_M5, 4);
    double close4  = iClose(_Symbol, PERIOD_M5, 4);

    // Bullish 
    if (buy_sell) {
        if(close4 < open4 && close3 < open3 && close2 > open2 && close1 > open1){
            if ( close2 > high3 && close3 < low4 && low1 > high3) {
                return true;
            }
        }
    }
    // Bearish
    else {
        if(close4 > open4 && close3 > open3 && close2 < open2 && open1 > close1){
            if (high4 < close3 && close2 < low3 && high1 < low2) {
                return true;
            }
        }
    }


    return false;
}


///////////////////////close position///////////////////////////
bool ClosePositions(int all_buy_sell){

    int total = PositionsTotal();
    for(int i=total-1; i>=0; i--){
        ulong ticket = PositionGetTicket(i);
        if(ticket < 0){Print("Failed to get position ticket"); return false;}
        if(!PositionSelectByTicket(ticket)){Print("Failed to select position"); return false;}
        long magic;
        if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position magicnumber"); return false;}

        if(magic == InpMagicnumber){
            long type;
            if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type"); return false;}
            if(all_buy_sell == 1 && type == POSITION_TYPE_SELL){continue;}
            if(all_buy_sell == 0 && type == POSITION_TYPE_BUY){continue;}
            trade.PositionClose(ticket);
            if(trade.ResultRetcode()!=TRADE_RETCODE_DONE){
                Print("Failed to close position ticket:",
                        (string)ticket," result:",(string)trade.ResultRetcode(),":",trade.CheckResultRetcodeDescription());
            }
        }
    }
    return true;
}


/////////Trailing stoploss//////////////////
void UpdateStopLoss(double slDistance){

    //open position
    int total = PositionsTotal();
    for(int i=total-1; i>=0; i--){
        ulong ticket = PositionGetTicket(i);
        if(ticket<=0){Print("Failed to get position ticket"); return;}
        if(!PositionSelectByTicket(ticket)){Print("Failed to select position by ticket"); return;}
        ulong magicnumber;
        if(!PositionGetInteger(POSITION_MAGIC,magicnumber)){Print("Failed to get position magicnumber"); return;}
        if(InpMagicnumber == magicnumber){

            //get type
            long type;
            if(!PositionGetInteger(POSITION_TYPE, type)){Print("Failed to get position type"); return;}
            //get current sl/tp
            double currSL, currTP;
            if(!PositionGetDouble(POSITION_SL,currSL)){Print("Failed to get  position stop loss"); return;}
            if(!PositionGetDouble(POSITION_TP,currTP)){Print("Failed to get position take profit"); return;}

            //calculate stop loss
            double currPrice = type==POSITION_TYPE_BUY ? currentTick.bid : currentTick.ask;
            int n            = type==POSITION_TYPE_BUY ? 1 : -1;
            double newSL     = currPrice - slDistance*n;
            if(!NormalizePrice(newSL)){return;}

            //check if new stoploss is closer to current price than existing stop loss
            if((newSL*n) < (currSL*n) || NormalizeDouble(MathAbs(newSL - currSL),_Digits) < _Point){
                //Print("No new stoploss needed")
                continue;
            }

            //modify position with new stoploss
            if(!trade.PositionModify(ticket,newSL,currTP)){
                Print("Failed to modify position, ticket:",(string)ticket," currSL:",(string)currSL,
                                                            "newSL:",(string)newSL,"currTP:",(string)currTP);
                return;       
            }

        }
    }
}