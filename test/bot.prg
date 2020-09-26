/** bot.prg  telegram bot example.
 *
 */

#include "tpy_hb.ch"

#define BOT_TOKEN "1089870519:AAEocjor1S_wLE6ALdsulOX9x9NRYA0LP-o"
#define BOT_NAME  "DoctorBlueBot"

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
