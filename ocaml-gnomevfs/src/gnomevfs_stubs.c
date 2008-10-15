/* $Id$ */

#include <errno.h>
#include <string.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/misc.h>
#include <caml/custom.h>
#include <caml/memory.h>
#include <caml/callback.h>

#include <libgnomevfs/gnome-vfs.h>

#define UNIX_BUFFER_SIZE 16384

static inline void init() {
	if (!gnome_vfs_initialized() && !gnome_vfs_init())
		exit(1);
}

static value * gnomevfs_error_exn = NULL;

void ocaml_gnomevfs_error(GnomeVFSResult result)
{
	value res;

	if (!gnomevfs_error_exn) {
		gnomevfs_error_exn = caml_named_value("Gnomevfs.Gnomevfs_error");
		if (!gnomevfs_error_exn)
			caml_invalid_argument("Exception Gnomevfs.Gnomevfs_error not initialized, please link gnomevfs.cma");
	}

	caml_raise_with_arg(*gnomevfs_error_exn, Val_int(result-1));
}

CAMLprim value ocaml_gnomevfs_error_msg(value result)
{
	CAMLparam1(result);

	CAMLreturn(copy_string(gnome_vfs_result_to_string(Int_val(result)+1)));
}

static GnomeVFSOpenMode ocaml_gnomevfs_open_modes[] = { GNOME_VFS_OPEN_READ, GNOME_VFS_OPEN_WRITE, GNOME_VFS_OPEN_RANDOM };

static GnomeVFSOpenMode ocaml_gnomevfs_mode_of_list (value list)
{
	int res = GNOME_VFS_OPEN_NONE;
	while (list != Val_int(0)) {
		res |= ocaml_gnomevfs_open_modes[Int_val(Field(list, 0))];
		list = Field(list, 1);
	}
	return res;
}

CAMLprim value ocaml_gnomevfs_open(value uri_, value mode_)
{
	CAMLparam2(uri_, mode_);
	GnomeVFSHandle *handle;
	GnomeVFSResult result;
	GnomeVFSOpenMode mode;
	char * uri = malloc(caml_string_length(uri_) + 1);
	uri = strcpy(uri, String_val(uri_));
	mode = ocaml_gnomevfs_mode_of_list(mode_);
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_open(&handle, uri, mode);
	caml_leave_blocking_section();

	free(uri);
	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn((value)handle);
}

CAMLprim value ocaml_gnomevfs_create(value uri_, value mode_, value excl_, value perm_)
{
	CAMLparam4(uri_, mode_, excl_, perm_);
	GnomeVFSHandle *handle;
	GnomeVFSResult result;
	char *uri = malloc(caml_string_length(uri_) + 1);
	GnomeVFSOpenMode mode = ocaml_gnomevfs_mode_of_list(mode_);
	guint perm = Int_val(perm_);
	gboolean excl = Bool_val(excl_);
	uri = strcpy(uri, String_val(uri_));
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_create(&handle, uri, mode, excl, perm);
	caml_leave_blocking_section();

	free(uri);
	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn((value)handle);
}

CAMLprim value ocaml_gnomevfs_close(value handle_)
{
	CAMLparam1(handle_);
	GnomeVFSResult result;
	GnomeVFSHandle *handle = (GnomeVFSHandle *)handle_;
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_close(handle);
	caml_leave_blocking_section();

	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn(Val_unit);
}

CAMLprim value ocaml_gnomevfs_unlink(value uri_)
{
	CAMLparam1(uri_);
	GnomeVFSResult result;
	char *uri = malloc(caml_string_length(uri_) + 1);
	uri = strcpy(uri, String_val(uri_));
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_unlink(uri);
	caml_leave_blocking_section();

	free(uri);
	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn(Val_unit);
}

