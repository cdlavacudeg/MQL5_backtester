//+------------------------------------------------------------------+
//|                                  StrategyTesterPracticeTrade.mq5 |          
//|                                Copyright 2015, SearchSurf (RmDj) |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2015, SearchSurf (RmDj)"
#property link        "https://www.mql5.com"
#property version     "1.00"
#property description "This EA is for MT5 and it is  mainly used to Practice Trade on Strategy Tester only."
#property description "The manual command is taken from the existance of a text file in the MT5's COMMON/FILE Folder."
#property description "Command text file as follows: 'buy.txt', 'sell.txt', or 'close.txt', only one must appear each time on the folder."
#include <Trade\Trade.mqh>


/*
 NOTE:  (Please read, this is important!!!)
- In order for this EA to use its function on the strategy tester, a textfile command outside MT5's processing is needed for the manual order execution.
- The EA will take the "buy/sell/close" order command mainly on the existance of certain files as "buy.txt", "sell.txt", or "close.txt" at the MT5's COMMON file folder.
  (The text file doesn't need anything on it, it's the presence of the filename that matters.)
- Only one file must exist on the said folder at each command, otherwise, the EA will execute the first one it reads and deletes the file/files.
*/

// Global Variables
input double DLot=1;    // Lot Size:
input double stop_L=1;  //Stop Loss
input double profit_L=1; //Take Profit
input double Limit_off=1; //Offset orden tipo limit
int          Arun_error;   // Any error encountered during run
double       JustifySize;  // Justify lotsize between buy/sell and close
int          Ax,Ay,live;   // Axis X, Axis Y on graph,live=0 or test=1
double       OpenProfit;   // Open position profit






//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Arun_error=0;
   OpenProfit=0;
   live=1;

   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,0,1);//Activa los eventos de dezplazamiento del mouse
   
// Profit
   ObjectCreate(0,"LABEL1",OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"LABEL1",OBJPROP_XDISTANCE,40);
   ObjectSetInteger(0,"LABEL1",OBJPROP_YDISTANCE,102);
   ObjectSetInteger(0,"LABEL1",OBJPROP_FONTSIZE,12);
   ObjectSetInteger(0,"LABEL1",OBJPROP_COLOR,clrRed);

// Equity 
   ObjectCreate(0,"LABEL2",OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"LABEL2",OBJPROP_XDISTANCE,50);
   ObjectSetInteger(0,"LABEL2",OBJPROP_YDISTANCE,75);
   ObjectSetInteger(0,"LABEL2",OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,"LABEL2",OBJPROP_COLOR,clrRed);

 
 //Botones
   func_button_create(0,"Buy",50,30);
   func_button_create(0,"Sell",100,30);
   func_button_create(0,"Close",150,30);
   func_button_create(0,"Buy_L",50,55);
   func_button_create(0,"Sell_L",100,55);
   func_button_create(0,"Cancel",150,55);
   func_button_create(0,"TP+",200,30);
   func_button_create(0,"SL+",250,30);
   func_button_create(0,"TP-",200,55);
   func_button_create(0,"SL-",250,55);

   ChartRedraw();
   
  
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Se Borran los objetos
   ObjectDelete(0,"LABEL");
   ObjectDelete(0,"LABEL1");
   ObjectDelete(0,"LABEL2");
   ObjectDelete(0,"Buy");
   ObjectDelete(0,"Sell");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---  
   Comment("Hora: ",TimeCurrent());
   
   //string candle;
   double CurP; //Variable para almacenar precio actual

   JustifySize=DLot; //Cantidad de contratos/lotes

   if(Arun_error>0)// si se detecta error
     {
      Alert("EA detected error: ",Arun_error," -- EA Aborted!!! Pls. close EA now and attend to your open entry/ies.");
      Print("EA detected error: ",Arun_error," -- EA Aborted!!! Pls. close EA now and attend to your open entry/ies.");
      if(!ObjectFind(0,"LABEL")) ObjectDelete(0,"LABEL");
      ObjectCreate(0,"LABEL",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"LABEL",OBJPROP_XDISTANCE,270);
      ObjectSetInteger(0,"LABEL",OBJPROP_YDISTANCE,40);
      ObjectSetInteger(0,"LABEL",OBJPROP_XSIZE,370);
      ObjectSetInteger(0,"LABEL",OBJPROP_YSIZE,30);
      ObjectSetInteger(0,"LABEL",OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,"LABEL",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"LABEL",OBJPROP_BGCOLOR,clrCyan);
      ObjectSetString(0,"LABEL",OBJPROP_TEXT,"Error: EA aborted, please close or restart.");
      ChartRedraw();
      return;
     }

