/*
  Copyright 2003-2008 Savonet team

  This file is part of Ocaml-iax.

  Ocaml-iax is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Ocaml-iax is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Ocaml-iax; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/**
 * IAX bindings for OCaml.
 *
 * @author Frank Spijkerman
 */

#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/misc.h>
#include <caml/mlvalues.h>
#include <caml/signals.h>

#include <stdio.h>
#include <string.h>
#include <assert.h>

#include <iax/iax-client.h>
#include <iax/iax.h>

#define Session_val(v) (*((struct iax_session**)Data_custom_val(v)))

static void finalize_session(value v)
{
  struct iax_session *s = Session_val(v);  
  free(s);
}

/* Custom blocks thingy */
static struct custom_operations iax_session_ops = {
  "caml_iax_session",
  finalize_session,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

CAMLprim value value_of_session(struct iax_session *s)
{
  CAMLparam0();
  CAMLlocal1(block);

  block = caml_alloc_custom(&iax_session_ops, sizeof(struct iax_session*), 0, 1);
  Session_val(block) = s;
  CAMLreturn(block);
}

CAMLprim value value_of_event(struct iax_event *event)
{
  CAMLparam0();
  CAMLlocal3(ret,data,tmp);
  int i = 0;
  switch (event->etype)
    {
    case IAX_EVENT_CONNECT:
      data = caml_alloc_tuple(11);
      Store_field(data,i++,caml_copy_string(event->event.connect.callerid));
      Store_field(data,i++,caml_copy_string(event->event.connect.dnid));
      Store_field(data,i++,caml_copy_string(event->event.connect.context));
      Store_field(data,i++,caml_copy_string(event->event.connect.exten));
      Store_field(data,i++,caml_copy_string(event->event.connect.username));
      Store_field(data,i++,caml_copy_string(event->event.connect.hostname));
      Store_field(data,i++,caml_copy_string(event->event.connect.secret));
      Store_field(data,i++,caml_copy_string(event->event.connect.language));
      Store_field(data,i++,Val_int(event->event.connect.portno));
      Store_field(data,i++,caml_callback(*caml_named_value("caml_iax_formats_of_int"),
                                         Val_int(event->event.connect.formats)));
      Store_field(data,i++,Val_int(event->event.connect.version));
      break;
    case IAX_EVENT_HANGUP:
      data = caml_copy_string(event->event.hangup.byemsg);
      break;
    case IAX_EVENT_REJECT:
      data = caml_copy_string(event->event.reject.reason);
      break;
    case IAX_EVENT_VOICE:
      Store_field(data,i++,caml_callback(*caml_named_value("caml_iax_audio_format_of_int"),
                                         Val_int(event->event.voice.format)));
      tmp = caml_alloc_string(event->event.voice.datalen);
      memcpy((char*)tmp,event->event.voice.data,event->event.voice.datalen);
      Store_field(data,i++,tmp);
      break;
    case IAX_EVENT_DTMF:
      data = Val_int(event->event.dtmf.digit);
      break;
    case IAX_EVENT_LAGRQ:
      data = Val_int(event->event.lagrq.ts);
      break;
    case IAX_EVENT_LAGRP:
      data = caml_alloc_tuple(2);
      Store_field(data,i++,Val_int(event->event.lag.lag));
      Store_field(data,i++,Val_int(event->event.lag.jitter));
      break;
    case IAX_EVENT_PING:
    case IAX_EVENT_PONG:
      data = caml_alloc_tuple(2);
      Store_field(data,i++,Val_int(event->event.ping.ts));
      Store_field(data,i++,Val_int(event->event.ping.seqno));
      break;
    case IAX_EVENT_IMAGE:
      Store_field(data,i++,caml_callback(*caml_named_value("caml_iax_image_format_of_int"),
                                         Val_int(event->event.image.format)));
      tmp = caml_alloc_string(event->event.image.datalen);
      memcpy((char*)tmp,event->event.voice.data,event->event.image.datalen);
      Store_field(data,i++,tmp);
      break;
    case IAX_EVENT_AUTHRQ:
      data = caml_alloc_tuple(3);
      // This needs to be extract to a list..
      Store_field(data,i++,caml_callback(*caml_named_value("caml_iax_auth_methods_of_int"),
                                         Val_int(event->event.authrequest.authmethods)));
      Store_field(data,i++,caml_copy_string(event->event.authrequest.challenge));
      Store_field(data,i++,caml_copy_string(event->event.authrequest.username));
      break;
    case IAX_EVENT_AUTHRP:
      data = caml_alloc_tuple(2);
      // This assumes that ocaml auth methods declaration is consistent with the C one.. 
      Store_field(data,i++,Val_int(event->event.authreply.authmethod - 1));
      Store_field(data,i++,caml_copy_string(event->event.authreply.reply));
      break;
    case IAX_EVENT_REGREQ:
      data = caml_alloc_tuple(5);
      Store_field(data,i++,caml_copy_string(event->event.regrequest.server));
      Store_field(data,i++,Val_int(event->event.regrequest.portno));
      Store_field(data,i++,caml_copy_string(event->event.regrequest.peer));
      Store_field(data,i++,caml_copy_string(event->event.regrequest.secret));
      Store_field(data,i++,Val_bool(event->event.regrequest.refresh));
      break;
    case IAX_EVENT_REGREP:
      data = caml_alloc_tuple(5);
      // This assumes consistency between C and ocaml declaration..
      Store_field(data,i++,Val_int(event->event.regreply.status - 1));
      Store_field(data,i++,caml_copy_string(event->event.regreply.ourip));
      Store_field(data,i++,caml_copy_string(event->event.regreply.callerid));
      Store_field(data,i++,Val_int(event->event.regreply.ourport));
      Store_field(data,i++,Val_bool(event->event.regreply.refresh));
      break;
    case IAX_EVENT_URL:
      data = caml_alloc_tuple(2);
      Store_field(data,i++,Val_int(event->event.url.link));
      Store_field(data,i++,caml_copy_string(event->event.url.url));
      break;
    case IAX_EVENT_TRANSFER:
      data = caml_alloc_tuple(2);
      Store_field(data,i++,caml_copy_string(event->event.transfer.newip));
      Store_field(data,i++,Val_int(event->event.transfer.newport));
      break;
    case IAX_EVENT_DPREQ:
      data = caml_copy_string(event->event.dpreq.number);
      break;
    case IAX_EVENT_DPREP:
      data = caml_alloc_tuple(6);
      Store_field(data,i++,caml_copy_string(event->event.dprep.number));
      Store_field(data,i++,Val_bool(event->event.dprep.exists));
      Store_field(data,i++,Val_bool(event->event.dprep.canexist));
      Store_field(data,i++,Val_bool(event->event.dprep.nonexistant));
      Store_field(data,i++,Val_bool(event->event.dprep.ignorepat));
      Store_field(data,i++,Val_int(event->event.dprep.expirey));
      break;
    case IAX_EVENT_DIAL:
      data = caml_copy_string(event->event.dial.number);
      break;
    case IAX_EVENT_TEXT:
      // Size hardcoded in the header
      data = caml_alloc_string(8192);
      memcpy((char*)data,event->event.text.text,8192);
      break;
    // Empty events
    case IAX_EVENT_ACCEPT:
    case IAX_EVENT_TIMEOUT:
    case IAX_EVENT_RINGA:
    case IAX_EVENT_BUSY:
    case IAX_EVENT_ANSWER:
    case IAX_EVENT_QUELCH:
    case IAX_EVENT_UNQUELCH:
    case IAX_EVENT_UNLINK:
    case IAX_EVENT_LDCOMPLETE:
    case IAX_EVENT_LINKREJECT:
      data = Val_unit;
      break;
    default:
      caml_failwith("Unknown event type");
    }

  ret = caml_alloc_tuple(3);
  Store_field(ret,0,event->etype);
  Store_field(ret,1,value_of_session(event->session));
  Store_field(ret,2,data);
    
  CAMLreturn(ret);
}

static char *copy_string(value v) 
{
  int n = caml_string_length(v)  + 1;
  char *ret = malloc(n);
  if (ret == NULL) 
    caml_failwith("malloc");
  strcpy(ret,String_val(v));
  return ret;
}

static struct iax_event *event_of_value(value type, value v) 
{
  int i = 0;
  value tmp;
  struct iax_event *event = malloc(sizeof(struct iax_event));
  if (event == NULL) caml_failwith("malloc");
  switch (Int_val(type))
    {
    case IAX_EVENT_CONNECT:
      event->event.connect.callerid = copy_string(Field(v,i++));
      event->event.connect.dnid = copy_string(Field(v,i++));
      event->event.connect.context = copy_string(Field(v,i++));
      event->event.connect.exten = copy_string(Field(v,i++));
      event->event.connect.username = copy_string(Field(v,i++));
      event->event.connect.hostname = copy_string(Field(v,i++));
      event->event.connect.secret = copy_string(Field(v,i++));
      event->event.connect.language = copy_string(Field(v,i++));
      event->event.connect.portno = Int_val(Field(v,i++));
      event->event.connect.formats = Int_val(caml_callback(*caml_named_value("caml_iax_int_of_formats"),                                                          Field(v,i++)));
      event->event.connect.version = Int_val(Field(v,i++));
      break;
    case IAX_EVENT_HANGUP:
      event->event.hangup.byemsg = copy_string(v);
      break;
    case IAX_EVENT_REJECT:
      event->event.reject.reason = copy_string(v);
      break;
    case IAX_EVENT_VOICE:
      event->event.voice.format = Int_val(caml_callback(*caml_named_value("caml_iax_int_of_audio_format"),                                                          Field(v,i++)));
      tmp = Field(v,i++);
      event->event.voice.data = copy_string(tmp);
      event->event.voice.datalen = caml_string_length(tmp);
      break;
    case IAX_EVENT_DTMF:
      event->event.dtmf.digit = Int_val(v);
      break;
    case IAX_EVENT_LAGRQ:
      event->event.lagrq.ts = Int_val(v);
      break;
    case IAX_EVENT_LAGRP:
      event->event.lag.lag = Int_val(Field(v,i++));
      event->event.lag.jitter = Int_val(Field(v,i++));
      break;
    case IAX_EVENT_PING:
    case IAX_EVENT_PONG:
      event->event.ping.ts = Int_val(Field(v,i++));
      event->event.ping.seqno = Int_val(Field(v,i++));
      break;
    case IAX_EVENT_IMAGE:
      event->event.image.format = Int_val(caml_callback(*caml_named_value("caml_iax_int_of_image_format"),                                                          Field(v,i++)));
      tmp = Field(v,i++);
      event->event.image.data = copy_string(tmp);
      event->event.image.datalen = caml_string_length(tmp);
      break;
    case IAX_EVENT_AUTHRQ:
      event->event.authrequest.authmethods = Int_val(caml_callback(*caml_named_value("caml_iax_int_of_auth_methods"),                                                          Field(v,i++)));
      event->event.authrequest.challenge = copy_string(Field(v,i++));
      event->event.authrequest.username = copy_string(Field(v,i++));
      break;
    case IAX_EVENT_AUTHRP:
      // This assumes that ocaml auth methods declaration is consistent with the C one.. 
      event->event.authreply.authmethod = Int_val(Field(v,i++)) + 1;
      event->event.authreply.reply = copy_string(Field(v,i++));
      break;
    case IAX_EVENT_REGREQ:
      event->event.regrequest.server = copy_string(Field(v,i++));
      event->event.regrequest.portno = Int_val(Field(v,i++));
      event->event.regrequest.peer = copy_string(Field(v,i++));
      event->event.regrequest.secret = copy_string(Field(v,i++));
      event->event.regrequest.refresh = Int_val(Field(v,i++));
      break;
    case IAX_EVENT_REGREP:
      // This assumes consistency between C and ocaml declaration..
      event->event.regreply.status = Int_val(Field(v,i++)) + 1;
      event->event.regreply.ourip = copy_string(Field(v,i++));
      event->event.regreply.callerid = copy_string(Field(v,i++));
      event->event.regreply.ourport = Int_val(Field(v,i++));
      event->event.regreply.refresh = Int_val(Field(v,i++));
      break;
    case IAX_EVENT_URL:
      event->event.url.link = Int_val(Field(v,i++));
      event->event.url.url = copy_string(Field(v,i++));
      break;
    case IAX_EVENT_TRANSFER:
      event->event.transfer.newip = copy_string(Field(v,i++));
      event->event.transfer.newport = Int_val(Field(v,i++));
      break;
    case IAX_EVENT_DPREQ:
      event->event.dpreq.number = copy_string(v);
      break;
    case IAX_EVENT_DPREP:
      event->event.dprep.number = copy_string(Field(v,i++));
      event->event.dprep.exists = Int_val(Field(v,i++));
      event->event.dprep.canexist = Int_val(Field(v,i++));
      event->event.dprep.nonexistant = Int_val(Field(v,i++));
      event->event.dprep.ignorepat = Int_val(Field(v,i++));
      event->event.dprep.expirey = Int_val(Field(v,i++));
      break;
    case IAX_EVENT_DIAL:
      event->event.dial.number = copy_string(v);
      break;
    case IAX_EVENT_TEXT:
      // Size hardcoded in the header
      memcpy(String_val(v),event->event.text.text,8192);
      break;
    // Empty events
    case IAX_EVENT_ACCEPT:
    case IAX_EVENT_TIMEOUT:
    case IAX_EVENT_RINGA:
    case IAX_EVENT_BUSY:
    case IAX_EVENT_ANSWER:
    case IAX_EVENT_QUELCH:
    case IAX_EVENT_UNQUELCH:
    case IAX_EVENT_UNLINK:
    case IAX_EVENT_LDCOMPLETE:
    case IAX_EVENT_LINKREJECT:
      // Nothing !
      break;
    default:
      caml_failwith("Unknown event type");
    }

