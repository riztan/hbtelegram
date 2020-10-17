/*
 * Harbour Contribution for Telegram API.
 *
 * Copyright 2020 Riztan Gutierrez <riztan@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file LICENSE.txt.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA (or visit https://www.gnu.org/licenses/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#require "hbcurl"
#include "hbcurl.ch"
#ifdef __BIN__
   #include "hbclass.ch"
   #include "tpy_hb.ch"
#else
   // Only for TPuy Script.
   #include "tpy_class.ch"
#endif


/** Utilizado para generar el hash de parametros definitivos en un metodo.
 */
STATIC FUNCTION CheckParam( hFrom, hTo, cLabel )
   if !hb_isHash(hFrom); return .f. ; endif
   if hb_hHasKey( hFrom, cLabel)
      hTo[ cLabel ] := hFrom[ cLabel ] 
      RETURN .t.
   endif
RETURN .f.


STATIC FUNCTION bot_ToPublic( hValues, cTlgrmJSON, lTPublic )
   local uItem, cName, cType
   local oValues 

   default lTPublic := .f.

   if lTPublic
      oValues := TPublic():New()
   else
      oValues := TLGRM_Update():New( cTlgrmJSON )
   endif

   FOR EACH uItem IN hValues
      cName := hb_hKeyAt( hValues, uItem:__EnumIndex() )
      cType := VALTYPE(uItem)
      IF cType = "H"
         oValues:Add( cName, bot_ToPublic( uItem, cTlgrmJSON, .t. ) )
      ELSEIF cType = "N"
         oValues:Add( cName, ALLTRIM(STR(uItem)) )
      ELSE
         oValues:Add( cName, uItem )
      ENDIF
   NEXT
   
   RETURN oValues



//---------------------------------------------------------------------------

CLASS tlgrmBot

   protected:
   DATA pCurl  
   DATA cBuffer
   DATA hUtfmap

   DATA cToken          INIT ""
   DATA cHost           INIT "https://api.telegram.org"
   DATA cName           INIT ""
   DATA cURL 
   DATA cLang           INIT "en"

   DATA nUpdatesLimit   INIT 20

   DATA oUpdates
   DATA hCommands       INIT hb_Hash()

   DATA hOpenQuestion   INIT hb_Hash()
   DATA hMediaGroup     INIT hb_Hash()

   DATA lRunning        INIT .f.

   visible:
   METHOD NEW( cToken, cName, nLimit, cError ) 
   METHOD setToken( cToken, cError )  
   METHOD setLang( cLang )            INLINE ::cLang := cLang
   METHOD Id()                        INLINE Left( ::cToken, At( ":", ::cToken )-1  ) 
   METHOD Name()                      INLINE ::cName
   METHOD setName( cName )            INLINE ::cName := cName
   METHOD setParams( hParams )        INLINE IIF( hb_IsHash(hParams), ::hParams := hParams, nil )

   METHOD clearMediaGroup( cFromId )  INLINE iif( hb_hHasKey(::hMediaGroup,cFromId),;
                                                      (hb_hDel( ::hMediaGroup, cFromId ), .t.),;
                                                       .f. )
   METHOD mediaGroup( cFromId )       INLINE iif( hb_hHasKey(::hMediaGroup,cFromId),; 
                                                       ::hMediaGroup[cFromId], "")
   METHOD addMediaGroup( cFromId, cId )    INLINE hb_hSet( ::hMediaGroup, cFromId, cId )

   METHOD getOpenQuestion( cFromId )  INLINE iif( hb_hHasKey(::hOpenQuestion,cFromId), ::hOpenQuestion[cFromId], nil )
   METHOD clearQuestion( cFromId )    INLINE iif( hb_hHasKey(::hOpenQuestion,cFromId),;
                                                  (hb_hDel( ::hOpenQuestion, cFromId ), .t.),;
                                                   .f. )
   METHOD OpenQuestion( cFromId )     INLINE iif( hb_hHasKey(::hOpenQuestion,cFromId),; 
                                                  ::hOpenQuestion[cFromId], "")

   METHOD Questions()                 INLINE Empty( ::hOpenQuestion )

   METHOD setCommand( cCommand, bAction, ... ) 
   METHOD getCommands()               INLINE ::hCommands   
//   METHOD SetUpdateNum( cUpdate ) 
   METHOD Commands()                  
   METHOD Reply()

   METHOD getMe()
   METHOD getUpdates()

   METHOD getFile( cFileID )          INLINE ::Execute( "getFile", { "file_id" => cFileId } )   
   METHOD getFileURL( cFileID )       INLINE "https://api.telegram.org/file/bot"+::cToken+"/"+;
                                             ::Execute( "getFile", { "file_id" => cFileId } )["result"]["file_path"]   

   //-- Metodos relacionados con el manejo del indice de mensajes pendientes (Updates)
   METHOD getUpdatesLimit()           INLINE ::nUpdatesLimit
   METHOD SetUpdatesLimit( nLimit )   INLINE IIF( hb_isNumeric(nLimit) .and. nLimit<50, ;
                                                  ::nUpdatesLimit := nLimit,            ;
                                                  nil )
   
   METHOD sendChatAction( uChatId, cAction )
   METHOD sendMessage( uChatId, cText,  oMsg, hOthers )

   METHOD editMessageText( cText, hOptionals ) 
   METHOD editMessageCaption( cCaption, hOptionals ) 
   METHOD editMessageReplyMarkup( cChatId, cMessageId, cInlineMessageId, aOptions, lPhoto, cText )

   METHOD sendMediaGroup( uChatId, aMedia, cText, lDisableNotification, nReplyToMessageId )

   METHOD sendVideo( uChatId, cCaption, cImagePath, oMsg, hOptionals )
   METHOD sendPhoto( uChatId, cCaption, cImagePath, oMsg, hOptionals )
   METHOD SendPoll( uChatId, cQuestion, aOptions, hOptionals, hOthers )

   METHOD sendVoice( uChatId, cCaption, cVoice, hOptionals, hOthers )

   METHOD answerInLine( cText, oMsg, aParams, cTitle )

   METHOD sendYesNo( uChatId, cText, oMsg, ... )

   METHOD inlineChoice( uChatId, cText, aOptions, oMsg, ... ) 