// If there's an open position, display the Profit every tick change.
   if(OpenPosition()=="none") OpenProfit=0;
   else
     {
      PositionSelect(_Symbol);
      OpenProfit=NormalizeDouble(PositionGetDouble(POSITION_PROFIT),2);
     }
   ChartTimePriceToXY(0,0,StringToTime(GetBarDetails("time",3,0)),GetBarPrice("close",3,0),Ax,Ay);
   ObjectSetInteger(0,"LABEL1",OBJPROP_XDISTANCE,Ax);
   ObjectSetInteger(0,"LABEL1",OBJPROP_YDISTANCE,Ay);
   ObjectSetString(0,"LABEL1",OBJPROP_TEXT,"  Profit: "+DoubleToString(OpenProfit,2));
   ObjectSetString(0,"LABEL2",OBJPROP_TEXT,"EQUITY: "+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));

   ChartRedraw();

   CurP=NormalizeDouble(GetBarPrice("close",3,0),_Digits);

// %%%%%%%%%  Below codes will keep checking at every tick for a specific command with the buttons %%%%%%%%%%%%%%%%%
   CheckButtons(CurP,JustifySize);
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
  
 
//---
   if(live==1)
     {
      // Remarks:
      ObjectCreate(0,"LABEL",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"LABEL",OBJPROP_XDISTANCE,270);
      ObjectSetInteger(0,"LABEL",OBJPROP_YDISTANCE,40);
      ObjectSetInteger(0,"LABEL",OBJPROP_XSIZE,370);
      ObjectSetInteger(0,"LABEL",OBJPROP_YSIZE,30);
      ObjectSetInteger(0,"LABEL",OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,"LABEL",OBJPROP_COLOR,clrBlack);
      ObjectSetInteger(0,"LABEL",OBJPROP_BGCOLOR,clrCyan);
      ObjectSetString(0,"LABEL",OBJPROP_TEXT,"NOTE: This EA is for Practice Trade on Strategy Tester only!!!");
      ChartRedraw();
      live=0;
     }
  }
//+------------------------------------------------------------------+
//|    Candle Bar Details                                            |
//+------------------------------------------------------------------+
//entry- (datetime) "time", (long) "tickVOL", (int) "spread", (long) "realVOL", maxbar- number of bars to initiate, bar- at which bar to get details
//entry- (datetime)  "lasttime", (ulong) "lastVOL", (long in millisec) "lastupdate", (uint) "TICKflag"  === all for latest only... 
string GetBarDetails(string entry,int maxbar,int bar) // bars based on the current (present) occurance of point of time.
  {
   string bardetails;

   MqlTick latestP;
   MqlRates BarRates[];

   ArraySetAsSeries(BarRates,true);

//--- last price quote:
   if(!SymbolInfoTick(_Symbol,latestP))
     {
      Alert("Error getting the latest price quote - error:1002");
      Arun_error=1002;
      return("error");
     }

//--- Get the details of the latest maxbars bars
   if(CopyRates(_Symbol,_Period,0,maxbar,BarRates)<0)
     {
      Alert("Error copying rates/history data - error:1002");
      Arun_error=1002;
      return("error");
     }

   if(entry=="time") bardetails=TimeToString(BarRates[bar].time);                 // datetime
   if(entry=="tickVOL") bardetails=IntegerToString(BarRates[bar].tick_volume);    // long ... 
   if(entry=="spread") bardetails=IntegerToString(BarRates[bar].spread);          // int
   if(entry=="realVOL") bardetails=TimeToString(BarRates[bar].real_volume);       // datetime

   if(entry=="lasttime") bardetails=TimeToString(latestP.time);                   // datetime
   if(entry=="lastVOL") bardetails=IntegerToString(latestP.volume);               // ulong 
   if(entry=="lastupdate") bardetails=IntegerToString(latestP.time_msc);          // long in milliseconds
   if(entry=="lastTickflag") bardetails=TimeToString(latestP.flags);              // uint

   return(bardetails);  // ...don't forget to convert the returned string result value to its designated data type.
  }
