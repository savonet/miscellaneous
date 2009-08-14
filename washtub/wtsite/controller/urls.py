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

from django.conf.urls.defaults import *

urlpatterns = patterns('wtsite.controller.views',    
	(r'^control/skip/(?P<host_name>\S+)/(?P<stream>\S+)$', 'stream_skip'),     
	(r'^control/start/(?P<host_name>\S+)/(?P<stream>\S+)$', 'stream_start'),      
	(r'^control/stop/(?P<host_name>\S+)/(?P<stream>\S+)$', 'stream_stop'),
	(r'^queue/push/(?P<host_name>\S+)$', 'queue_push'),
	(r'^status/nodes/(?P<host_name>\S+)$', 'display_nodes'),
	(r'^status/queues/(?P<host_name>\S+)$', 'display_queues'),
	(r'^status/history/(?P<host_name>\S+)$', 'display_history'),
	(r'^status/help/(?P<host_name>\S+)$', 'display_help'),
	(r'^status/(?P<host_name>\S+)$', 'display_status'),
	(r'^log/(?P<host_name>\S+)$', 'write_log'),
	(r'^pool/search/(?P<host_name>\S+)/(?P<page>\d+)$', 'search_pool_page'),
	(r'^pool/search/(?P<host_name>\S+)$', 'search_pool'),
	(r'^pool/(?P<host_name>\S+)/(?P<type>\S+)/(?P<page>\d+)$', 'display_pool_page'),     
	(r'^pool/(?P<host_name>\S+)/(?P<type>\S+)$', 'display_pool'),
	(r'^$', 'index'),
	)