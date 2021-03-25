//+------------------------------------------------------------------+
//|                                                      chanlun.mq5 |
//|                                      Copyright 2021, Xiaojun Gao |
//|                                        https://www.forex24.today |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Xiaojun Gao"
#property link      "https://www.forex24.today"
#property version   "1.00"
#property strict

#include "zencore.mqh"

//################
// Input Variables
//################

input string TradeSymbols = "EURUSD";       //Symbol(s)


//################
//Global Variables
//################

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int      NumberOfTradeableSymbols;                    //Set in OnInit()
string   SymbolArray[];                               //Set in OnInit()

int      TicksReceivedCount                = 0;       //Number of ticks received by the EA
int      TicksProcessedCount               = 0;       //Number of ticks processed by the EA (will depend on the BarProcessingMethod being used)
datetime TimeLastTickProcessed[];                     //Used to control the processing of trades so that processing only happens at the desired intervals (to allow like-for-like back testing between the Strategy Tester and Live Trading)
string   SymbolsProcessedThisIteration;

int      iBarToUseForProcessing;                      //This will either be bar 0 or bar 1, and depends on the BarProcessingMethod - Set in OnInit()



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//Populate SymbolArray and determine the number of symbols being traded
   NumberOfTradeableSymbols = StringSplit(TradeSymbols, '|', SymbolArray);

   ArrayResize(TimeLastTickProcessed, NumberOfTradeableSymbols);
   ArrayInitialize(TimeLastTickProcessed, D'1971.01.01 00:00');

//################################
//Determine which bar we will used (0 or 1) to perform processing of data
//################################

//Perform immediate update to screen so that if out of hours (e.g. at the weekend), the screen will still update (this is also run in OnTick())
   if(!MQLInfoInteger(MQL_TESTER))
      OutputStatusToScreen();

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   TicksReceivedCount++;

//##################################
//Loop through each tradeable Symbol to ascertain if we need to process this iteration
//##################################

   SymbolsProcessedThisIteration = "";

   for(int SymbolLoop = 0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
     {
      string CurrentSymbol = SymbolArray[SymbolLoop];

      //###############################################################
      //Control EA so that we only process trades at required intervals (Either 'Every Tick', 'TF Open Prices' or 'M1 Open Prices')
      //###############################################################

      bool ProcessThisIteration = false;     //Set to false by default and then set to true below if required

      if(TimeLastTickProcessed[SymbolLoop] != iTime(CurrentSymbol, PERIOD_M1, 0))
        {
         ProcessThisIteration = true;
         TimeLastTickProcessed[SymbolLoop] = iTime(CurrentSymbol, PERIOD_M1, 0);
        }


      //#############################
      //Process Trades if appropriate
      //#############################

      if(ProcessThisIteration == true)
        {
         TicksProcessedCount++;

         ProcessM1Bar(SymbolLoop);
        }
     }
  }

Bar buildM1Bar(string symbol) {
   Bar bar;
   bar.time = iTime(symbol, PERIOD_M1,1);
   bar.high = iHigh(symbol,PERIOD_M1,1);
   bar.open = iOpen(symbol, PERIOD_M1,1);
   bar.close = iClose(symbol, PERIOD_M1,1);
   bar.low = iLow(symbol, PERIOD_M1,1);
   return bar;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessM1Bar(int SymbolLoop)
  {
   string CurrentSymbol = SymbolArray[SymbolLoop];
   Bar bar = buildM1Bar(CurrentSymbol);

   string OutputText = "\n\r\n\r";
   OutputText += "ProcessClose " + CurrentSymbol + " open:" +DoubleToString(bar.open) + " high:" + DoubleToString(bar.high) +" low:" +DoubleToString(bar.low) + " close:" + DoubleToString(bar.close) +"\n\r";

   if(!MQLInfoInteger(MQL_TESTER))
      Comment(OutputText);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OutputStatusToScreen()
  {
   double offsetInHours = (TimeCurrent() - TimeGMT()) / 3600.0;

   string OutputText = "\n\r\n\r";

   OutputText += "MT5 SERVER TIME: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " (OPERATING AT UTC/GMT" + StringFormat("%+.1f", offsetInHours) + ")\n\r\n\r";

   OutputText += Symbol() + " Ticks Received:   " + IntegerToString(TicksReceivedCount) + "\n\r";
   OutputText += "Ticks Processed across all " + IntegerToString(NumberOfTradeableSymbols) + " symbols:   " + IntegerToString(TicksProcessedCount) + "\n\r";

//SYMBOLS BEING TRADED
   OutputText += "SYMBOLS:   ";
   for(int SymbolLoop=0; SymbolLoop < NumberOfTradeableSymbols; SymbolLoop++)
     {
      OutputText += " " + SymbolArray[SymbolLoop];
     }

   if(SymbolsProcessedThisIteration != "")
      SymbolsProcessedThisIteration = "\n\r" + SymbolsProcessedThisIteration;

   OutputText += "\n\rSYMBOLS PROCESSED THIS TICK:" + SymbolsProcessedThisIteration;

   Comment(OutputText);

   return;
  }

//+------------------------------------------------------------------+
