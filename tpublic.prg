/*
 *  TPublic().
 *  Clase para el reemplazo de Variables Publicas
 *  Esta basada en la clase original TPublic de
 *  Daniel Andrade Version 2.1
 *
 *  Rosario - Santa Fe - Argentina
 *  andrade_2knews@hotmail.com
 *  http://www.dbwide.com.ar
 *
 *  con Aportes de:
 *     [ER] Eduardo Rizzolo
 *     [WA] Wilson Alves - wolverine@sercomtel.com.br	18/05/2002
 *     [RG] Riztan Gutierrez - riztan@gmail.com 28/10/2008
 *
 *  Sustituido uso de Arreglos por Hashes  [RG]
 *
 *  DATAS
 *	hVars		   - Hash de variables
 *	cName		   - Nombre ultima variable accedida
 *	nPos		   - Valor ultimo variable accedida
 *	lAutomatic	- Asignación automatica, por defecto TRUE	[WA]
 * lSensitive  - Sensibilidad a Mayusculas, por defecto FALSE [RG]
 *
 *  METODOS
 *	New()		- Contructor
 *	Add()		- Agrega/define nueva variable
 *	Del()		- Borra variable
 *	Get()		- Accede a una veriable directamente
 *	Set()		- Define nuevo valor directamente
 *	GetPos()	- Obtener la posición en el Hash
 *	Release()	- Inicializa el Hash
 *	IsDef()		- Chequea si una variable fue definida
 *	Clone()		- Clona el Hash
 *	nCount()	- Devuelve cantidad de variables definidas
 *
 *  NOTA
 *	Para acceder al valor de una variable, se puede hacer de 2 formas,
 *	una directa usando oPub:Get("Codigo") o por Prueba/Error oPub:Codigo,
 *	este último es mas simple de usar pero más lento.
 *
 *	Para definir un nuevo valor a una variable tambien puede ser por 2 formas,
 *	directamente por oPub:Set("Codigo", "ABC" ), o por Prueba/Error
 *	oPub:Codigo := "ABC".
 *
 *	Las variables definidas NO son case sensitive.
 *
 *  ULTIMAS
 *	Se guarda el Nombre y Posición de la última variable accedida para incrementar
 *	la velocidad. (Implementado por Eduardo Rizzolo)
 *
 *  EJEMPLO
 *	FUNCTION Test()
 *	local oP := TPublic():New(), aSave, nPos
 *
 *	oP:Add("Codigo")     // Defino variable sin valor inicial
 *	oP:Add("Precio", 1.15)     // Defino variable con valor inicial
 *	oP:Add("Cantidad", 10 )
 *	oP:Add("TOTAL" )
 *
 *	// Acceso a variables por prueba/error
 *	oP:Total := oP:Precio * oP:Cantidad
 *
 *	// Definicion y Acceso a variables directamente
 *	oP:Set("Total", oP:Get("precio") * oP:Get("CANTIDAD") )
 *
 *	oP:Del("Total")         // Borro una variable
 *	? oP:IsDef("TOTAL")     // Verifico si existe una variable
 *
 *	nPos := oP:GetPos("Total") // Obtengo la posición en el array
 *
 *	oP:Release()         // Borro TODAS las variables
 *
 *	oP:End()       // Termino
 *
 *	RETURN NIL
 *
 *  EXEMPLO (Asignación Automática)
 *
 *	FUNCTION MAIN()
 *	LOCAL oP:=TPublic():New(.T.)
 *
 *	op:nome		:= "Wilson Alves"
 *	op:Endereco	:= "Rua dos Cravos,75"
 *	op:Cidade	:= "Londrina-PR"
 *	op:Celular	:= "9112-5495"
 *	op:Empresa	:= "WCW Software"
 *
 *	? op:Nome,op:Endereco,op:Cidade,op:celular,op:empresa
 *
 *	op:End()
 *	RETURN NIL
 *
 */

#include "hbclass.ch"
#include "common.ch"

/*
 * TPublic()
 */
/**\file tpublic.prg
 * \class TPublic. Clase TPublic
 *
 *  Clase para el reemplazo de Variables Publicas
 *  Esta basada en la clase original TPublic de
 *  Daniel Andrade Version 2.1
 *  
 *  \see Add().
 */
CLASS TPublic