CAMLprim value ocaml_gnomevfs_move(value old_, value new_, value force_)
{
	CAMLparam3(old_, new_, force_);
	GnomeVFSResult result;
	gchar *old = malloc(caml_string_length(old_) + 1);
	gchar *new = malloc(caml_string_length(new_) + 1);
	gboolean force = Bool_val(force_);
	old = strcpy(old, String_val(old_));
	new = strcpy(new, String_val(new_));
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_move(old, new, force);
	caml_leave_blocking_section();

	free(old);
	free(new);
	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn(Val_unit);
}

CAMLprim value ocaml_gnomevfs_check_same_fs(value source_, value target_)
{
	CAMLparam2(source_, target_);
	GnomeVFSResult result;
	gboolean same_fs;
	gchar *source = malloc(caml_string_length(source_) + 1);
	gchar *target = malloc(caml_string_length(target_) + 1);
	source = strcpy(source, String_val(source_));
	target = strcpy(target, String_val(target_));
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_check_same_fs(source, target, &same_fs);
	caml_leave_blocking_section();

	free(source);
	free(target);
	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn(Val_bool(same_fs));
}

CAMLprim value ocaml_gnomevfs_read(value handle_, value buf_, value ofs_, value len_)
{
	CAMLparam4(handle_, buf_, ofs_, len_);
	GnomeVFSResult result;
	GnomeVFSFileSize bytes_read;
	GnomeVFSHandle *handle = (GnomeVFSHandle *)handle_;
	gchar buf[UNIX_BUFFER_SIZE];
	GnomeVFSFileSize len = Long_val(len_);
	if (len > UNIX_BUFFER_SIZE) len = UNIX_BUFFER_SIZE;
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_read(handle, buf, len, &bytes_read);
	caml_leave_blocking_section();

	if (result) ocaml_gnomevfs_error(result);
	memmove(&Byte(buf_, Long_val(ofs_)), buf, bytes_read);
	CAMLreturn(Val_int(bytes_read));
}

CAMLprim value ocaml_gnomevfs_write(value handle_, value buf_, value ofs_, value len_)
{
	CAMLparam4(handle_, buf_, ofs_, len_);
	GnomeVFSResult result;
	GnomeVFSFileSize bytes_written;
	GnomeVFSHandle *handle = (GnomeVFSHandle *)handle_;
	gchar buf[UNIX_BUFFER_SIZE];
	GnomeVFSFileSize len = Long_val(len_);
	if (len > UNIX_BUFFER_SIZE) len = UNIX_BUFFER_SIZE;
	init();
	memmove(buf, &Byte(buf_, Long_val(ofs_)), len);

	caml_enter_blocking_section();
	result = gnome_vfs_write(handle, buf, len, &bytes_written);
	caml_leave_blocking_section();

	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn(Val_int(bytes_written));
}

static GnomeVFSSeekPosition ocaml_gnomevfs_seek_positions[] = { GNOME_VFS_SEEK_START, GNOME_VFS_SEEK_CURRENT, GNOME_VFS_SEEK_END };

CAMLprim value ocaml_gnomevfs_seek(value handle_, value whence_, value offset_)
{
	CAMLparam3(handle_, whence_, offset_);
	GnomeVFSResult result;
	GnomeVFSHandle *handle = (GnomeVFSHandle *)handle_;
	GnomeVFSSeekPosition whence = ocaml_gnomevfs_seek_positions[Int_val(whence_)];
	GnomeVFSFileOffset offset = Long_val(offset_);
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_seek(handle, whence, offset);
	caml_leave_blocking_section();

	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn(Val_unit);
}

CAMLprim value ocaml_gnomevfs_tell(value handle_)
{
	CAMLparam1(handle_);
	GnomeVFSResult result;
	GnomeVFSFileSize offset_return;
	GnomeVFSHandle *handle = (GnomeVFSHandle *)handle_;
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_tell(handle, &offset_return);
	caml_leave_blocking_section();

	if (result) ocaml_gnomevfs_error(result);
	if (offset_return > Max_long) ocaml_gnomevfs_error(GNOME_VFS_ERROR_TOO_BIG);
	CAMLreturn(Val_long(offset_return));
}