//   METHOD KeyboardChoice( hItems )   (POR HACER #ToDo )

   METHOD addQuestion( uChatID, cIdQuestion )  INLINE hb_hSet( ::hOpenQuestion, uChatID, cIdQuestion )

   METHOD sendQuestion( uChatId, cIdQuestion, cText, oMsg, ... )
   METHOD sendQuestion_cancel( uChatId, cIdQuestion, cText, oMsg, aOptions )
   METHOD sendConfirmation( uChatID, cText, oMsg, ... )

   METHOD answerCallbackQuery( cCallBackQryId, cText, lShowAlert, cURL, nCacheTime )

   METHOD delMessage( uChatId, cMessageId )   INLINE  ::Execute( "deleteMessage", ;
                                                                {"chat_id"=>uChatId, "message_id" => cMessageId} )
   METHOD sendVoiceFile( cChatID, cFile, cCaption )  // <-- En Desarrollo RIGC 2020-Sep-16
   METHOD Execute( cMethod, hParams, cError )

   METHOD getChatAdministrators( uChatId )     INLINE hb_jsonEncode( ::Execute( "getChatAdministrators", ;
                                                                 {"chat_id" => uChatId} ) )

   METHOD Reconnect()

   METHOD End()

ENDCLASS



METHOD ReConnect() CLASS TLGRMBOT

   curl_easy_cleanup( ::pCurl )
   curl_global_cleanup()

   curl_global_init()
   ::pCurl := curl_easy_init()

RETURN .t.




METHOD NEW( cToken, cName, nLimit, cError )  CLASS TLGRMBOT

   local hUtfMap

   if !Empty( cToken )
      if !::SetToken( cToken, @cError )
         RETURN cError
      endif
   endif

   if !Empty(cName)
      ::cName := cName
   endif

   if !Empty(nLimit) ; ::SetUpdatesLimit( nLimit ) ; endif

   curl_global_init()

   ::pCurl := curl_easy_init()

   #include "utf.map"

   ::hUtfMap := hUtfMap

   RETURN Self



/*
 *
 */
METHOD SetToken( cToken, cError )  CLASS TLGRMBOT
   if empty(cToken) .or. !ValType( cToken ) = "C"
      cError := "Token inválido"
      return .f.
   endif

   ::cToken := cToken
   ::cURL := ::cHost + "/bot" + ::cToken + "/"

   RETURN .t.



/*
 *
 */
METHOD getMe() CLASS TLGRMBOT

   local hTgm, cError
   local oGetMe := TPublic():New()
   
   hTgm := ::Execute( "getMe",,@cError )

   if hb_isNIL( hTgm )
      ::cError := "Problem when trying to execute the request."
      tracelog ::cError
      return NIL
   endif
   
   oGetMe:id         := hTgm["result"]["id"]
   oGetMe:first_name := hTgm["result"]["first_name"]
   oGetMe:username   := hTgm["result"]["username"]

   RETURN oGetMe



/*
 *
 */
METHOD getUpdates( )  CLASS TLGRMBOT
   local oUpdates := TLGRM_Updates():New( self ) 
   ::oUpdates := oUpdates

RETURN oUpdates



/*
 *
 */
METHOD sendChatAction( uChatId, cAction ) CLASS TLGRMBOT
   local aActions
   aActions :=  {"typing","upload_photo","record_video",;
                 "upload_video","record_audio","upload_audio",;
                 "upload_document","find_location","record_video_note",;
                 "upload_video_note"}
   if ASCAN( aActions, {|a| a = cAction } ) = 0 ; return .f. ; endif

   ::Execute( "sendChatAction", ;
             {"chat_id"=>uChatId, "action" => cAction} )

RETURN .t.



/*
 *
 */
METHOD sendMessage( uChatId, cText,  oMsg, hOthers ) CLASS TLGRMBOT
   local hTgm, hParams//, uItem, hResult
   //local oRes := TPublic():New()

   hb_default( hOthers, Hash() )

   if VALTYPE(uChatId) = "C" ; uChatId := ALLTRIM(uChatId) ; endif
   if empty( cText ) ; return "" ; endif

   ::sendChatAction( uChatId, "typing" )

   hParams := Hash()
   //hParams["&"] := ""
   
   if hb_IsObject( oMsg )
      hParams["reply_to_message_id"] := oMsg:message_id
   endif

   hParams["chat_id"] := uChatId

   hParams["text"]    := UTF_8(cText)
   //hParams["text"]    := iif( !hb_StrIsUTF8(cText), hb_strToUtf8(cText), cText )
   //hParams["text"]    := iif( !hb_StrIsUTF8(cText), utf_8(cText), cText )

   hParams["parse_mode"] := "HTML" //"Markdown"

   if !Empty( hOthers )
      hParams["reply_markup"] := hOthers
   endif

   hTgm := ::Execute( "sendMessage", hParams )

   if !hb_isHash( hTgm ) ; return .f. ; endif

   RETURN .t.



/*
 *
 */
METHOD editMessageText( cText, hOptionals )  CLASS TLGRMBOT
   local hEdit := hb_Hash()
   local hTgm

   CheckParam( hOptionals, @hEdit, "chat_id" )
   CheckParam( hOptionals, @hEdit, "message_id" )
   CheckParam( hOptionals, @hEdit, "inline_message_id" )
   CheckParam( hOptionals, @hEdit, "parse_mode" )
   CheckParam( hOptionals, @hEdit, "disable_web_page_preview" )
   CheckParam( hOptionals, @hEdit, "reply_markup" )

   //hEdit["text"] := cText
   hEdit["text"]    := iif( !hb_StrIsUTF8(cText), hb_strToUtf8(cText), cText )
   //hEdit["text"]    := iif( !hb_StrIsUTF8(cText), utf_8(cText), cText )
   
/*
   if !Empty( hOthers )
      hEdit["reply_markup"] := hOthers
   endif
*/
   hTgm := ::Execute( "editMessageText", hEdit )

   if !hb_isHash( hTgm ) ; return .f. ; endif

   RETURN .t.



/*
 *
 */
METHOD editMessageCaption( cCaption, hOptionals )  CLASS TLGRMBOT
   local hEdit := hb_Hash()
   local hTgm

   CheckParam( hOptionals, @hEdit, "chat_id" )
   CheckParam( hOptionals, @hEdit, "message_id" )
   CheckParam( hOptionals, @hEdit, "inline_message_id" )
   CheckParam( hOptionals, @hEdit, "parse_mode" )
   CheckParam( hOptionals, @hEdit, "reply_markup" )

   hEdit["caption"]    := cCaption //iif( !hb_StrIsUTF8(cCaption), hb_strToUtf8(cCaption), cCaption )
   
   hTgm := ::Execute( "editMessageCaption", hEdit )

   if !hb_isHash( hTgm ) ; return .f. ; endif

   RETURN .t.



