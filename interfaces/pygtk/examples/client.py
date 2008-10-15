#!/usr/bin/python

import gtk,gobject,sys,os

mainPath=sys.path[0]
sys.path.append(mainPath+'/../libs')
import ClientThreadManager

#from libs import ClientThreadManager

class countdownBox(gtk.EventBox):
    def __init__(self,sender):
	gtk.EventBox.__init__(self)
	self.label=l=gtk.Label("     ")
	self.add(l)
	self.sender=sender
	self.thread=None

	self.blinkState=False
	self.blinkFreq=5
	self.blinkTotal=0

	self.set_size_request(50,-1)
	self.modify_bg(gtk.STATE_NORMAL,gtk.gdk.Color(59135,59135,59135))

    def start(self):
	self.sender.manager.make_response_thread('mixer_main.status 0','.*?([+-]?\\d*\\.\\d+)(?![-+0-9\\.])',self.start_timer)

    def stop(self):
	if self.thread:
	    self.sender.manager._register_thread_completed(self.thread)

    def update(self,sender,*args):
	self.label.set_label(args[0])

    def final(self,sender,*args):
	if self.blinkTotal<self.blinkFreq:
	    self.blinkTotal+=1
	    return
	self.blinkTotal=0

	if self.blinkState:
	    self.modify_bg(gtk.STATE_NORMAL,gtk.gdk.Color(59135,29135,29135))
	else:
	    self.modify_bg(gtk.STATE_NORMAL,gtk.gdk.Color(59135,59135,59135))
	self.blinkState=not self.blinkState

    def start_timer(self,sender,*args):	
	time=float(args[0])
	self.thread=self.sender.manager.make_countdown_thread(time,self.update,self.final)

class Client:

    ##############
    # Demo client
    ##############
    def __init__(self):
	win=gtk.Window()
	
	self.manager = ClientThreadManager.ClientThreadManager(3)
	win.connect("delete_event",self.quit)
	box=gtk.VBox(False,3)
	win.add(box)
	controlButtons=gtk.HBox(False,10)
	self.metaWatcherButton=gtk.ToggleButton('Watch queue')
	self.metaWatcherButton.connect('clicked',self.metaWatcherButton_clicked)

	self.cueButton=gtk.ToggleButton('CUE')
	self.cueButton.connect('clicked',self.cueButton_clicked)

	self.skipButton=gtk.Button('Skip')
	self.skipButton.connect('clicked',self.skip_clicked)

#	self.remainInfo=gtk.Label(" ")
#	self.remain=None
	self.remainInfo=countdownBox(self)

	self.addButton=addButton=gtk.FileChooserButton('')
	fileFilter = gtk.FileFilter()
	fileFilter.set_name("Audio MP3/OGG")
	fileFilter.add_pattern("*.mp3")
	fileFilter.add_pattern("*.ogg")
	addButton.add_filter(fileFilter)
	addButton.connect("selection-changed",self.cue_file)
	
	self.metaWatcherModel = gtk.ListStore(gobject.TYPE_STRING,gobject.TYPE_STRING,gobject.TYPE_STRING)
	metaWatcherView=gtk.TreeView(self.metaWatcherModel)
	metaWatcherView.set_size_request(400,200)
	cols=['Artist','Title','Status']
	i=0
	for col in cols:
		metaWatcherView.append_column(gtk.TreeViewColumn(col, gtk.CellRendererText(), text=i))
		i=i+1
	
	controlButtons.pack_start(self.metaWatcherButton,False)
	controlButtons.pack_start(self.cueButton,False)
	controlButtons.pack_start(self.skipButton,False)
	controlButtons.pack_start(self.remainInfo,False)

	box.pack_start(controlButtons,False)
	box.pack_start(self.addButton,False)
	box.pack_start(metaWatcherView)

	self.manager.make_commandWatcher('mixer_main.status 0',self.cueButton_daemon,self.deactive_cueButton,
	'.*?(?:[a-z][a-z]+).*?(?:[a-z][a-z]+).*?(?:[a-z][a-z]+).*?((?:[a-z][a-z]+))'
	);

	win.show_all()
	gtk.main()

    def deactive_null(self,*args):
	None

    def cue_file(self,sender):
	self.manager.make_command_thread('main.push %s'%sender.get_filename())
	sender.set_filename('')

    ###########################################################################
    # cueButton

    def update_cueButton(self,active):
	if active:
	    self.cueButton.set_label('Play')
	    self.remainInfo.start()
	else:
	    self.cueButton.set_label('CUE')
	    self.remainInfo.stop()
	self.cueButton.set_active(active)
	

    def cueButton_clicked(self,sender):
	active=sender.get_active()
	s='mixer_main.select 0 '+str(active).lower()
	self.manager.make_command_thread(s)

    def cueButton_daemon(self,sender,*args):
	active=args[0]=="true"
	self.update_cueButton(active)

    def deactive_cueButton(self,sender):
	self.update_cueButton(False)

    ###########################################################################

    def skip_clicked(self,sender,*args):
	self.manager.make_command_thread('mixer_main.skip 0')
	self.remainInfo.stop()

    def quit(self, sender, event):
        self.manager.stop_all_threads(block=True)
        gtk.main_quit()

    def metaWatcherButton_clicked(self,sender):
	if sender.get_active():
		self.start_metaWatcher(sender)
		sender.set_label('Watching queue')
	else:
		self.stop_metaWatcher(sender)
		self.empty_queue(None)
		sender.set_label('Watch queue')

    def start_metaWatcher(self,sender):
	self.manager.make_metaWatcher_thread(self.handle_metaData,self.handle_error,self.empty_queue,'main')

    def stop_metaWatcher(self,sender):
	self.manager.stop_metaWatcher_thread('main')



#    def cueButton_clicked(self,sender):
#	
#	if sender.get_active():
#		sender.set_label('Play')
#		self.manager.make_command_thread('mixer_main.select 0 true')
#	#	self.manager.make_response_thread('mixer_main.status 0','.*?([+-]?\\d*\\.\\d+)(?![-+0-9\\.])',self.start_remain)
#	else:
#		sender.set_label('CUE')
#		self.manager.make_command_thread('mixer_main.select 0 false')
	

    def empty_queue(self,sender):
	model=self.metaWatcherModel
	while not model.get_iter_first() == None:
		row=self.metaWatcherModel.get_iter(0)
		model.remove(row)

    def handle_metaData(self,data,*args):
	values=args[0]
	for entry in values:		
		if len(entry)==0:
			continue

		if 'artist' not in entry:
			continue
	
		try:
			row=self.metaWatcherModel.get_iter(entry['rid'])
			self.metaWatcherModel.set_value(row,2,entry['status'])
		except ValueError:
			self.metaWatcherModel.insert(entry['rid'],(entry['artist'],entry['title'],entry['status']))
    def handle_error(self,*args):
	self.metaWatcherButton.set_active(False)
	#self.stop_remain()
	self.empty_queue(None)

if __name__ == "__main__":
    client=Client()



    
	
