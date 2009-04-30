$(function(){

	// Accordion
	$("#accordion").accordion({ header: "h3" });

	// Tabs
	$('#tabs').tabs('select', 2);

	// Dialog			
	$('#dialog').dialog({
		autoOpen: false,
		width: 600,
		buttons: {
			"Ok": function() { 
				$(this).dialog("close"); 
			}, 
			"Cancel": function() { 
				$(this).dialog("close"); 
			} 
		}
	});
	
	// Dialog Link
	$('#dialog_link').click(function(){
		$('#dialog').dialog('open');
		return false;
	});

	// Datepicker
	$('#datepicker').datepicker({
		inline: true
	});
	
	// Slider
	$('#slider').slider({
		range: true,
		values: [17, 67]
	});
	
	// Progressbar
	$("#progressbar").progressbar({
		value: 20 
	});
	
	//hover states on the static widgets
	$('#dialog_link, ul#icons li').hover(
		function() { $(this).addClass('ui-state-hover'); }, 
		function() { $(this).removeClass('ui-state-hover'); }
	);
	
	//Call Table Sorter
	$("#metaTable0").tablesorter({
		widgets: ['zebra']
	});
	
	//Call Table Sorter
	$("#metaTable1").tablesorter({
		widgets: ['zebra']
	});
	
	//Call Table Sorter
	$("#metaTable2").tablesorter({
		widgets: ['zebra']
	});
	
	//Call Table Sorter
	$("#historyTable0").tablesorter({
		widgets: ['zebra']
	});
	
	//Call Table Sorter
	$("#historyTable1").tablesorter({
		widgets: ['zebra']
	});
	
	//Call Table Sorter
	$("#onAirTable").tablesorter({
		widgets: ['zebra']
	});
	
	//Call Table Sorter
	$("#aliveTable").tablesorter({
		widgets: ['zebra']
	});
	
});