/*
 *
 */
METHOD editMessageReplyMarkup( cChatId, cMessageId, cInlineMessageId, aOptions, lPhoto, cText )
  local hParams:=hb_Hash(), hTgm

  default lPhoto := .f.
  default cText  := ""

   if !hb_StrIsUTF8( cText ) ; cText := hb_StrToUTF8(cText) ; endif
  //  ESTAMOS INTENTANDO COLOCAR LA CUENTA EN LOS BOTONES DEL REPLYMARKUP

  if empty( aOptions ) .or. !hb_isArray( aOptions )
     return .f.
  endif

/*
  if empty( hMessage ) .or. hb_isNIL( hMessage )
     lPhoto := .f.
  else
     if hMessage:isDef("photo")
        lPhoto := .t.
     endif
  endif
*/

  if !Empty(cChatId) .and. !hb_isNIL(cChatId)
     hParams["chat_id"] := cChatId
  endif

  if !Empty(cMessageId) .and. !hb_isNIL(cMessageId)
     hParams["message_id"] := cMessageId
  endif

  if !Empty(cInLineMessageId) .and. !hb_isNIL(cInLineMessageId)
     hParams["inline_message_id"] := cInLineMessageId
  endif

  hParams["reply_markup"] := {"inline_keyboard"   => { aOptions }} 

  if !lPhoto
     //hParams["text"] := cText
     hTgm := ::Execute( "editMessageText", hParams )
  else
     hParams["caption"] := cText
     hTgm := ::Execute( "editMessageCaption", hParams )
  endif

  if !hb_isHash( hTgm ) ; return .f. ; endif

RETURN .t.



/*
 *
 */
METHOD sendMediaGroup( uChatId, aMedia, cText, lDisableNotification, nReplyToMessageId ) CLASS TLGRMBOT
   local hParams := hb_Hash()

   default lDisableNotification := .f.
   default cText := ""

   if !Empty(cText)
      aMedia := hb_jsonDecode( aMedia )
      if !hb_StrIsUTF8( cText ) ; cText := hb_StrToUTF8(cText) ; endif
      aMedia[1]["caption"   ] := cText
      aMedia[1]["parse_mode"] := "HTML"
      aMedia := hb_jsonEncode( aMedia )
   endif

   hParams["chat_id"] := uChatId
   hParams["media"  ] := aMedia
   hParams["disable_notification"] := lDisableNotification
   if !Empty(nReplyToMessageId) .and. !hb_isNil( nReplyToMessageId )
      hParams["reply_to_message_id"] := nReplyToMessageId
   endif

RETURN ::Execute( "sendMediaGroup", hParams )



/*
 *
 */
METHOD sendVideo( uChatId, cCaption, cImagePath, oMsg, hOptionals ) CLASS TLGRMBOT
   local hTgm, hParams//, uItem, hResult

   if VALTYPE(uChatId) = "C" ; uChatId := ALLTRIM(uChatId) ; endif
   if empty( cCaption ) ; return "" ; endif

   ::sendChatAction( uChatId, "upload_video" )

   hParams := Hash()
   
   if hb_IsObject( oMsg )
      hParams["reply_to_message_id"] := oMsg:id
   endif

   hParams["chat_id"] := uChatId

   hParams["caption"] := cCaption
   hParams["caption"] := iif( !hb_StrIsUTF8(cCaption), hb_strToUtf8(cCaption), cCaption )
   //hParams["caption"] := iif( !hb_StrIsUTF8(cCaption), utf_8(cCaption), cCaption )

   hParams["parse_mode"] := "HTML" //"Markdown"
   hParams["video"]   := cImagePath

   if hb_isHash( hOptionals ) .and. !Empty( hOptionals )
      HEVAL( hOptionals, {|key,value |  hb_hSet( hParams, key, value ) } )
tracelog  hb_valtoexp(hOptionals)
   endif

   hTgm := ::Execute( "sendVideo", hParams )
   
   if !hb_ISHash( hTgm )
      RETURN .F.
   endif

RETURN .t.



/*
 *
 */
METHOD sendPhoto( uChatId, cCaption, cImagePath, oMsg, hOptionals ) CLASS TLGRMBOT
   local hTgm, hParams//, uItem, hResult

   if VALTYPE(uChatId) = "C" ; uChatId := ALLTRIM(uChatId) ; endif
   if empty( cCaption ) ; return "" ; endif

   ::sendChatAction( uChatId, "upload_photo" )

   hParams := Hash()
   
   if hb_IsObject( oMsg )
      hParams["reply_to_message_id"] := oMsg:id
   endif

   hParams["chat_id"] := uChatId

   hParams["caption"] := cCaption
   hParams["caption"] := iif( !hb_StrIsUTF8(cCaption), hb_strToUtf8(cCaption), cCaption )
   //hParams["caption"] := iif( !hb_StrIsUTF8(cCaption), utf_8(cCaption), cCaption )

   hParams["parse_mode"] := "HTML" //"Markdown"
   hParams["photo"]   := cImagePath

   if hb_isHash( hOptionals ) .and. !Empty( hOptionals )
      HEVAL( hOptionals, {|key,value |  hb_hSet( hParams, key, value ) } )
tracelog  hb_valtoexp(hOptionals)
   endif

   hTgm := ::Execute( "sendPhoto", hParams )
   
   if !hb_ISHash( hTgm )
      RETURN .F.
   endif

RETURN .t.



/*
 *
 */
METHOD SendPoll( uChatId, cQuestion, aOptions, hOptionals, hOthers )  CLASS TLGRMBOT
   local hTgm, hPoll := hb_Hash()

   if hb_isNIL( aOptions ) .or. Empty( aOptions )
      return .f.
   endif

   hPoll["chat_id" ] := uChatId
   hPoll["question"] := iif( !hb_strIsUTF8(cQuestion), hb_strToUtf8(cQuestion), cQuestion )
   //hPoll["question"] := iif( !hb_strIsUTF8(cQuestion), utf_8(cQuestion), cQuestion )
   hPoll["options" ] := aOptions