//+------------------------------------------------------------------+
//|    Candle Bar Prices                                             |
//+------------------------------------------------------------------+
//entry- open,high,low,close,bid,ask,last, maxbar- number of bars to initiate, bar- at which bar to get price
double GetBarPrice(string price,int maxbar,int bar)
  {
   double barprice=0;

   MqlTick latestP;
   MqlRates BarRates[];

   ArraySetAsSeries(BarRates,true);

//--- last price quote:
   if(!SymbolInfoTick(_Symbol,latestP))
     {
      Alert("Error getting the latest price quote - error:1003");
      Arun_error=1003;
      return(0);
     }

//--- price details of the latest maxbar bars:
   if(CopyRates(_Symbol,_Period,0,maxbar,BarRates)<0)
     {
      Alert("Error copying rates/history data - error:1003");
      Arun_error=1003;
      return(0);
     }

// for Previous completed bar, where 0-last current one in progress. 
   if(price=="open") barprice=BarRates[bar].open;
   if(price=="close") barprice=BarRates[bar].close; // if bar=0 , its close price is same as current price bid
   if(price=="high") barprice=BarRates[bar].high;
   if(price=="low") barprice=BarRates[bar].low;

// for Current Bar in Progress:
   if(price=="bid") barprice=latestP.bid;
   if(price=="ask") barprice=latestP.ask;
   if(price=="last") barprice=latestP.last;

   return(barprice);
  }
//+------------------------------------+
//| Execute TRADE                      |
//+------------------------------------+  
bool ExecuteTrade(string Entry,double ThePrice,double lot, string entry_type) // Entry = buy or sell / returns true if successfull.
  {
   bool success;

   success=true;
   

   MqlTradeRequest mreq; // for trade send request.
   MqlTradeResult mresu; // get trade result.
   ZeroMemory(mreq); // Initialize trade send request.

   Print("Order Initialized");
 
   
   if(entry_type=="market")
   {
   mreq.action = TRADE_ACTION_DEAL;                                   // immediate order execution
   if(Entry=="buy") mreq.price = NormalizeDouble(ThePrice,_Digits);   // should be latest bid price
   if(Entry=="sell") mreq.price = NormalizeDouble(ThePrice,_Digits);  // should be latest ask price
   mreq.symbol = _Symbol;                                             // currency pair
   mreq.volume = lot;                                                 // number of lots to trade
   mreq.magic = 11119;                                                // Order Magic Number
   if(Entry=="sell") {
   mreq.type = ORDER_TYPE_SELL;
   mreq.sl = NormalizeDouble(ThePrice+stop_L,_Digits);
   mreq.tp = NormalizeDouble(ThePrice-profit_L+0.25,_Digits);}               // Sell Order
   
   if(Entry=="buy") {
   mreq.type = ORDER_TYPE_BUY;
   mreq.tp = NormalizeDouble(ThePrice+profit_L,_Digits);
   mreq.sl = NormalizeDouble(ThePrice-stop_L+0.25,_Digits);
   }                       // Buy Order
   mreq.type_filling = ORDER_FILLING_FOK;                             // Order execution type
   mreq.deviation=100;                                               // Deviation from current price
   }
   
   if(entry_type=="limit")
   {
   mreq.action = TRADE_ACTION_PENDING;                                   // immediate order execution
   if(Entry=="buy") mreq.price = NormalizeDouble(ThePrice-Limit_off,_Digits);   // should be latest bid price
   if(Entry=="sell") mreq.price = NormalizeDouble(ThePrice+Limit_off,_Digits);  // should be latest ask price
   mreq.symbol = _Symbol;                                             // currency pair
   mreq.volume = lot;                                                 // number of lots to trade
   mreq.magic = 11119;                                                // Order Magic Number
   if(Entry=="sell") {
   mreq.type = ORDER_TYPE_SELL_LIMIT;
   mreq.sl = NormalizeDouble(ThePrice+Limit_off+stop_L,_Digits);
   mreq.tp = NormalizeDouble(ThePrice+Limit_off-profit_L+0.25,_Digits);}               // Sell Order
   
   if(Entry=="buy") {
   mreq.type = ORDER_TYPE_BUY_LIMIT;
   mreq.tp = NormalizeDouble(ThePrice-Limit_off+profit_L-0.25,_Digits);
   mreq.sl = NormalizeDouble(ThePrice-Limit_off-stop_L,_Digits);
   } 
   mreq.type_filling = ORDER_FILLING_FOK;                             // Order execution type
   mreq.deviation=100;                                               // Deviation from current price 
   }
   
                                 
//--- send order
   if(!OrderSend(mreq,mresu))
     {
      Alert("Order Not Sent: ",GetLastError());
      ResetLastError();
      success=false;
     }

// Result code
   if(mresu.retcode==10009 || mresu.retcode==10008) //Request is completed or order placed       
     {
      if(Entry=="SELL") Print("A Sell order has been successfully placed with Ticket#:",mresu.order,"!!");
      if(Entry=="BUY") Print("A Buy order has been successfully placed with Ticket#:",mresu.order,"!!");
     }
   else
     {
      Alert("The Order not completed -error:",GetLastError());
      ResetLastError();
      success=false;
     }

   if(success==false)
     {
      Alert("Error ORDER FAILED!!! - error:1004");
      //Arun_error=1004;
     }
   return(success);
  }
