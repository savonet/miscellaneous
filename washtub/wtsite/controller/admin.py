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

from wtsite.controller.models import *
from django.contrib import admin

class ThemeAdmin(admin.ModelAdmin):
	pass
	
class HostAdmin(admin.ModelAdmin):
	list_display = ('name', 'ip_address', 'base_url', 'theme', 'admin')

class SettingAdmin(admin.ModelAdmin):
	list_filter = ['hostname']
	list_display = ('value', 'data', 'hostname')

admin.site.register(Theme, ThemeAdmin)
admin.site.register(Host, HostAdmin)
admin.site.register(Setting, SettingAdmin)