//   if hb_hHasKey( hOptionals, "is_anonymous") ; hOptionals[ "is_anonymous" ] := hOptionals["is_anonymous"]
   CheckParam( hOptionals, @hPoll, "is_anonymous" )
   CheckParam( hOptionals, @hPoll, "type" )
   CheckParam( hOptionals, @hPoll, "allows_multiple_answers" )
   CheckParam( hOptionals, @hPoll, "correct_option_id" )
   CheckParam( hOptionals, @hPoll, "explanation" )
   CheckParam( hOptionals, @hPoll, "explanation_parse_mode" )
   CheckParam( hOptionals, @hPoll, "open_period" )
   CheckParam( hOptionals, @hPoll, "close_date" )
   CheckParam( hOptionals, @hPoll, "is_closed" )
   CheckParam( hOptionals, @hPoll, "disable_notification" )
   CheckParam( hOptionals, @hPoll, "reply_to_message_id" )
//   CheckParam( hOptionals, @hPoll, "reply_markup" )

   
   if !Empty( hOthers )
      hPoll["reply_markup"] := hOthers
   endif

   hTgm := ::Execute( "sendPoll", hPoll )

   if !hb_isHash( hTgm ) ; return .f. ; endif

   RETURN .t.



/*
 *
 */
METHOD sendVoice( uChatId, cCaption, cVoice, hOptionals, hOthers )  CLASS TLGRMBOT
   local hTgm, hVoice := hb_Hash()

   if Empty(cVoice) .or. hb_isNIL(cVoice) 
      tracelog "No reference to the content of the voice message has been indicated."
      return .f.
   endif

   ::sendChatAction( uChatId, "record_audio" )

   hVoice["chat_id" ] := uChatId
   hVoice["caption"]  := iif( !hb_strIsUTF8(cCaption), hb_strToUtf8(cCaption), cCaption )
   hVoice["voice"]    := cVoice

   CheckParam( hOptionals, @hVoice, "parse_mode" )
   CheckParam( hOptionals, @hVoice, "duration" )
   CheckParam( hOptionals, @hVoice, "disable_notification" )
   CheckParam( hOptionals, @hVoice, "reply_to_message_id" )

   
   if !Empty( hOthers )
      hVoice["reply_markup"] := hOthers
   endif

   hTgm := ::Execute( "sendVoice", hVoice )

   if !hb_isHash( hTgm ) ; return .f. ; endif

   RETURN .t.



/*
 *
 */
METHOD AnswerInLine( cText, oMsg, aParams, cTitle )  CLASS TLGRMBOT
   local hTgm //, oRes := TPublic():New()
   local hParams := hash(), hInline :=Hash()

   hb_default( cTitle, "" )

   if Empty(aParams) ; return .f. /*oRes*/ ; endif

   hParams["type"] := "article"
   hParams["id"]   := hb_MD5( hb_jsonEncode( hParams ) + oMsg:id )
   hParams["title"]:= cTitle 
   hParams["description"] := cText
   hParams["input_message_content"] := {"message_text"=>cText}

//   hInline["&"] := ""
   hInline["inline_query_id"] := oMsg:id
   hInline["results"] := hb_jsonEncode( {hParams} )
//? "----------------------"
//? procname()
//? hb_jsonEncode(hInline)

//? procname(),": Id --> ",hInLine["inline_query_id"]
   hTgm := ::Execute( "answerInLineQuery", hInline )
//?
//? hb_ValToexp( hTgm )
//?
   
   //oRes:nLen := LEN( hTgm["result"] )
   if !hb_isHash( hTgm ) ; return .F. ; endif

RETURN .t.



/*
 *
 */
METHOD InlineChoice( uChatId, cText, aOptions, oMsg, ... ) CLASS TLGRMBOT
   local hKBtn, hResult

   if empty( aOptions ) .or. hb_isNIL(aOptions) .or. !hb_isArray(aOptions)
      tracelog "The list of elements to be elaborated is not recognized."
      return .f.
   endif

   // -- en caso de recibir un array sencillo, lo metemos dentro de otro array.
   if VALTYPE(aOptions[1])="H" ; aOptions := {aOptions} ; endif

   hKBtn := {"inline_keyboard" => aOptions,            ;
                               "resize_keyboard" => .t.,   ;
                               "one_time_keyboard" => .t.  ;
            }
            
   tracelog hb_jsonEncode(hKBtn)
 
   if !hb_StrIsUTF8( cText ) ; cText := hb_StrToUTF8(cText) ; endif
   hResult := ::SendMessage( uChatId, cText, oMsg, hb_jsonEncode(hKBtn), ... )
RETURN hresult



/*
 *
 */
METHOD sendQuestion( uChatId, cIdQuestion, cText, oMsg, ... ) CLASS TLGRMBOT
   hb_hSet( ::hOpenQuestion, uChatID, cIdQuestion )
   //if !hb_StrIsUTF8( cText ) ; cText := hb_StrToUTF8(cText) ; endif
//tracelog cText
RETURN ::SendMessage( uChatId, cText, oMsg, ... )



/*
 *
 */
METHOD sendQuestion_cancel( uChatId, cIdQuestion, cText, oMsg, aOptions ) CLASS TLGRMBOT
   local hKBtn
   local aInlineKeyboard := {{"text"=>"No continuar ⏹","callback_data" => "/cancelar"} }
   //local aInlineKeyboard := { {"text"=>"No continuar ⏹","callback_data" => "/cancelar"} }

   if hb_isArray( aOptions )
      AADD( aOptions, aInlineKeyboard[1] )
   else
      aOptions := aInlineKeyboard
   endif 

   hKBtn := {"inline_keyboard" => { aOptions },;
             "resize_keyboard" => .t.,   ;
             "one_time_keyboard" => .t.  ;
            }
   if !hb_StrIsUTF8( cText ) ; cText := hb_StrToUTF8(cText) ; endif
RETURN ::SendQuestion( uChatId, cIdQuestion, cText, oMsg, hKBtn )



/*
 *
 */
METHOD SendYesNo( uChatId, cText, oMsg, ... ) CLASS TLGRMBOT
   local aOptions 
   aOptions := {  ;
                  {"text" => "Si", "callback_data" => "/si"}, ;
                  {"text" => "No", "callback_data" => "/no"}  ;
               }
   if !hb_StrIsUTF8( cText ) ; cText := hb_StrToUTF8(cText) ; endif