//+------------------------------------+
//|  Check if there's an open position | 
//+------------------------------------+ 
string OpenPosition() // Returns "none", "buy", "sell"
  {
   string post;//variable para guardar posición

   post="none";

   if(PositionSelect(_Symbol)==true) // open position 
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         post="buy";
        }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         post="sell";
        }
     }

   return(post);
  }
//+------------------------------------------------------------------+
//|Funcion para chequeo de Click en botones                          |
//+------------------------------------------------------------------+

  
void CheckButtons(double CurPo,double Size)
{
   if( bool( ObjectGetInteger( 0, "Buy", OBJPROP_STATE ) ) )
      {
         Print( " Compra Iniciada" );
         if(ExecuteTrade("buy",CurPo,Size,"market"))
         {
         ObjectSetInteger( 0, "Buy", OBJPROP_STATE, false );
         }
         
      }
      
   if( bool( ObjectGetInteger( 0, "Sell", OBJPROP_STATE ) ) )
      {
         Print( " Venta Iniciada" );
         if(ExecuteTrade("sell",CurPo,Size,"market"))
         {
         ObjectSetInteger( 0, "Sell", OBJPROP_STATE, false );
         }
      }
   
   if(bool( ObjectGetInteger( 0, "Close", OBJPROP_STATE ) ))
     {
        Print( " Cierre de Posición" );
        if(OpenPosition()=="buy")
        {
         PositionSelect(_Symbol);
         Size=NormalizeDouble(PositionGetDouble(POSITION_VOLUME),2);
         ExecuteTrade("sell",CurPo,Size,"market");
         ObjectSetInteger( 0, "Close", OBJPROP_STATE, false );
         
        }

      if(OpenPosition()=="sell")
        {
         PositionSelect(_Symbol);
         Size=NormalizeDouble(PositionGetDouble(POSITION_VOLUME),2);
         ExecuteTrade("buy",CurPo,Size,"market");
         ObjectSetInteger( 0, "Close", OBJPROP_STATE, false );
         
        }
         ObjectSetInteger( 0, "Close", OBJPROP_STATE, false );
       }
     
     
      if( bool( ObjectGetInteger( 0, "Buy_L", OBJPROP_STATE ) ) )
      {
         Print( " Compra tipo Limit Iniciada" );
         if(ExecuteTrade("buy",CurPo,Size,"limit"))
         {
         ObjectSetInteger( 0, "Buy_L", OBJPROP_STATE, false );
         }
      }
   
     if( bool( ObjectGetInteger( 0, "Sell_L", OBJPROP_STATE ) ) )
      {
         Print( " Sell tipo Limit Iniciada" );
         if(ExecuteTrade("sell",CurPo,Size,"limit"))
         {
         ObjectSetInteger( 0, "Sell_L", OBJPROP_STATE, false );
         }
      }
   
    if( bool( ObjectGetInteger( 0, "Cancel", OBJPROP_STATE ) ) )
      {
        Print("Cancelando Ordenes pendientes");
        PendingOrderDelete();
        ObjectSetInteger( 0, "Cancel", OBJPROP_STATE, false );
     }
     
     //Botones TP Y SL subirlos
     if( bool( ObjectGetInteger( 0, "TP+", OBJPROP_STATE ) ) )
      {
        ModifySLorTP("tp",0);
        ObjectSetInteger( 0, "TP+", OBJPROP_STATE, false );
     }
     
     if( bool( ObjectGetInteger( 0, "SL+", OBJPROP_STATE ) ) )
      {
        ModifySLorTP("sl",0);
        ObjectSetInteger( 0, "SL+", OBJPROP_STATE, false );
     }
     
     //Botones TP y SL bajarlo
     
     if( bool( ObjectGetInteger( 0, "TP-", OBJPROP_STATE ) ) )
      {
        ModifySLorTP("tp",1);
        ObjectSetInteger( 0, "TP-", OBJPROP_STATE, false );
     }
     
     if( bool( ObjectGetInteger( 0, "SL-", OBJPROP_STATE ) ) )
      {
        ModifySLorTP("sl",1);
        ObjectSetInteger( 0, "SL-", OBJPROP_STATE, false );
     }
     
  
  }
   



