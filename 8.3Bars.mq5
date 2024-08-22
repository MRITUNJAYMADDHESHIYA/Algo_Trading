#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

////////////Inputs///////////
input group "===General==="
static input long  InpMagicnumber = 52545;  //magic number
static input double InpLotSize    = 0.01;   //lot size

input group "=== Trading ==="
input ENUM_TIMEFRAMES  InpTimeframe    = PERIOD_M5;  //timeframe
input int              InpStreak       = 3;          //candle streak
input int              InpSizeFilter   = 0;          //size filter in points(0=off)
input int              InpStoploss     = 200;        //stoploss in points
input int              InpTakeprofit   = 500;          //take profit in points
input int              InpTimeExitHour = 22;         //time exit hour(-1=off)




///////////////Global Variabel//////////////
MqlTick tick;
CTrade trade;
CPositionInfo position;



int OnInit(){

    //check all the inputs
    if(!CheckInputs()){return INIT_PARAMETERS_INCORRECT;}

    //magic number to trade object
    trade.SetExpertMagicNumber(InpMagicnumber);

    return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason){
}


void OnTick(){
    //check if current tick is a bar open tick
    if(!IsNewBar()){return;}

    //get current tick
    if(!SymbolInfoTick(_Symbol,tick)){
        Print("Fails to get current tick");
        return;
    }

    //count open position
    int cntBuy = 0, cntSell = 0;
    CountPositions(cntBuy, cntSell);

    //check for new buy position
    if(cntBuy == 0 && CheckBars(true)){

        //sl and tp
        double sl = InpStoploss == 0 ? 0:tick.bid - InpStoploss * _Point;
        double tp = InpTakeprofit == 0 ? 0:tick.bid + InpTakeprofit * _Point;

        //normalization
        if(!NormalizePrice(sl)){return;}
        if(!NormalizePrice(tp)){return;}

        //open buy position
        trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLotSize,tick.ask,sl,tp,"StreakEA");
    }


    //check for new sell position
    if(cntSell == 0 && CheckBars(false)){

        //sl and tp
        double sl = InpStoploss == 0 ? 0:tick.ask + InpStoploss * _Point;
        double tp = InpTakeprofit == 0 ? 0:tick.ask - InpTakeprofit * _Point;

        //normalization
        if(!NormalizePrice(sl)){return;}
        if(!NormalizePrice(tp)){return;}

        //open buy position
        trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLotSize,tick.bid,sl,tp,"StreakEA");
    }


    //check for time exit
    MqlDateTime dt;
    TimeCurrent(dt);
    if(dt.hour == InpTimeExitHour && dt.min<3){
        ClosePositions(true); //for buy
        ClosePositions(false); //for sell
    }
}


/////////Custom function//////////////////
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
    if(InpStoploss < 0){
        Alert("Wrong input: stop loss < 0");
        return false;
    }
    if(InpTakeprofit < 0){
        Alert("Wrong input: take profit < 0");
        return false;
    }
    if(InpTimeExitHour < -1 || InpTimeExitHour > 23){
        Alert("Wrong input: time exit < -1 or time exit > 23");
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


//count open position
void CountPositions(int &cntBuy, int &cntSell){

    cntBuy  = 0;
    cntSell = 0;
    int total = PositionsTotal();
    for(int i=total-1; i>=0; i--){
        position.SelectByIndex(i);
        if(position.Magic()==InpMagicnumber){
            if(position.PositionType()==POSITION_TYPE_BUY){cntBuy++;}
            if(position.PositionType()==POSITION_TYPE_SELL){cntSell++;}
        }
    }
}


//check bars
bool CheckBars(bool buy_sell){

    //get bars
    MqlRates rates[];
    ArraySetAsSeries(rates,true);
    if(!CopyRates(_Symbol,InpTimeframe, 0, InpStreak+1, rates)){
        Print("Failed to get rates"); 
        return false;
    }

    //check condition
    for(int i=InpStreak; i>0; i--){
        bool isGreen = rates[i].open <= rates[i].close;
        double size  = MathAbs(rates[i].open - rates[i].close);
        if(buy_sell && (!isGreen || (InpSizeFilter>0 && size < InpSizeFilter*_Point))){
            return false;
        }
        if(!buy_sell && (isGreen || (InpSizeFilter>0 && size < InpSizeFilter*_Point))){
            return false;
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


//close position, true for buy/false fot sell
void ClosePositions(bool buy_sell){

    int total = PositionsTotal();
    for(int i=total-1; i>=0; i--){
        position.SelectByIndex(i);
        if(position.Magic()==InpMagicnumber){
            if(buy_sell && position.PositionType()==POSITION_TYPE_SELL){continue;}
            if(!buy_sell && position.PositionType()==POSITION_TYPE_BUY){continue;}
            trade.PositionClose(position.Ticket());
        }
    }
}