RETURN ::InlineChoice( uCHatId, cText, aOptions, oMsg, ... )



/*
 *
 */
METHOD sendConfirmation( uChatID, cText, oMsg, ... )
   local aOptions 

   if !hb_hHasKey( ::hOpenQuestion, uChatId ) 
      tracelog "There is nothing to ask for confirmation."
      hb_hSet( ::hOpenQuestion, uChatId, "yesno" )
   endif

   if ::cLang="es"
      aOptions := {{"text"=>"Si","callback_data"=>"/confirme "+::hOpenQuestion[uChatId]+":SI"},;
                   {"text"=>"No","callback_data"=>"/confirme "+::hOpenQuestion[uChatId]+":NO"}}
   else
      aOptions := {{"text"=>"Yes","callback_data"=>"/confirme "+::hOpenQuestion[uChatId]+":YES"},;
                   {"text"=>"No" ,"callback_data"=>"/confirme "+::hOpenQuestion[uChatId]+":NO" }}
   endif
//tracelog hb_valtoexp(aOptions)
//   ::sendQuestion( uChatID, "yesno", cText, oMsg, ,... )
   if !hb_StrIsUTF8( cText ) ; cText := hb_StrToUTF8(cText) ; endif
RETURN ::InlineChoice( uChatId, cText, aOptions, oMsg, ... )



/*
 *
 */
METHOD answerCallbackQuery( cCallBackQryId, cText, lShowAlert, cURL, nCacheTime ) CLASS TLGRMBOT
   local lResp := .f., hParams := hb_Hash()

   hParams["callback_query_id"] := cCallBackQryId

   if !hb_isNil( cText ) .and. !Empty( cText ) 
      hParams["text"] := cText
   endif
   
   if !hb_isLogical( lShowAlert )
      hParams["show_alert"] := lShowAlert
   endif
   
   if !hb_isNil( cURL ) .and. !Empty( cURL ) 
      hParams["url"] := cURL
   endif
   
   if !hb_isNumeric( nCacheTime ) 
      hParams["cache_time"] := nCacheTime
   endif
   
   tracelog hb_valtoexp( ::Execute( "answerCallbackQuery", hParams ) )
   //lResp := ::Execute( "answerCallbackQuery", hParams )["ok"]

RETURN lResp



/*
 *
 */
METHOD sendVoiceFile( cChatId, cFile, cCaption ) CLASS TLGRMBOT
   local cData
   local cDest  := 'tmp/voice_'+cChatId+STRTRAN(Time(),":","")+'.json '
   local cEXE   := 'curl '
   local cMode  := "-X POST " + ::cURL + 'sendVoice'
   //local cMode := "-X POST -i -L " + cPostURL +''
   local cSilent:= '' //'-s '
   local cCmd      

/*
curl -i -F 'chat_id=1234567890' -F 'voice=@audio.ogg' 'https://api.telegram.org/bot1234567890:AABBCCDDEEFFGGHH/sendVoice' 2>&1"
*/

   //TODO: Improve. It is better to use the library, 
   //      but I still have problems applying it. (for now, this is how it works)

   default cCaption := ''

   if empty(cFile) .or. hb_isNIL(cFile) ; return "" ; endif


   cData :=   ' -F "chat_id='+cChatId+'" '+;
              iif( !Empty(cCaption), ' -F "caption='+cCaption+'" -F "parse_mode=HTML"', '' ) +; 
              ' -F "voice=@'+cFile+'" '

   cCmd := cEXE + cMode  + cData + cSilent + cFile + ' > '+cDest

   tracelog cCmd

   hb_run(cCmd)

   if FILE( cDest )
      Return hb_memoRead( cDest )
   endif

/*
curl -X POST https://api.telegram.org/bot11111:1111111/sendVoice -F "chat_id=330534557" -F "voice=@result.ogg"
*/

/*
   if Empty(cFile) .or. hb_IsNIL(cFile)
      cError := "no se ha indicado nombre del archivo contenedor del audio"
      tracelog cError
      return ""
   endif
  
   pCurl = curl_easy_init()    // Initialize a CURL session.
   curl_easy_setopt( pCurl, HB_CURLOPT_URL, ::cURL + "sendAudio" )
   curl_easy_setopt( pCurl, HB_CURLOPT_CUSTOMREQUEST, 'POST' )
   curl_easy_setopt( pCurl, HB_CURLOPT_POST, .t. )
   curl_easy_setopt( pCurl, HB_CURLOPT_POSTFIELDS, hb_MemoRead( cFile ) )
   curl_easy_setopt( pCurl, HB_CURLOPT_SSL_VERIFYPEER, .f. )
   curl_easy_setopt( pCurl, HB_CURLOPT_HTTPHEADER, {"Content-Type: multipart/form-data","charset=utf-8"} )


   nRes := curl_easy_perform( pCurl )
   If nRes != HB_CURLE_OK
      //MsgStop( curl_easy_strerror(nRes) )
      cError := curl_easy_strerror(nRes)
tracelog cError
      curl_easy_cleanup( pCurl )
      RETURN nRes
   EndIf
  
//tracelog "Aparentemente bien"
   curl_easy_cleanup( pCurl )
*/
RETURN ""



/*
 *
 */
METHOD Execute( cMethod, hParams, cError ) CLASS TLGRMBOT

   local hTgm, oErr
   local nResp := 999 , nCont := 0
   local cResp, nPos, cFind

   if ::lRunning 
      tracelog "Ya hay un proceso ejecutándose..."
      return nil
   endif

//tracelog "iniciando..."

   ::lRunning := .t.

   While nResp != 0 .and. nCont < 5

      curl_global_init()
      ::pCurl := curl_easy_init()

