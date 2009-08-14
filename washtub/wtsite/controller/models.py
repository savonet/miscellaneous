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

from django.db import models
from django.contrib.auth.models import User, Group
from django.utils.encoding import *
import datetime
from datetime import datetime

# Create your models here.
class Theme(models.Model):
    name = models.CharField(max_length=64, unique=True)
    
    def __unicode__(self):
        return self.name

class Host(models.Model):
    name = models.CharField(max_length=128)
    ip_address = models.IPAddressField('Server IP Address')
    base_url = models.URLField(verify_exists=False)
    theme = models.ForeignKey(Theme)
    description = models.TextField('Description', blank=True)
    admin_group = models.ManyToManyField(Group, related_name='host_admin_group', blank=True)
    admin = models.ForeignKey(User, related_name='host_admin', default=1)

    def __unicode__(self):
    	return self.name
    
class Setting(models.Model):
    SETTINGS_CHOICES = (
    	('port', 'port'),
    	('protocol', 'protocol'),
        ('queue_id', 'queue_id'),
    	)

    value = models.CharField(max_length=128, choices=SETTINGS_CHOICES)
    data = models.CharField(max_length=255)
    hostname = models.ForeignKey('Host',default=1)
    
    def __unicode__(self):
        return self.value
    
    class Meta:
        ordering = ['hostname', 'value']
        verbose_name = "Setting"
        verbose_name_plural = "Settings"
        
class Log(models.Model):
    entrytime = models.DateTimeField(editable=False)
    info = models.CharField(max_length=48, editable=False)
    host = models.CharField(max_length=255, editable=False)
    stream = models.CharField(max_length=128, editable=False)
    song_id = models.IntegerField(default=-1, editable=False)
    title = models.CharField(max_length=765, editable=False)
    artist = models.CharField(max_length=765, editable=False)
    album = models.CharField(max_length=765, editable=False)

    def simple_entrytime(self):
        return self.entrytime.strftime('%Y-%m-%d %H:%M:%S')
    
    class Meta:
        ordering = ['-entrytime']
        verbose_name_plural = "Log Entries"
    