#xtranslate HGetAutoAdd( <hash> )  =>  ( hb_HAutoAdd(<hash>) == 2 )
//#xtranslate HHasKey( <hash>, <cVar> )  =>  ( hb_HHasKey(<hash>,<cVar>) )

   protected:

   DATA  lAutoAdd    AS LOGICAL	 INIT .T.		
   DATA  lSensitive  AS LOGICAL	 INIT .F.		

   ERROR HANDLER OnError( uValue )

   VISIBLE:


   DATA  hVars

   DATA  nPos        AS NUMERIC    INIT 0   // READONLY // [ER]
   DATA  cName       AS CHARACTER  INIT ""  // READONLY // [ER]

   METHOD New( lAutoAdd, lSensitive )          /**New(). */
   METHOD End()            INLINE ::Release()  /**End(). */ 

   METHOD Add( cName, xValue )                 /**Add(). */
   METHOD Del( cName )             
   METHOD Get( cName ) 
   METHOD Set( cName, xValue )

   METHOD GetPos( cName )
   METHOD GetVar( nPos )

   METHOD IsDef( cName )   INLINE hb_hHasKey( ::hVars, cName )

   METHOD Clone()          INLINE HClone( ::hVars )
   METHOD nCount()         INLINE Len( ::hVars )

   METHOD GetArray()           
   METHOD GetVars()        INLINE ::GetArray()
   METHOD VarList()        INLINE ::GetArray()

   METHOD Release()        //INLINE ::hVars := Hash()


ENDCLASS


METHOD RELEASE()  CLASS TPUBLIC
   ::hVars := nil
   self := nil
   hb_gcAll()
RETURN nil


/*
 *  TPublic:New()
 */
/** Metodo Constructor.
 *  Permite generar la instancia de un objeto TPublic,
 *  Se puede inicializar con los parametros lAutomatic y lSensitive, 
 *  para definir si permite la creacion de variables y si admite 
 *  sensibilidad a las mayusculas respectivamente.
*/
METHOD New( lAutoAdd, lSensitive ) CLASS TPublic

   ::hVars := Hash()

   DEFAULT lAutoAdd   TO .T.
   DEFAULT lSensitive TO .F.

   HSetAutoAdd( ::hVars, lAutoAdd )

   HSetCaseMatch( ::hVars, lSensitive )

   ::cName:=""
   ::lAutoAdd  :=lAutoAdd
   ::lSensitive:=lSensitive

RETURN Self

/** 
 *  TPublic:Add()
 */
/** Metodo Add.
 *  Permite adicionar una variable al objeto TPublic,
 *  \param cName.
 *  \param xValue.
 *  \return Self.
*/
METHOD Add( cName, xValue ) CLASS TPublic

   If ::lAutoAdd .AND. !::IsDef( cName )
      HSet( ::hVars, cName, xValue )
   EndIf

RETURN Self

/**
 *  TPublic:Del()
 */
METHOD Del( cName ) CLASS TPublic

   If ::IsDef( cName )
      HDel( ::hVars , cName )
   EndIf
   
RETURN IIF( ::IsDef( cName ), .f., .t. )

/**
 *  TPublic:Get()
 */
METHOD Get( cName ) CLASS TPublic

   Local xRet:=NIL

   If ::IsDef( cName )
      xRet := HGet( ::hVars , cName )
   Endif

RETURN xRet

/**
 *  TPublic:Set()
 */
METHOD Set( cName, xValue ) CLASS TPublic

   //Detectar y convertir valor logico en caso de venir como CHAR
   if left(cName,1)="l" .and. ValType(xValue)="C" .and. ;
                              (xValue $ ".t.T.f.F." )
      xValue := iif( ("t" $ lower(xValue)), .t., .f. )
? "cambiado valor ",cName," a: ", xValue
   endif

   //Detectar y convertir valor fecha en caso de venir como CHAR
   if left(cName,1)="d" .and. ValType(xValue)="C" //.and. ;
                              //CTOD(xValue)<>0
      xValue := CTOD(xValue)
? "cambiado valor ",cName," a fecha "
   endif

   //Detectar y convertir valor numerico en caso de venir como CHAR
   if left(cName,1)="n" .and. ValType(xValue)="C" 
      xValue := VAL(xValue)
? "cambiado valor ",cName," a numérico "
   endif

   If ::IsDef( cName )
      HSet( ::hVars , cName , xValue )
   Else
      ::Add( cName, xValue )
   Endif

RETURN IIF( ::Get(cName)!=xValue, .f., .t. )

/**
 *  TPublic:GetPos() 
 */
METHOD GetPos( cName ) CLASS TPublic
   Local nRet:=0

   If ::IsDef( ::hVars )
      nRet := HGetPos( ::hVars, cName )
   Endif

RETURN nRet


/**
 *  TPublic:GetVar()                         
 */
METHOD GetVar( nPos ) CLASS TPublic

   Local nRet:=0

   If !( nPos > Len(::hVars) )
      nRet := HGetValueAt( ::hVars, nPos )
   Endif
   
RETURN nRet


/**
 *  TPublic:GetArray()
 */
METHOD GetArray() CLASS TPublic

   Local nCont:= 1, nHash:= Len(::hVars)
   Local aRet:=ARRAY( nHash , 2 )
   Local aKeys, aValues

   aKeys  := HGetKeys( ::hVars )
   aValues:= HGetValues( ::hVars )

   While nCont <= nHash

      aRet[ nCont , 1 ]:= aKeys[ nCont ]
      aRet[ nCont , 2 ]:= aValues[ nCont ]
      nCont++

   EndDo