// -- proxy
/*
      curl_easy_setopt( ::pCurl, HB_CURLOPT_PROXYPORT, 3128 )
      curl_easy_setopt( ::pCurl, HB_CURLOPT_PROXY, 'IP_DEL_PROXY')
      curl_easy_setopt( ::pCurl, HB_CURLOPT_PROXYTYPE, 'HTTP')

      curl_easy_setopt( ::pCurl, HB_CURLOPT_PROXYUSERPWD, 'USUARIO:PASSWORD')
      curl_easy_setopt( ::pCurl, HB_CURLOPT_HTTPPROXYTUNNEL, .f.)
*/

      curl_easy_setopt( ::pCurl, HB_CURLOPT_URL, ::cURL + cMethod )
      curl_easy_setopt( ::pCurl, HB_CURLOPT_CUSTOMREQUEST, 'POST' )
      curl_easy_setopt( ::pCurl, HB_CURLOPT_POST, .t. )
      curl_easy_setopt( ::pCurl, HB_CURLOPT_SSL_VERIFYPEER, .f. )

      curl_easy_setopt( ::pCurl, HB_CURLOPT_CONNECTTIMEOUT, 10 )

      curl_easy_setopt( ::pCurl, HB_CURLOPT_VERBOSE, .f. )
      curl_easy_setopt( ::pCurl, HB_CURLOPT_HTTPHEADER, {"Content-Type: application/json","charset=utf-8"} )


      curl_easy_setopt( ::pCurl, HB_CURLOPT_POSTFIELDS, hb_jsonEncode( hParams ) )
      curl_easy_setopt( ::pCurl, HB_CURLOPT_DL_BUFF_SETUP )


      BEGIN SEQUENCE WITH __BreakBlock()
         nResp := curl_easy_perform( ::pCurl ) 
      RECOVER USING oErr
         tracelog oErr:description
         hb_idlesleep(3)
         loop
      END SEQUENCE

      if nResp != HB_CURLE_OK
         tracelog "ERROR", NToStr(nResp) , iif(nResp=28,"(Waiting limit exceeded).","")
         hb_IdleSleep( 3 )
      else
         //tracelog time()+" OK "
         exit
      endif

      if nCont = 4
         tracelog "Countdown resumes... waiting 4 seconds."
         hb_IdleSleep( 3 )
         ::Reconnect()
         hb_IdleSleep( 1 )
         nCont := 0
      endif
      nCont++

tracelog time()+". Cycle counter...", nCont

   EndDo

//tracelog uResp  // <-- mostramos en monitoreo el resultado obtenido.

   cResp := curl_easy_dl_buff_get( ::pCurl )
   nPos := hb_at( "\ud", cResp ) 
   // TODO: The only way I have managed to solve with emojies
   While nPos > 0
      cFind := SubStr(cResp, nPos, 12)

      if hHasKey( ::hUtfMap, cFind )
         cResp := STRTRAN( cResp, cFind, hb_hGet(::hUtfMap,cFind)[1] )
      else
         cResp := STRTRAN( cResp, cFind, "?" )
      endif
      nPos := hb_at( "\ud", cResp ) 
   EndDo


   hTgm := hb_jsonDecode( cResp )

   curl_easy_reset( ::pCurl )

   curl_easy_cleanup( ::pCURL )
   curl_global_cleanup()

   ::lRunning := .f.

   /*Manipulate the possible error that can throw cURL*/
   if !hb_isHash(hTgm) .or. Empty( hTgm )
      cError :=  "No answer, empty container."
      tracelog cError
      return NIL
   endif

   if !hTgm["ok"]
      cError := STR(hTgm["error_code"])+" -> "+hTgm["description"]
      tracelog cError
   endif

   //tracelog hb_valtoexp(hTgm)
   if hb_hHasKey( hTgm, "result" ) .and. !Empty( hTgm["result"] )
      tracelog "Update: "+hb_eol()+cResp
   endif
RETURN hTgm 



/** Retorna lista de comandos disponibles.
 */
METHOD COMMANDS() CLASS TLGRMBOT
   local cResp
   cResp := hb_valtoexp( hb_hKeys(::hCommands) )
   tracelog cResp
   cResp := STRTRAN(cResp,"/","")
RETURN cResp


/** Registra un comando
 */
METHOD SetCommand( cCommand, bAction, ... ) CLASS TLGRMBOT
   if !hb_isBlock( bAction )
      tracelog "The code block has not been indicated"
      return .f.
   endif

tracelog "Incorporating command  ", cCommand 
   hb_hSet( ::hCommands, cCommand, bAction, ... )
tracelog hb_valtoexp(::hCommands)
RETURN .t.



/** Revisa los datos de la entrada e identifica si se solicita la ejecución de 
 *  un comando para ejecutarlo y emitir la respuesta correspondiente.
 */
METHOD Reply() CLASS TLGRMBOT
   local oUpdate := ::oUpdates:Current()
   local aTokens := oUpdate:tokens
   //local lCallBack := .f.
   local oFrom, oMsg, cCommand, oErr, cText

   //tracelog "tokens", hb_valtoexp( aTokens ) //oUpdate:tokens )

   if Empty( aTokens )
      if !( oUpdate:isDef("message") .and. oUpdate:message:isdef("voice") ;
            .and. hb_hHasKey( ::hCommands, "/audio" ) )
         return .F.
      endif
      aTokens := {"/audio"}
   endif
      
//tracelog "type", oUpdate:type
   Do Case
   Case oUpdate:type == "callback_query"
      //lCallBack := .t.
      oFrom := oUpdate:callback_query:from
      oMsg  := oUpdate:callback_query:message
   Case oUpdate:type == "message"
      oFrom := oUpdate:message:from
      oMsg  := oUpdate:message
   Other
      Return .f.
   EndCase

   cCommand := STRTRAN( aTokens[1], ::cName, "" )
   if hb_hHasKey( ::hCommands, cCommand )
      Do Case
      Case hb_isBlock( ::hCommands[ cCommand ] )      

         //-- This must be improved (RIGC Sep/2020)
         BEGIN SEQUENCE WITH {| oErr | Break( oErr ) }

            EVAL( ::hCommands[cCommand], oFrom, oUpdate, oMsg, self )

         RECOVER USING oErr
            cText := "<b>SubSystem: </b>"  +oErr:subsystem + hb_eol()
            cText += "<b>SubCode: </b>"    +ALLTRIM(STR(oErr:subcode)) + hb_eol()
            cText += "<b>Description: </b>"+oErr:description + hb_eol()
            cText += "<b>Command: </b>"    +cCommand + hb_eol()
            cText += "<b>From: </b> "      +oFrom:first_name+hb_eol()
            cText += "<b>Update: </b>"     +hb_eol()+hb_valtoexp(oUpdate)+hb_eol()+hb_eol()
            //::sendMessage("330534557", cText )
            tracelog cText
            hb_memoWrit( "exit.log", cText )
         END SEQUENCE

      Case hb_isString( ::hCommands[ cCommand ] )
         ::SendMessage( oMsg:chat:id, ::hCommands[ cCommand ], oMsg )

      EndCase
   else
      tracelog "Command ["+cCommand+"] not found."
      RETURN .F.
   endif