CAMLprim value ocaml_gnomevfs_make_directory(value uri_, value perm_)
{
	CAMLparam2(uri_, perm_);
	GnomeVFSResult result;
	gchar *uri = malloc(caml_string_length(uri_) + 1);
	uri = strcpy(uri, String_val(uri_));
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_make_directory(uri, Int_val(perm_));
	caml_leave_blocking_section();

	free(uri);
	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn(Val_unit);
}

CAMLprim value ocaml_gnomevfs_remove_directory(value uri_)
{
	CAMLparam1(uri_);
	GnomeVFSResult result;
	gchar *uri = malloc(caml_string_length(uri_) + 1);
	uri = strcpy(uri, String_val(uri_));
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_remove_directory(uri);
	caml_leave_blocking_section();

	free(uri);
	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn(Val_unit);
}

CAMLprim value ocaml_gnomevfs_directory_open(value uri_, value options_)
{
	CAMLparam2(uri_, options_);
	GnomeVFSResult result;
	GnomeVFSDirectoryHandle *handle;
	gchar *uri = malloc(caml_string_length(uri_) + 1);
	uri = strcpy(uri, String_val(uri_));
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_directory_open(&handle, uri, GNOME_VFS_FILE_INFO_DEFAULT);
	caml_leave_blocking_section();

	free(uri);
	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn((value)handle);
}

CAMLprim value ocaml_gnomevfs_directory_read_next(value handle_)
{
	CAMLparam1(handle_);
	GnomeVFSFileInfo *info = gnome_vfs_file_info_new();
	GnomeVFSResult result;
	GnomeVFSDirectoryHandle *handle = (GnomeVFSDirectoryHandle *)handle_;
	CAMLlocal3(info_, symlink_name, mime_type);
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_directory_read_next(handle, info);
	caml_leave_blocking_section();

	if (result) ocaml_gnomevfs_error(result);
	info_ = caml_alloc_tuple(18);
	Store_field(info_, 0, caml_copy_string(info->name));
	Store_field(info_, 1, Val_int(info->valid_fields));
	Store_field(info_, 2, Val_int(info->type));
	Store_field(info_, 3, Val_int(info->permissions));
	Store_field(info_, 4, Val_int(info->flags));
	Store_field(info_, 5, Val_int(info->device));
	Store_field(info_, 6, Val_int(info->inode));
	Store_field(info_, 7, Val_int(info->link_count));
	Store_field(info_, 8, Val_int(info->uid));
	Store_field(info_, 9, Val_int(info->gid));
	Store_field(info_, 10, Val_int(info->block_count));
	Store_field(info_, 11, Val_int(info->io_block_size));
	Store_field(info_, 12, caml_copy_double((double)(info->atime)));
	Store_field(info_, 13, caml_copy_double((double)(info->mtime)));
	Store_field(info_, 14, caml_copy_double((double)(info->ctime)));
	if (!(info->symlink_name)) symlink_name = Val_unit;
	else {
		symlink_name = caml_alloc_tuple(1);
		Store_field(symlink_name, 0, caml_copy_string(info->symlink_name));
	}
	Store_field(info_, 15, symlink_name);
	if (!(info->mime_type)) mime_type = Val_unit;
	else {
		mime_type = caml_alloc_tuple(1);
		Store_field(mime_type, 0, caml_copy_string(info->mime_type));
	}
	Store_field(info_, 16, mime_type);
	Store_field(info_, 17, Val_int(info->refcount));
	gnome_vfs_file_info_unref(info);
	CAMLreturn(info_);
}

CAMLprim value ocaml_gnomevfs_directory_close(value handle_)
{
	CAMLparam1(handle_);
	GnomeVFSResult result;
	GnomeVFSDirectoryHandle *handle = (GnomeVFSDirectoryHandle *)handle_;
	init();

	caml_enter_blocking_section();
	result = gnome_vfs_directory_close(handle);
	caml_leave_blocking_section();

	if (result) ocaml_gnomevfs_error(result);
	CAMLreturn(Val_unit);
}
