/** bot.prg  telegram bot example.
 *
 */

#include "tpy_hb.ch"

#define BOT_TOKEN "YOUR_BOT_TOKEN_HERE"
#define BOT_NAME  "YOUR_BOT_NAME_HERE"

procedure main()

   local oBot, oUpdates

   oBot := TlgrmBot():New( BOT_TOKEN, BOT_NAME )

   if oBot=NIL
      Alert( "Problem." )
      return
   endif

   oBot:SetCommand( "/start",  {|...| bot_Start(...) } )


   oUpdates := oBot:getUpdates()

   While !oUpdates:Eof()

tracelog "yeah"
      oBot:Reply()

      oUpdates:Skip()
   EndDo   

return



procedure bot_Start( oFrom, oUpdate, oMsg, oBot )

   tracelog hb_valtoexp( oUpdate )
   tracelog hb_valtoexp( oMsg )
   oBot:sendMessage( oFrom:id, "Hello, im a Harbour bot for telegram!" )

return

//eof