RETURN .T.



/** Finaliza la ejecución del bot
 */
METHOD End() CLASS TlgrmBot
   curl_easy_cleanup( ::pCurl )
   curl_global_cleanup()

RETURN .t.



//-----------------------------------------------------------------------------

/**
 *  Clase para control de las entradas en telegram.
 *  Las entradas son los mensajes sin revisar.
 */
CLASS TLGRM_UPDATES 

   protected:
   DATA oBot
   DATA hParams
   DATA hTgm     INIT hb_Hash()
   DATA nLen     INIT 0
   DATA lEof     INIT .f.
   DATA nPos     INIT 1
   DATA nUpdate  INIT 1
   DATA oUpdate
   DATA cFileUpdates  INIT "tlgrmbot.update"

   DATA cError   INIT ""

   visible:
   Method New( oBot )

   METHOD Refresh()

   METHOD Len()         INLINE ::nLen
   METHOD RecCount()    INLINE ::nLen
   METHOD RecNo()       INLINE ::nPos
   METHOD Eof()         INLINE ::lEof

   METHOD Current( nPos ) 
   METHOD Values()      INLINE hb_hKeys( ::oUpdate:hVars )
   METHOD Next( nMove ) 
   METHOD Skip( nPos )  INLINE ::Next( nPos )

   METHOD Error()       INLINE ::cError

   ERROR HANDLER OnError( uValue )

ENDCLASS



/*
 *
 */
METHOD New( oBot ) CLASS TLGRM_UPDATES

   local nUpdate 

   ::oBot := oBot

   if FILE( ::cFileUpdates ) 
      nUpdate := VAL(hb_MemoRead( ::cFileUpdates ))
      if nUpdate > 0 ; ::nUpdate := nUpdate ; endif
   endif

   ::hParams := { "offset" => ::nUpdate,;
                  "limit"  => ::oBot:getUpdatesLimit() }
   ::Refresh()

RETURN Self



/*
 *
 */
METHOD Refresh() CLASS TLGRM_UPDATES
   
   local aResult, hTgm

   //SysRefresh(.t.)
//tracelog hb_valtoexp( ::hParams )
   hTgm := ::oBot:Execute( "getUpdates", ::hParams, @::cError )

   if hb_isNIL( hTgm) .or. !hb_isHash( hTgm ) .or. !hTgm["ok"]
      tracelog "ERROR. " + ::cError
      RETURN NIL
   endif

   ::hTgm := hTgm

   aResult := ::hTgm["result"]

//   tracelog hb_valtoexp( ::hTgm["result"] )
   if empty( aResult )
      ::Update := 0
      ::nLen   := 0
      ::nPos   := 0
      ::lEof   := .t.
      RETURN .t.
   endif

   ::nUpdate := ::hTgm["result"][::nPos]["update_id"]
   ::nLen    += LEN( ::hTgm["result"] )
tracelog ALLTRIM(STR(::nLen)), "Updates to be processed... "

   ::Current()

RETURN .T.



/*
 *
 */
METHOD Next( nMove ) CLASS TLGRM_UPDATES
   default nMove := 1
   ::cError := ""
   Do Case
   Case ::nPos + nMove > ::nLen
      ::nPos := ::nLen
      ::Current( ::nLen )
      ::lEof := .t.
   Case ::nPos + nMove <= 1
      ::lEof := .f.
      ::nPos := 1
      ::Current( ::nPos )
   Case nMove = 0
      return .t.
   Other
      ::nPos += nMove
      ::Current( ::nPos )
   EndCase

   //-- Se debe colocar el nro de actualización + 1 
   //   Como valor de arranque una proxima vez que se inicie el bot.
   if !hb_MemoWrit( ::cFileUpdates, ALLTRIM(STR(::nUpdate+1)) )
      ::cError := "it was not possible to update the control file. ("+::cFileUpdate+")"
      tracelog ::cError
      RETURN .F.
   endif
tracelog "almacenado el nro de update. "+ALLTRIM(STR(::nUpdate+1))

   hb_IdleSleep( 1 )
   
RETURN .T.



/*
 *
 */
METHOD Current( nPos ) CLASS TLGRM_UPDATES
   local hUpdate, oUpdate, cTlgrmJSON
   local aTypes := { "message",             ;
                     "edited_message",      ;
                     "channel_post",        ;
                     "edited_channel_post", ;
                     "inline_query",        ;
                     "chosen_inline_result",;
                     "callback_query",      ;
                     "shipping_query",      ;
                     "pre_checkout_query",  ;
                     "poll",                ;
                     "poll_answer"          ;
                   }

   ::cError := ""

   default nPos := 0 //::nPos

   if hb_isNIL( ::oUpdate ) ; nPos := 1 ; endif

   if ::nLen = 0
      ::cError := "No update pending or no communication."
      tracelog ::cError
      hb_IdleSleep( 5 )
//tracelog "Reconectando"
      ::oBot:ReConnect()
//tracelog "Refrescando"
      ::Refresh()
      return NIL
   endif

   if nPos = 0 //.and. !hb_isNIL(::oUpdate)
      return ::oUpdate
   endif

   if nPos > ::nLen .or. nPos <= 0
      ::cError := "The indicated position is outside the update cursor."
//tracelog "Updates actuales: ", ::Len()
      tracelog ::cError
      hb_IdleSleep( 5 )
      return NIL 
   endif 


   hUpdate := ::hTgm["result"][nPos]
   cTlgrmJSON := hb_jsonEncode(hUpdate)
//tracelog "keys en hUpdate... ", hb_eol(), hb_valToExp(hb_hKeys( hUpdate ))

   AEVAL( aTypes, {|type| iif( hb_hHasKey(hUpdate,type), hUpdate["type"] := type, nil ) } )

   hUpdate["text"  ] := ""
   hUpdate["tokens"] := {}

   if hb_hHasKey( hUpdate, "message" )

      if hb_hHasKey( hUpdate["message"], "text" )
         hUpdate["text"  ] := hUpdate["message"]["text"]
         hUpdate["tokens"] := hb_aTokens( hUpdate["text"] )
      endif

      hUpdate["lPhoto"    ] := .f.
      hUpdate["lDice"     ] := .f.
      hUpdate["lSticker"  ] := .f.
      hUpdate["lDocument" ] := .f.
      hUpdate["lVoice"    ] := .f.
      hUpdate["lAudio"    ] := .f.
      hUpdate["lVideo"    ] := .f.
      hUpdate["lVideoNote"] := .f.
      hUpdate["lAnimation"] := .f.
      hUpdate["lContact"  ] := .f.
      hUpdate["lLocation" ] := .f.
      hUpdate["lVenue"    ] := .f.
