/*  $Id: tpy_hb.ch,v 1.00 2015/01/07 13:40 riztan Exp $ */
/*
	Copyright © 2008  Riztan Gutierrez <riztang@gmail.org>

   Este programa es software libre: usted puede redistribuirlo y/o modificarlo 
   conforme a los términos de la Licencia Pública General de GNU publicada por
   la Fundación para el Software Libre, ya sea la versión 3 de esta Licencia o 
   (a su elección) cualquier versión posterior.

   Este programa se distribuye con el deseo de que le resulte útil, pero 
   SIN GARANTÍAS DE NINGÚN TIPO; ni siquiera con las garantías implícitas de
   COMERCIABILIDAD o APTITUD PARA UN PROPÓSITO DETERMINADO. Para más información, 
   consulte la Licencia Pública General de GNU.

   http://www.gnu.org/licenses/
*/

#include "utc.ch"
//#include "xhb.ch"
//#include "hbcompat.ch"
#include "common.ch"
//#include "hbxml.ch"

#ifdef __UTC__
  #xtranslate date() => DateUTC()
  #xtranslate time() => TimeUTC()
  #xtranslate hb_dateTime() => dateTimeUTC()
#endif


#xtranslate tracelog <aElements,...> => QOUT( procname(),": ",<aElements> )
//#xtranslate tracelog <xValues, ...> => QOUT( "TPuy."+ALLTRIM(procname())+;
//                                             "("+ALLTRIM(STR(procline()))+") ",;
#xtranslate tracelog LINE => QOUT( Repl("-",30) )

#xtranslate NToStr( <nValue> ) => ALLTRIM(STR(<nValue>))

#xtranslate UTF_8( <exp> ) => hb_StrToUtf8(<exp>)

#xcommand DEFAULT <v1> := <x1> [, <vn> := <xn> ] => ;
                                IF <v1> == NIL ; <v1> := <x1> ; END ;
                                [; IF <vn> == NIL ; <vn> := <xn> ; END ]

//eof
