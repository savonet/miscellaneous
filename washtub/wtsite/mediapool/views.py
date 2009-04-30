#    Copyright (c) 2009, Chris Everest 
#    This file is part of Washtub.
#
#    Washtub is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Washtub is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Washtub.  If not, see <http://www.gnu.org/licenses/>.

from django.conf import settings
from django.core.paginator import Paginator
from django.http import Http404, HttpResponseRedirect, HttpResponse
from django.utils.encoding import smart_str, smart_unicode
from django.contrib.auth.decorators import login_required
from wtsite.mediapool.models import *
from os import access, stat, path, walk, F_OK, R_OK
from os.path import join, getsize
from stat import ST_MTIME
import tagpy, datetime, logging

def build_file_list(dir):
    logging.info('Start of build_file_list(%s)' % dir)
    if not (access(dir, (F_OK or R_OK))):
        return
    list = walk(dir,topdown=True)
    for root, dirs, files in list:
        for f in files:
            ext = path.splitext(f)[1]
            if ext in ('.mp3', '.flac'):
                full_path = path.join(root,f)
                mod_time = stat(full_path)[ST_MTIME]
                mod_time = datetime.datetime.fromtimestamp(mod_time)
                try: 
                    #check update time and compare against database.
                    s = Song.objects.get(filename=full_path)
                    if(mod_time > s.date_modified): 
                        s.date_modified=mod_time.isoformat(' ')
                        s.save()
                except Song.DoesNotExist:
                    #add it into the database
                    now = datetime.datetime.now().isoformat(' ')
                    s = Song(filename=full_path, date_modified=mod_time, date_entered=now)
                    s.save()
    logging.info('End of build_file_list(%s)' % dir)
    return

def build_file_list2(dir):
    logging.info('Start of build_file_list2(%s)' % dir)
    if not (access(dir, (F_OK or R_OK))):
        return
    #empty all songs from current database.  This should be fast!!!
    d = Song.objects.all()
    d.delete()
    list = walk(dir,topdown=True)
    for root, dirs, files in list:
        for f in files:
            ext = path.splitext(f)[1]
            if ext in ('.mp3', '.flac'):
                full_path = path.join(root,f)
                mod_time = stat(full_path)[ST_MTIME]
                mod_time = datetime.datetime.fromtimestamp(mod_time)
                #try: 
                #    #check update time and compare against database.
                #    s = Song.objects.get(filename=full_path)
                #    if(mod_time > s.date_modified): 
                #        s.date_modified=mod_time.isoformat(' ')
                #        s.save()
                #except Song.DoesNotExist:
                    #add it into the database
                now = datetime.datetime.now().isoformat(' ')
                s = Song(filename=full_path, date_modified=mod_time, date_entered=now)
                s.save()
    logging.info('End of build_file_list2(%s)' % dir)
    return

def clean_db(dir, songs):
    logging.info('Start of clean_db(%s)' % dir)
    if not (access(dir, (F_OK or R_OK))):
        return
    # remove songs that are in the database, but aren't physically on the filesystem
    for s in songs:
        found = False
        db_filename = smart_str(s.filename)
        list = walk(dir,topdown=True)
        for root, dirs, files in list:
            if(found):
                continue
            for f in files:
                if(found):
                    continue
                ext = path.splitext(f)[1]
                if ext in ('.mp3', '.flac'):
                    full_path = path.join(root,f)
                    if(full_path == db_filename):
                        found = True
        if not found:
            d = Song.objects.get(filename__exact=s.filename)
            d.delete()
    
    # refresh list of songs (we may have just deleted some)
    songs = Song.objects.all()
    # remove albums that don't have corresponding songs
    d = Album.objects.filter(song__title__isnull=True)
    d.delete()
    
    d = Artist.objects.filter(song__title__isnull=True)
    d.delete()
    
    d = Genre.objects.filter(song__title__isnull=True)
    d.delete()
    
    logging.info('End of clean_db(%s)' % dir)
    return  

def clean_db2(dir, songs):
    logging.info('Start of clean_db(%s)' % dir)
    if not (access(dir, (F_OK or R_OK))):
        return
    # No need to remove objects that don't exist (build_file_list2 only adds new to empty database)
    # Remove albums that don't have corresponding songs
    d = Album.objects.filter(song__title__isnull=True)
    d.delete()
    
    d = Artist.objects.filter(song__title__isnull=True)
    d.delete()
    
    d = Genre.objects.filter(song__title__isnull=True)
    d.delete()
    
    logging.info('End of clean_db(%s)' % dir)
    return 

@login_required()
def file_scanner(request):
    
    if(settings.MEDIAPOOL_PATH):
        directory = settings.MEDIAPOOL_PATH
    else:
        return
    
    list = build_file_list2(directory)
    songs = Song.objects.all()
    clean_db2(directory, songs)
    
    return HttpResponseRedirect('/'+settings.BASE_URL)
    
    
def get_song_pager():
	 pager = Paginator(Song.objects.all(), 15)
	 return pager

def get_song_search_pager(queryset):
     pager = Paginator(queryset, 15)
     return pager
    

    