//      hUpdate["lPollOption"]  := .f.
      Do Case
      Case hb_hHasKey( hUpdate["message"], "photo" )
         hUpdate["lphoto"] := .t.
      Case hb_hHasKey( hUpdate["message"], "dice" )
         hUpdate["lDice"] := .t.
      Case hb_hHasKey( hUpdate["message"], "sticker" )
         hUpdate["lSticker"] := .t.
      Case hb_hHasKey( hUpdate["message"], "document" )
         hUpdate["lDocument"] := .t.
      Case hb_hHasKey( hUpdate["message"], "voice" )
         hUpdate["lVoice"] := .t.
      Case hb_hHasKey( hUpdate["message"], "audio" )
         hUpdate["lAudio"] := .t.
      Case hb_hHasKey( hUpdate["message"], "video" )
         hUpdate["lVideo"] := .t.
      Case hb_hHasKey( hUpdate["message"], "videonote" )
         hUpdate["lVideoNote"] := .t.
      Case hb_hHasKey( hUpdate["message"], "animation" )
         hUpdate["lAnimation"] := .t.
      Case hb_hHasKey( hUpdate["message"], "contact" )
         hUpdate["lContact"] := .t.
      Case hb_hHasKey( hUpdate["message"], "location" )
         hUpdate["lLocation"] := .t.
      Case hb_hHasKey( hUpdate["message"], "venue" )
         hUpdate["lVenue"] := .t.
//      Case hb_hHasKey( hUpdate["message"], "polloption" )
//         hUpdate["lPollOption"] := .t.
      EndCase
   endif

   if hb_hHasKey( hUpdate, "callback_query" )
      hUpdate[ "text"  ] := hUpdate["callback_query"]["data"]
      hUpdate[ "tokens"] := hb_aTokens( hUpdate["text"] )
   endif

   oUpdate := bot_ToPublic( hUpdate, cTlgrmJSON )
   if hb_isNIL( oUpdate ) 
      hb_IdleSleep( 5 ) 
      RETURN ::Current()
   endif
   ::oUpdate := oUpdate
   ::nPos    := nPos
   ::nUpdate := hUpdate["update_id"]
   if ::nPos > ::nLen ; ::lEof := .t. ; endif

RETURN ::oUpdate
   


/*
 *
 */
METHOD OnError( uValue ) CLASS TLGRM_UPDATES

  Local cMsg

  if hb_IsNIL( ::oUpdate ) ; return nil ; endif

  cMsg := lower( ALLTRIM(__GetMessage()) )

  If ::oUpdate:IsDef( cMsg )
     Return ::oUpdate:Get( cMsg ) 
  EndIf

RETURN uValue



/*
 * Clase que construye cada elemento (mensaje o entrada) pendiente para procesar.
 */
CLASS TLGRM_Update FROM TPUBLIC

   protected:
   DATA oUpdates
   DATA cTlgrmJSON

   visible:
   METHOD New( cTlgrmJSON )
   METHOD Resume()
   METHOD getJSON()  INLINE ::cTlgrmJSON

   METHOD getFrom()

ENDCLASS



/*
 *
 */
METHOD New( cTlgrmJSON ) CLASS TLGRM_UPDATE

   ::cTlgrmJSON := cTlgrmJSON

//tracelog ::cTlgrmJSON
   ::Super:New()

RETURN Self



/*
 *
 */
METHOD getFrom() CLASS TLGRM_UPDATE

   Do Case
   Case ::type = "callback_query"
      return ::callback_query:from
   Case ::type = "inline_query"
      return ::inline_query:from
   Case ::type = "message"
      return ::message:from
   Other
      tracelog "TYPE INPUT TO BE PROCESSED IN THE CLASS."
   EndCase
RETURN NIL



/*
 *
 */
METHOD Resume() CLASS TLGRM_UPDATE

   local cResume := ""
   local oMsg, oFrom, cLastName, cUserName

   Do Case
   Case ::type = "callback_query"
      oMsg := ::callback_query:message
      oFrom := oMsg:from
      cLastName := iif( oFrom:IsDef("last_name"),oMsg:from:last_name, "" )
      cUserName := iif( oFrom:IsDef("username"),"("+oMsg:from:username+")", "" )
      cResume  += "De: "+hb_eol()
      cResume  += "   Telegram_Id: "+ ALLTRIM(oMsg:from:id )+hb_eol()     +;
                  "   Name: "       + ALLTRIM(oMsg:from:first_name) + " " +;
                                      cLastName +;
                                      iif( !Empty(cUserName),cUserName+hb_eol(),+"")
//      cResume += "Fecha: "+DTOC( NToT( oMsg:date ) ) + hb_eol()
      cResume += "Text: "+::callback_query:data

   Case ::type = "message"
      oMsg := ::message
      oFrom := oMsg:from
      cLastName := iif( oFrom:IsDef("last_name"),oMsg:from:last_name, "" )
      cUserName := iif( oFrom:IsDef("username"),"("+oMsg:from:username+")", "" )
      cResume  += "De: "+hb_eol()
//tracelog NToSTR( oMsg:from:id )
//tracelog hb_valtoexp(oMsg:from )
      cResume  += "De: "+hb_eol()
      cResume  += "   Telegram_Id: "+ ALLTRIM(oMsg:from:id )+hb_eol()     +;
                  "   Name: "       + ALLTRIM(oMsg:from:first_name) + " " +;
                                      cLastName +;
                                      iif( !Empty(cUserName),cUserName+hb_eol(),+"")
//      cResume += "Fecha: "+DTOC( NToT( oMsg:date ) ) + hb_eol()
      if oMsg:IsDef( "text" )
         cResume += "Text: " + oMsg:text
      endif
      

   Other
      tracelog "TYPE INPUT TO BE PROCESSED IN THE CLASS."
      
   EndCase

RETURN cResume


//eof
