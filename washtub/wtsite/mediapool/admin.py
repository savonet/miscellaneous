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

from wtsite.mediapool.models import *
from django.contrib import admin

class SongAdmin(admin.ModelAdmin):
    search_fields = ['title']
    list_per_page = 50  
    list_filter = ['artist']
    list_display = ('title', 'artist', 'album', 'genre')
    fieldsets = (
        (None, {
            'classes': ['wide'],
            'fields': ('filename', 'title', 'artist', 'album', 'genre', )
        }),
        ('Extras', {
            'fields': ('track', 'year', 'length', 'numplays',
                       'rating', 'lastplay', 'date_entered', 'date_modified', 'format', 'size', 
                       'description', 'comment', 'disc_count', 'disc_number', 'track_count', 'start_time',
                       'stop_time', 'eq_preset', 'relative_volume', 'sample_rate', 'bitrate', 'bpm')
        }),
    )

    
class ArtistAdmin(admin.ModelAdmin):
    list_per_page = 50  

class AlbumAdmin(admin.ModelAdmin):
    list_per_page = 50  
    list_filter = ['artist']
    list_display = ('name', 'artist_list', 'year')
    
class GenreAdmin(admin.ModelAdmin):
    list_per_page = 50  

admin.site.register(Song, SongAdmin)
admin.site.register(Album, AlbumAdmin)
admin.site.register(Artist, ArtistAdmin)
admin.site.register(Genre, GenreAdmin)