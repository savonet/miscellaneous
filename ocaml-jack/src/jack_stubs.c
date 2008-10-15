/* $Id$ */

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
#include <pthread.h>
#include <assert.h>
#include <jack/jack.h>
#include <jack/ringbuffer.h>
#include <jack/statistics.h>

static void check_for_err(int ret)
{
  if (ret)
    caml_raise_with_arg(*caml_named_value("jack_exn_jack_error"), Val_int(ret));
}

static value error_function = (value)NULL;

static void custom_error_function(const char *msg)
{
  /* TODO: leave blocking sections! */
  caml_callback(error_function, caml_copy_string(msg));
}

CAMLprim value ocaml_jack_set_error_function(value f)
{
  CAMLparam1(f);

  if (!error_function)
    caml_register_global_root(&error_function);
  error_function = f;
  jack_set_error_function(custom_error_function);

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_get_sample_size(value unit)
{
  CAMLparam1(unit);
  CAMLreturn(Val_int(sizeof(jack_default_audio_sample_t)));
}

/***************
 * Ringbuffers *
 ***************/

typedef struct {
  jack_ringbuffer_t *jrb;
  pthread_mutex_t *mutex;
} caml_ringbuffer_t;

#define Ringbuffer_val(v) (*(caml_ringbuffer_t**)Data_custom_val(v))

static void finalize_ringbuffer(value rbv)
{
  caml_ringbuffer_t *rb = Ringbuffer_val(rbv);
  jack_ringbuffer_free(rb->jrb);
  free(rb->mutex);
  free(rb);
}

static struct custom_operations ringbuffer_ops =
{
  "ocaml_jack_ringbuffer",
  finalize_ringbuffer,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

CAMLprim value ocaml_jack_ringbuffer_create(value size)
{
  CAMLparam1(size);
  CAMLlocal1(rbv);
  caml_ringbuffer_t *rb;

  rb = malloc(sizeof(caml_ringbuffer_t));
  rb->jrb = jack_ringbuffer_create(Int_val(size));
  rb->mutex = malloc(sizeof(pthread_mutex_t));
  assert(!pthread_mutex_init(rb->mutex, NULL));
  rbv = caml_alloc_custom(&ringbuffer_ops, sizeof(caml_ringbuffer_t*), 0, 1);
  Ringbuffer_val(rbv) = rb;

  CAMLreturn(rbv);
}

CAMLprim value ocaml_jack_ringbuffer_mlock(value rbv)
{
  CAMLparam1(rbv);
  int ret;

  ret = jack_ringbuffer_mlock(Ringbuffer_val(rbv)->jrb);
  if (ret)
    caml_raise_constant(*caml_named_value("jack_exn_mlock_failed"));

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_ringbuffer_read(value rbv, value buf, value ofs, value len)
{
  CAMLparam4(rbv, buf, ofs, len);
  size_t n;

  pthread_mutex_lock(Ringbuffer_val(rbv)->mutex);
  n = jack_ringbuffer_read(Ringbuffer_val(rbv)->jrb, String_val(buf) + Int_val(ofs), Int_val(len));
  pthread_mutex_unlock(Ringbuffer_val(rbv)->mutex);

  CAMLreturn(Val_int(n));
}

CAMLprim value ocaml_jack_ringbuffer_read32f(value rbv, value buf, value _ofs, value _len)
{
  CAMLparam2(rbv, buf);
  size_t n;
  int len = Int_val(_len);
  int ofs = Int_val(_ofs);
  float *tmpbuf = malloc(len*4);
  int i;

  if (Wosize_val(buf)/Double_wosize < ofs + len)
  {
    printf("buffer has size %d, at least %d is expected\n", (int)Wosize_val(buf)/Double_wosize, ofs + len),
    assert(0);
  }

  pthread_mutex_lock(Ringbuffer_val(rbv)->mutex);
  n = jack_ringbuffer_read(Ringbuffer_val(rbv)->jrb, (char*)tmpbuf, len*4);
  pthread_mutex_unlock(Ringbuffer_val(rbv)->mutex);

  for (i=0; i < n/4; i++)
    Store_double_field(buf, i+ofs, tmpbuf[i]);

  free(tmpbuf);
  CAMLreturn(Val_int(n/4));
}

CAMLprim value ocaml_jack_ringbuffer_read_advance(value rbv, value ofs)
{
  CAMLparam2(rbv, ofs);

  pthread_mutex_lock(Ringbuffer_val(rbv)->mutex);
  jack_ringbuffer_read_advance(Ringbuffer_val(rbv)->jrb, Int_val(ofs));
  pthread_mutex_unlock(Ringbuffer_val(rbv)->mutex);

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_ringbuffer_read_space(value rbv)
{
  CAMLparam1(rbv);
  size_t n;

  pthread_mutex_lock(Ringbuffer_val(rbv)->mutex);
  n = jack_ringbuffer_read_space(Ringbuffer_val(rbv)->jrb);
  pthread_mutex_unlock(Ringbuffer_val(rbv)->mutex);

  CAMLreturn(Val_int(n));
}

CAMLprim value ocaml_jack_ringbuffer_reset(value rbv)
{
  CAMLparam1(rbv);

  pthread_mutex_lock(Ringbuffer_val(rbv)->mutex);
  jack_ringbuffer_reset(Ringbuffer_val(rbv)->jrb);
  pthread_mutex_unlock(Ringbuffer_val(rbv)->mutex);

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_ringbuffer_write(value rbv, value buf, value ofs, value len)
{
  CAMLparam4(rbv, buf, ofs,  len);
  size_t n;

  pthread_mutex_lock(Ringbuffer_val(rbv)->mutex);
  n = jack_ringbuffer_write(Ringbuffer_val(rbv)->jrb, String_val(buf) + Int_val(ofs), Int_val(len));
  pthread_mutex_unlock(Ringbuffer_val(rbv)->mutex);

  CAMLreturn(Val_int(n));
}

CAMLprim value ocaml_jack_ringbuffer_write32f(value rbv, value buf, value ofs, value len)
{
  CAMLparam4(rbv, buf, ofs, len);
  size_t n;
  float *tmpbuf = malloc(Int_val(len)*4);
  int i;

  for (i=0; i<Int_val(len); i++)
    tmpbuf[i] = Double_field(buf, i+Int_val(ofs));

  pthread_mutex_lock(Ringbuffer_val(rbv)->mutex);
  n = jack_ringbuffer_write(Ringbuffer_val(rbv)->jrb, (char*)tmpbuf, Int_val(len)*4);
  pthread_mutex_unlock(Ringbuffer_val(rbv)->mutex);

  free(tmpbuf);
  CAMLreturn(Val_int(n/4));
}

CAMLprim value ocaml_jack_ringbuffer_write_advance(value rbv, value len)
{
  CAMLparam2(rbv, len);

  pthread_mutex_lock(Ringbuffer_val(rbv)->mutex);
  jack_ringbuffer_write_advance(Ringbuffer_val(rbv)->jrb, Int_val(len));
  pthread_mutex_unlock(Ringbuffer_val(rbv)->mutex);

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_ringbuffer_write_space(value rbv)
{
  CAMLparam1(rbv);
  size_t n;

  pthread_mutex_lock(Ringbuffer_val(rbv)->mutex);
  n = jack_ringbuffer_write_space(Ringbuffer_val(rbv)->jrb);
  pthread_mutex_unlock(Ringbuffer_val(rbv)->mutex);

  CAMLreturn(Val_int(n));
}

/*********
 * Ports *
 *********/

#define Port_val(v) ((jack_port_t*)v)
#define Val_port(p) ((value)p)

CAMLprim value ocaml_jack_port_name(value pv)
{
  CAMLparam1(pv);
  CAMLreturn(caml_copy_string(jack_port_name(Port_val(pv))));
}

CAMLprim value ocaml_jack_port_set_name(value pv, value name)
{
  CAMLparam2(pv, name);
  check_for_err(jack_port_set_name(Port_val(pv), String_val(name)));
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_port_short_name(value pv)
{
  CAMLparam1(pv);
  CAMLreturn(caml_copy_string(jack_port_short_name(Port_val(pv))));
}

CAMLprim value ocaml_jack_port_flags(value pv)
{
  CAMLparam1(pv);
  CAMLlocal1(ret);
  int i = 0, n = 0;
  int flags = jack_port_flags(Port_val(pv));

  if (flags & JackPortIsInput)
    n++;
  if (flags & JackPortIsOutput)
    n++;
  if (flags & JackPortIsPhysical)
    n++;
  if (flags & JackPortCanMonitor)
    n++;
  if (flags & JackPortIsTerminal)
    n++;

  ret = caml_alloc_tuple(n);
  if (flags & JackPortIsInput)
    Store_field(ret, i++, Val_int(0));
  if (flags & JackPortIsOutput)
    Store_field(ret, i++, Val_int(1));
  if (flags & JackPortIsPhysical)
    Store_field(ret, i++, Val_int(2));
  if (flags & JackPortCanMonitor)
    Store_field(ret, i++, Val_int(3));
  if (flags & JackPortIsTerminal)
    Store_field(ret, i++, Val_int(4));

  CAMLreturn(ret);
}

static unsigned long long_of_flags_list(value flags)
{
  unsigned long ret = 0;

  while (!Is_long(flags))
  {
      switch (Int_val(Field(flags, 0)))
      {
          case 0:
              ret |= JackPortIsInput;
              break;

          case 1:
              ret |= JackPortIsOutput;
              break;

          case 2:
              ret |= JackPortIsPhysical;
              break;

          case 3:
              ret |= JackPortCanMonitor;
              break;

          case 4:
              ret |= JackPortIsTerminal;
              break;

          default:
              break;
      }
      flags = Field(flags, 1);
  }

  return (ret);
}

CAMLprim value ocaml_jack_port_type(value pv)
{
  CAMLparam1(pv);
  CAMLreturn(caml_copy_string(jack_port_type(Port_val(pv))));
}

CAMLprim value ocaml_jack_port_connected(value pv)
{
  CAMLparam1(pv);
  CAMLreturn(Val_int(jack_port_connected(Port_val(pv))));
}

CAMLprim value ocaml_jack_port_connected_to(value pv, value pn)
{
  CAMLparam2(pv, pn);
  CAMLreturn(Val_int(jack_port_connected_to(Port_val(pv), String_val(pn))));
}

CAMLprim value ocaml_jack_port_set_latency(value pv, value frames)
{
  CAMLparam2(pv, frames);
  jack_port_set_latency(Port_val(pv), Int_val(frames));
  CAMLreturn(Val_unit);
}

/****************
 * Jack clients *
 ****************/

#define DIR_READ 0
#define DIR_WRITE 1

typedef struct
{
  jack_client_t *client;
  value on_shutdown_callback;
  value caml_buffer_mutex;
  value caml_buffer_data_ready;
  pthread_mutex_t *buffer_mutex; /* callback protecting the ringbuffers */
  pthread_cond_t *buffer_data_ready; /* some data is ready in the buffers */
  pthread_t *client_process_callback_poller;
  value *client_process_callback_ringbuffersv; /* ringbuffers used by callback functions, it is a couple inputing / output ringbuffer, needed for the caml_register_global_root */
  /* TODO: array of tuples? */
  caml_ringbuffer_t **client_process_callback_ringbuffers; /* C version of the ringbuffers */
  int client_process_callback_ringbuffers_nb; /* size of the client_process_callback_ringbuffer array */
  jack_port_t **client_process_callback_ringbuffers_port;
  int *client_process_callback_ringbuffers_dir; /* read / write direction for each buffer in client_process_callback_ringbuffer array */
} caml_client_t;

#define Caml_client_val(v) (*(caml_client_t**)Data_custom_val(v))
#define Client_val(v) (Caml_client_val(v)->client)

static void remove_process_callback(caml_client_t *cc)
{
  int i;

  if (!cc->client_process_callback_ringbuffersv)
  {
    return;
  }

  for (i = 0; i < cc->client_process_callback_ringbuffers_nb; i++)
    caml_remove_global_root(&cc->client_process_callback_ringbuffersv[i]);
  cc->client_process_callback_ringbuffers_nb = 0;
  free(cc->client_process_callback_ringbuffers);
  cc->client_process_callback_ringbuffers = NULL;
  free(cc->client_process_callback_ringbuffersv);
  cc->client_process_callback_ringbuffersv = (value)NULL;
  free(cc->client_process_callback_ringbuffers_port);
  cc->client_process_callback_ringbuffers_port = NULL;
}

static void finalize_client(value cv)
{
  caml_client_t *cc = Caml_client_val(cv);
  if (cc->on_shutdown_callback)
    caml_remove_global_root(&cc->on_shutdown_callback);
  caml_remove_global_root(&cc->caml_buffer_data_ready);
  caml_remove_global_root(&cc->caml_buffer_mutex);
  free(cc->buffer_data_ready);
  free(cc->buffer_mutex);
  if (cc->client_process_callback_poller)
  {
    /* TODO: kill polling thread */
    free(cc->client_process_callback_poller);
  }
  remove_process_callback(cc);
  free(cc);
}

static struct custom_operations client_ops =
{
  "ocaml_jack_client",
  finalize_client,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static void* poll_for_callback(void *arg)
{
  caml_client_t *cc = (caml_client_t*)arg;

  pthread_mutex_lock(cc->buffer_mutex);
  while(1)
  {
    caml_callback(*caml_named_value("caml_mutex_unlock"), cc->caml_buffer_mutex);
    pthread_cond_wait(cc->buffer_data_ready, cc->buffer_mutex);
    pthread_mutex_unlock(cc->buffer_mutex);
    caml_callback(*caml_named_value("caml_condition_signal"), cc->caml_buffer_data_ready);
    pthread_mutex_lock(cc->buffer_mutex);
    caml_callback(*caml_named_value("caml_mutex_lock"), cc->caml_buffer_mutex);
  }
  pthread_mutex_unlock(cc->buffer_mutex);
}

CAMLprim value ocaml_jack_client_new(value name)
{
  CAMLparam1(name);
  CAMLlocal1(cv);
  jack_client_t *jc;
  caml_client_t *cc;

  jc = jack_client_new(String_val(name));
  if (!jc)
    caml_raise(*caml_named_value("jack_exn_client_creation_error"));
  cc = malloc(sizeof(caml_client_t));
  cc->client = jc;
  cc->on_shutdown_callback = (value)NULL;
  cc->client_process_callback_ringbuffersv = (value)NULL;
  cc->client_process_callback_ringbuffers = NULL;
  cc->client_process_callback_ringbuffers_nb = 0;
  cc->client_process_callback_ringbuffers_port = NULL;
  cc->client_process_callback_ringbuffers_dir = (value)NULL;
  cv = caml_alloc_custom(&client_ops, sizeof(caml_client_t*), 0, 1);
  Caml_client_val(cv) = cc;

  caml_register_global_root(&cc->caml_buffer_mutex);
  caml_register_global_root(&cc->caml_buffer_data_ready);
  cc->caml_buffer_mutex = caml_callback(*caml_named_value("caml_mutex_create"), Val_unit);
  cc->caml_buffer_data_ready = caml_callback(*caml_named_value("caml_condition_create"), Val_unit);
  cc->buffer_mutex = malloc(sizeof(pthread_mutex_t));
  assert(!pthread_mutex_init(cc->buffer_mutex, NULL));
  cc->buffer_data_ready = malloc(sizeof(pthread_cond_t));
  assert(!pthread_cond_init(cc->buffer_data_ready, NULL));
  cc->client_process_callback_poller = NULL;

  CAMLreturn(cv);
}

CAMLprim value ocaml_jack_start_poller(value cv)
{
  CAMLparam1(cv);
  caml_client_t *cc = Caml_client_val(cv);

  if (!cc->client_process_callback_poller)
  {
    cc->client_process_callback_poller = malloc(sizeof(pthread_t));
    pthread_create(cc->client_process_callback_poller, NULL, poll_for_callback, cc);
  }

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_client_close(value cv)
{
  CAMLparam1(cv);

  check_for_err(jack_client_close(Client_val(cv)));

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_is_realtime(value cv)
{
  CAMLparam1(cv);
  CAMLreturn(Val_int(jack_is_realtime(Client_val(cv))));
}

static int ringbuffer_callback(jack_nframes_t nframes, void *arg)
{
  int i;
  jack_default_audio_sample_t *port_buf;
  caml_client_t *cc = (caml_client_t*)arg;

  pthread_mutex_lock(cc->buffer_mutex);
  for (i = 0; i < cc->client_process_callback_ringbuffers_nb; i++)
  {
    port_buf = jack_port_get_buffer(cc->client_process_callback_ringbuffers_port[i], nframes);
    pthread_mutex_lock(cc->client_process_callback_ringbuffers[i]->mutex);
    if (cc->client_process_callback_ringbuffers_dir[i] == DIR_READ)
      jack_ringbuffer_read(cc->client_process_callback_ringbuffers[i]->jrb, (char*)port_buf, sizeof(jack_default_audio_sample_t) * nframes);
    else
      jack_ringbuffer_write(cc->client_process_callback_ringbuffers[i]->jrb, (char*)port_buf, sizeof(jack_default_audio_sample_t) * nframes);
    pthread_mutex_unlock(cc->client_process_callback_ringbuffers[i]->mutex);
  }
  pthread_cond_signal(cc->buffer_data_ready);
  pthread_mutex_unlock(cc->buffer_mutex);

  return 0;
}

CAMLprim value ocaml_jack_set_process_ringbuffer_callback(value cv, value bufs)
{
  CAMLparam2(cv, bufs);
  int i;
  caml_client_t *cc = Caml_client_val(cv);

  remove_process_callback(cc);
  if (Is_long(bufs))
    CAMLreturn(Val_unit);

  cc->client_process_callback_ringbuffers_nb = Wosize_val(bufs);
  cc->client_process_callback_ringbuffersv = malloc(sizeof(value) * cc->client_process_callback_ringbuffers_nb);
  cc->client_process_callback_ringbuffers = malloc(sizeof(caml_ringbuffer_t*) * cc->client_process_callback_ringbuffers_nb);
  cc->client_process_callback_ringbuffers_port = malloc(sizeof(jack_port_t*) * cc->client_process_callback_ringbuffers_nb);
  cc->client_process_callback_ringbuffers_dir = malloc(sizeof(int) * cc->client_process_callback_ringbuffers_nb);
  for (i = 0; i < cc->client_process_callback_ringbuffers_nb; i++)
  {
    caml_register_global_root(&cc->client_process_callback_ringbuffersv[i]);
    cc->client_process_callback_ringbuffersv[i] = Field(Field(bufs, i), 1);
    cc->client_process_callback_ringbuffers[i] = Ringbuffer_val(cc->client_process_callback_ringbuffersv[i]);
    cc->client_process_callback_ringbuffers_port[i] = Port_val(Field(Field(bufs, i), 0));
    cc->client_process_callback_ringbuffers_dir[i] = Int_val(Field(Field(bufs, i), 2));
  }
  jack_set_process_callback(Client_val(cv), ringbuffer_callback, cc);

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_get_process_callback_mutex(value cv)
{
  CAMLparam1(cv);
  caml_client_t *cc = Caml_client_val(cv);
  CAMLreturn(cc->caml_buffer_mutex);
}

CAMLprim value ocaml_jack_get_process_callback_condition(value cv)
{
  CAMLparam1(cv);
  caml_client_t *cc = Caml_client_val(cv);
  CAMLreturn(cc->caml_buffer_data_ready);
}

CAMLprim value ocaml_jack_activate(value cv)
{
  CAMLparam1(cv);

  check_for_err(jack_activate(Client_val(cv)));

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_deactivate(value cv)
{
  CAMLparam1(cv);

  check_for_err(jack_deactivate(Client_val(cv)));

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_connect(value cv, value src, value dst)
{
  CAMLparam3(cv, src, dst);

  check_for_err(jack_connect(Client_val(cv), String_val(src), String_val(dst)));

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_disconnect(value cv, value src, value dst)
{
  CAMLparam3(cv, src, dst);

  check_for_err(jack_disconnect(Client_val(cv), String_val(src), String_val(dst)));

  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_port_by_name(value cv, value name)
{
  CAMLparam2(cv, name);

  CAMLreturn(Val_port(jack_port_by_name(Client_val(cv), String_val(name))));
}

CAMLprim value ocaml_jack_get_ports(value cv, value port_name_pattern, value type_name_pattern, value flags)
{
  CAMLparam4(cv, port_name_pattern, type_name_pattern, flags);
  CAMLlocal1(ans);
  const char **ports;
  char *pnp, *tnp;
  int i, n=0;

  if (!String_val(port_name_pattern)[0])
    pnp = NULL;
  else
    pnp = String_val(port_name_pattern);
  if (!String_val(type_name_pattern)[0])
    tnp = NULL;
  else
    tnp = String_val(type_name_pattern);

  ports = jack_get_ports(Client_val(cv), pnp, tnp, Int_val(flags));

  if (!ports)
  {
    ans = caml_alloc_tuple(0);
    CAMLreturn(ans);
  }

  while (ports[n]) n++;
  ans = caml_alloc_tuple(n);
  for (i=0; i<n; i++)
    Store_field(ans, i, caml_copy_string(ports[i]));

  free(ports);

  CAMLreturn(ans);
}

CAMLprim value ocaml_jack_port_get_all_connections(value cv, value port)
{
  CAMLparam2(cv, port);
  CAMLlocal1(ans);
  const char **ports;
  int i, n=0;

  ports = jack_port_get_all_connections(Client_val(cv), Port_val(port));

  if (!ports)
  {
    ans = caml_alloc_tuple(0);
    CAMLreturn(ans);
  }

  while (ports[n]) n++;
  ans = caml_alloc_tuple(n);
  for (i=0; i<n; i++)
    Store_field(ans, i, caml_copy_string(ports[i]));

  free(ports);

  CAMLreturn(ans);
}

CAMLprim value ocaml_jack_frame_time(value cv)
{
  CAMLparam1(cv);
  CAMLreturn(Val_int(jack_frame_time(Client_val(cv))));
}

CAMLprim value ocaml_jack_frames_since_cycle_start(value cv)
{
  CAMLparam1(cv);
  CAMLreturn(Val_int(jack_frames_since_cycle_start(Client_val(cv))));
}

CAMLprim value ocaml_jack_get_buffer_size(value cv)
{
  CAMLparam1(cv);
  CAMLreturn(Val_int(jack_get_buffer_size(Client_val(cv))));
}

CAMLprim value ocaml_jack_get_cpu_load(value cv)
{
  CAMLparam1(cv);
  CAMLreturn(caml_copy_double(jack_cpu_load(Client_val(cv))));
}

static void on_shutdown_callback(void *arg)
{
  caml_client_t *cc = (caml_client_t*)arg;
  /* TODO: this does not play nicely with blocking sections. */
  caml_callback(cc->on_shutdown_callback, Val_unit);
}

CAMLprim value ocaml_jack_on_shutdown(value cv, value cb)
{
  CAMLparam2(cv, cb);
  caml_client_t *cc = Caml_client_val(cv);
  cc->on_shutdown_callback = cb;
  caml_register_global_root(&cc->on_shutdown_callback);
  jack_on_shutdown(cc->client, on_shutdown_callback, cc);
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_port_register(value cv, value name, value type, value flags, value bufsize)
{
  CAMLparam5(cv, name, type, flags, bufsize);
  CAMLreturn(Val_port(jack_port_register(Client_val(cv), String_val(name), String_val(type), long_of_flags_list(flags), Int_val(bufsize))));
}

CAMLprim value ocaml_jack_get_sample_rate(value cv)
{
  CAMLparam1(cv);
  CAMLreturn(Val_int(jack_get_sample_rate(Client_val(cv))));
}

/*********
 * Stats *
 *********/

CAMLprim value ocaml_jack_get_max_delayed_usecs(value cv)
{
  CAMLparam1(cv);
  CAMLreturn(caml_copy_double(jack_get_max_delayed_usecs(Client_val(cv))));
}

CAMLprim value ocaml_jack_get_xrun_delayed_usecs(value cv)
{
  CAMLparam1(cv);
  CAMLreturn(caml_copy_double(jack_get_xrun_delayed_usecs(Client_val(cv))));
}

CAMLprim value ocaml_jack_reset_max_delayed_usecs(value cv)
{
  CAMLparam1(cv);
  jack_reset_max_delayed_usecs(Client_val(cv));
  CAMLreturn(Val_unit);
}

/*************
 * Transport *
 *************/

CAMLprim value ocaml_jack_transport_start(value cv)
{
  CAMLparam1(cv);
  jack_transport_start(Client_val(cv));
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_jack_transport_stop(value cv)
{
  CAMLparam1(cv);
  jack_transport_stop(Client_val(cv));
  CAMLreturn(Val_unit);
}
