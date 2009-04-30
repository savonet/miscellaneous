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

from django.template.defaultfilters import stringfilter
from django.conf import settings
from django import template
import string

register = template.Library()

@register.filter("replacedot")
@stringfilter
def replacedot(value):
	return value.replace('(dot)', '.')

@register.filter("cat")
@stringfilter
def cat(value, string):
	return value+string

@register.filter("baseurl")
@stringfilter
def baseurl(value):
	return '/'+settings.BASE_URL+value


@register.filter("tominutes")
def tominutes(value):
	try:
		value = float(value)
		minutes = int(value/60)
		seconds = int(value%60)
		return ('%s:%.2d' % (minutes,seconds))
	except (ValueError, TypeError):
		return