   event->etype = Int_val(type);
   return event;
}

static value check_error(value x)
{
  if (Int_val(x) < 0) 
    caml_raise_constant(*caml_named_value("iax_session_exn_error"));
  return x;
}

/**
 * IAX API stuff here
 *
 */

CAMLprim value ocaml_iax_init(value port)
{
	CAMLparam1(port);
	int rv = iax_init(Int_val(port)); // param1 = port
	CAMLreturn(check_error(Val_int(rv)));
}

CAMLprim value ocaml_iax_get_fd(void)
{
	CAMLparam0();
	CAMLreturn(Val_int(iax_get_fd()));
}

CAMLprim value ocaml_iax_time_to_next_event(void)
{
	CAMLparam0();
	CAMLreturn(Val_int(iax_time_to_next_event()));
}

CAMLprim value ocaml_iax_session_new(void)
{
	CAMLparam0();
	CAMLlocal1(block);

	struct iax_session *s = iax_session_new();
	if (s == NULL) 
		caml_raise_constant(*caml_named_value("iax_session_exn_malloc"));
	block = caml_alloc_custom(&iax_session_ops, sizeof(struct iax_session*), 0, 1);
	Session_val(block) = s;
	CAMLreturn(block);
} 

CAMLprim value ocaml_iax_do_event(value session, value type, value event)
{
	return check_error(Val_int(iax_do_event(Session_val(session), event_of_value(type,event))));
}

CAMLprim value ocaml_iax_get_event(value blocking)
{
	CAMLparam1(blocking);
	int b = Bool_val(blocking);

	/* This call can be blocking.. */
	caml_enter_blocking_section();
	struct iax_event *e = iax_get_event(b);
	caml_leave_blocking_section();

	if (e == NULL)
		caml_raise_constant(*caml_named_value("iax_session_exn_no_event"));
	CAMLreturn(value_of_event(e));
}

CAMLprim value ocaml_iax_auth_reply(value session, value pass, value chal, value methods)
{
	CAMLparam4(session, pass, chal, methods);

	int ret = iax_auth_reply(Session_val(session), 
		String_val(pass), String_val(chal), Int_val(methods));

	CAMLreturn(check_error(Val_int(ret)));
}
/*
CAMLprim ocaml_iax_end(void)
{
	//CAMLparam0();
	iax_end();
	//CAMLreturn0;
}
*/

void ocaml_iax_set_formats(value format)
{
	CAMLparam1(format);
	iax_set_formats(Int_val(format));
	CAMLreturn0;
}

CAMLprim value ocaml_iax_register(value session, value host, value peer, value secret, value refresh)
{
	CAMLparam5(session, host, peer, secret, refresh);
	int n = iax_register(Session_val(session), String_val(host), String_val(peer), String_val(secret), Int_val(refresh));
        check_error(Val_int(n)); 
	CAMLreturn(Val_unit);
}

CAMLprim value ocaml_iax_lag_request(value session)
{
	CAMLparam1(session);
	CAMLreturn(check_error(Val_int(iax_lag_request(Session_val(session)))));
}