RETURN aRet


/**
 *  OnError()
 */
METHOD OnError( uValue ) CLASS TPublic

  Local cMsg   := UPPE(ALLTRIM(__GetMessage()))
  Local cMsg2  := Subs(cMsg,2)

  If SubStr( cMsg, 1, 1 ) == "_" // Asignar Valor
     If !::IsDef( cMsg2 )
        ::Add( cMsg2 , uValue )
     Else
        ::Set(cMsg2, uValue )
     EndIf
  Else
     If ::IsDef( cMsg )
        Return ::Get( cMsg ) 
     EndIf
  EndIf


RETURN uValue







/** Nuevo TObject
 *
*/
CLASS TObject

   VISIBLE:

   DATA  lAutoAdd    AS LOGICAL	 INIT .T.		
   DATA  lSensitive  AS LOGICAL	 INIT .F.		

   METHOD New( lAutoAdd )                       /**New(). */
   METHOD End()            INLINE ::Release()  /**End(). */ 

   METHOD Add( cName, xValue )                 /**Add(). */
   METHOD Del( cName )             
   METHOD Get( cName ) 
   METHOD Set( cName, xValue )

   METHOD AddMethod( cMethod, pFunc )
   METHOD DelMethod( cMethod )

   METHOD IsDef( cName )   INLINE __objHasData( Self, cName )

   METHOD SendMsg( cMsg, ...  ) 

   METHOD GetArray()       INLINE __objGetValueList( self ) 

   METHOD Release()        INLINE Self := NIL

   ERROR HANDLER OnError( uValue )

ENDCLASS


//------------------------------------------------//
METHOD New( lAutoAdd ) CLASS TObject
   DEFAULT lAutoAdd to .T.

   ::lAutoAdd  :=lAutoAdd
RETURN Self


//------------------------------------------------//
METHOD Add( cName, xValue ) CLASS TObject

   if !::lAutoAdd ; return .f. ; endif

   if !::IsDef(cName)
      __objAddData( Self, cName )

      if !HB_ISNIL(xValue)
          return ::Set(cName, xValue)
      endif 

   endif

RETURN .F.


//------------------------------------------------//
METHOD Del( cName ) CLASS TObject
   if !::IsDef(cName)
      __objDelMethod( Self, cName )
      return .t.
   endif
Return .f.


//------------------------------------------------//
METHOD Get( cName ) CLASS TObject
   //local aData, nPos
   if ::IsDef(cName)
      return ::SendMsg( cName )
   endif
/*
   if __objHasData( Self, cName )
      aData := __objGetValueList(Self)
      nPos  := ASCAN(aData,{|a| a[HB_OO_DATA_SYMBOL]=UPPER(cName) }) 
      return aData[nPos,HB_OO_DATA_VALUE]
   endif
*/
Return nil


//------------------------------------------------//
METHOD Set( cName, xValue ) CLASS TObject
   local uRet
   
   if __objHasData( Self, cName)

   #ifndef __XHARBOUR__
      if xValue == nil
         uRet = __ObjSendMsg( Self, cName )
      else
         uRet = __ObjSendMsg( Self, "_"+cName, xValue )
      endif
   #else   
      if xValue == nil
         uRet = hb_execFromArray( @Self, cName )
      else
         uRet = hb_execFromArray( @Self, cName, { xValue } )
      endif
   #endif    

   endif

return uRet


//------------------------------------------------//
METHOD AddMethod( cMethod, pFunc ) CLASS TObject
 
   if ! __objHasMethod( Self, cMethod )  
      __objAddMethod( Self, cMethod, pFunc )    
   endif

return nil


//------------------------------------------------//
METHOD DelMethod( cMethod ) CLASS TObject
 
   if ! __objHasMethod( Self, cMethod )  
      __objDelMethod( Self, cMethod )    
   endif

return nil


//------------------------------------------------//

#ifndef __XHARBOUR__
METHOD SendMsg( cMsg, ...  ) CLASS TObject
   if "(" $ cMsg
      cMsg = StrTran( cMsg, "()", "" )
   endif
return __ObjSendMsg( Self, cMsg, ... )
#else   
METHOD SendMsg( ... ) CLASS TObject
   local aParams := hb_aParams()
      
   if "(" $ aParams[ 1 ]
      aParams[ 1 ] = StrTran( aParams[ 1 ], "()", "" )
   endif
 
   ASize( aParams, Len( aParams ) + 1 )
   AIns( aParams, 1 )
   aParams[ 1 ] = Self
   
   return hb_execFromArray( aParams )   
#endif 


//------------------------------------------------//
METHOD ONERROR( uValue ) CLASS TObject
   local cCol    := __GetMessage()

   if Left( cCol, 1 ) == "_"
      cCol = Right( cCol, Len( cCol ) - 1 )
   endif
   
   if !::IsDef(cCol)
      ::Add( cCol )
   endif
   
RETURN ::Set(cCol,uValue)

//EOF