//+------------------------------------------------------------------+
//| Funcion para creación de botones                                 |
//+------------------------------------------------------------------+

void func_button_create(
                        long chart_ID,
                        string name,// button name
                        int x,// X position
                        int y// Y position
                        )
  {
   ObjectCreate(chart_ID,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,40);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,20);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clrBlack);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,name);
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,false);
  
  }
  
 //+------------------------------------------------------------------+
 //| Eliminar Ordenes pendientes                                      |
 //+------------------------------------------------------------------+
 
void PendingOrderDelete() 
{  
         CTrade mytrade;
         int o_total=OrdersTotal();
         for(int j=o_total-1; j>=0; j--)
         {
            ulong o_ticket = OrderGetTicket(j);
            if(o_ticket != 0)
            {
             // delete the pending order
             mytrade.OrderDelete(o_ticket);
             Print("Pending order deleted sucessfully!");
          }
      }     
}

//+------------------------------------------------------------------+
//| Modificar SL o TP  con botones del grafico                       |
//+------------------------------------------------------------------+

void ModifySLorTP(string modify,int type)
{
   CTrade trade;
   ulong PositionTicket=PositionGetInteger(POSITION_TICKET);
   double CurrentSL=PositionGetDouble(POSITION_SL);
   double CurrentTP=PositionGetDouble(POSITION_TP); 
   double valorTick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   //int type ;//0->arriba 1->abajo
   

   Print("Order change");
   
   if (modify == "tp")
   {
      if(type==0){
         trade.PositionModify(PositionTicket,CurrentSL,CurrentTP+valorTick);
      }
      else 
      {
         trade.PositionModify(PositionTicket,CurrentSL,CurrentTP-valorTick);
      }
        
   }
   
    if (modify == "sl")
   {
      if(type==0){
         trade.PositionModify(PositionTicket,CurrentSL+valorTick,CurrentTP);
      }
      else 
      {
         trade.PositionModify(PositionTicket,CurrentSL-valorTick,CurrentTP);
      }
        
   }
}