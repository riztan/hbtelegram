/** bot.prg  telegram bot example.
 *
 */

#include "tpy_hb.ch"

#include "bot_token.ch"
/*
#define BOT_TOKEN "YOUR_BOT_TOKEN_HERE"
#define BOT_NAME  "YOUR_BOT_NAME_HERE"
*/

#define LINE   hb_eol() + repli("-",30) + hb_eol()

procedure main()

   local oBot, oUpdates, oUpdate, oFrom

   hb_CdpSelect( "UTF8" )

   oBot := TlgrmBot():New( BOT_TOKEN, BOT_NAME )

   if oBot=NIL
      Alert( "Problem." )
      return
   endif

   oBot:SetCommand( "/start",    {|...| bot_Start(...) } )
   oBot:SetCommand( "/xbase",    {|...| bot_xBase(...) } )


   oUpdates := oBot:getUpdates()

   While !oUpdates:Eof()

      oUpdate := oUpdates:Current()

      ? "Update: "
      tracelog LINE + ( oUpdate:getJSON() ) + LINE
      ? "update_id: "      + oUpdate:update_id
      ? "type: "           + oUpdate:type
      oFrom := oUpdate:getFrom()
      ? "from_id: "        + oFrom:id 
      ? "from_firstname: " + oFrom:first_name
      Do Case
      Case oUpdate:type = "message"
         ? "chat: "   + oUpdate:message:chat:id
         ? "type: "   + oUpdate:message:chat:type
         if oUpdate:message:isDef("text")
            ? "text: "   + oUpdate:message:text
         endif
      Case oUpdate:type = "callback_query"
      EndCase

      if oUpdate:isdef("text")
         if len( oUpdate:tokens ) > 0 
            ? "tokens: ", hb_valtoexp( oUpdate:tokens )
         endif

         if left( oUpdate:text,1 ) = "/"
            oBot:Reply()
         endif
      endif

      oUpdates:Skip()
   EndDo   

return



procedure bot_Start( oFrom, oUpdate, oMsg, oBot )

   tracelog hb_valToExp( oUpdate )
   tracelog hb_valToExp( oMsg )
   oBot:sendMessage( oFrom:id, "Hello, I'm a Harbour bot for telegram!" )
   bot_menu( oFrom, oUpdate, oMsg, oBot )

return


procedure bot_menu( oFrom, oUpdate, oMsg, oBot )

   local aOptions := {}

   if oUpdate:isDef("message")
      tracelog "This is a message"
   elseif oUpdate:isDef("callback_query")
      tracelog "This is a callback query"
   endif

   tracelog hb_valToexp( oMsg:text )

   AADD( aOptions, {{"text"          => "I'm xBase developer",;
                     "callback_data" => "/xbase"              ;
                    }} )

   oBot:InlineChoice( oFrom:id, "Main menu 💫",aOptions )

return


procedure bot_xBase( oFrom, oUpdate, oMsg, oBot )

   local cPathImg := "http://www.harbour-project.com.br/art/harbour-logo.jpg"
   local cText

   if oUpdate:isDef("message")
      tracelog "This is a message"
   elseif oUpdate:isDef("callback_query")
      tracelog "This is a callback query"
   endif

   tracelog "chat id: "+oMsg:chat:id  
   tracelog "from user (id): "+oFrom:id  

   cText := "<b>The Harbour Project</b>"+hb_eol()
   cText += "<i>Clipper compatible OpenSource Compiler</i>"+hb_eol()
   cText += "Harbour Reference Guide: https://harbour.github.io/doc/harbour.html"

   oBot:sendPhoto( oMsg:chat:id, cText, cPathImg )

return

//eof
