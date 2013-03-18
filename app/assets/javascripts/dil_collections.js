/**
*  This is for the drag-drop for adding an image or collection to another collection.
*  This is also the code to sort items within collections.
*  REFACTOR NEEDED
**/


function dropMe(theObj) {
	$(theObj).droppable({
	activeClass: "ui-state-default",
	hoverClass: "dil-ui-state-hover",
	accept: ":not(.ui-sortable-helper)",
	tolerance: "pointer",
	drop: function( event, ui ) {
    
		$( this ).find( ".placeholder" ).remove();
		
		//get id attribute for draggable <li> item (image)
		var imageID = $(ui.draggable).attr("pid");
		
		//get title attribute for draggable <li> item (image)
		var titleID = $(ui.draggable).attr("title");
		
		//get member_type attribute for draggable <li> item (image)
		//var memberType = $(ui.draggable).attr("member_type");

		//get id attribute for droppable <li> item (collection)
		//var collectionID = $( this ).find("li").attr("pid");
		var collectionID = $( this ).attr("pid");
  
		//show the loading gif
        $('.modal-collection').show();
        
		$.ajax({
		type: "POST",
		url: "dil_collections/add/" + collectionID + "/" + imageID + "?member_title=" + titleID,
		//data: "id=10",
		async: false,
		success: function(msg){
		 
		 //hide the loading gif
		 $('.modal').hide();
		 
		 //reload the page to refresh the collections
		 location.reload();
	    },
		
		 error: function(msg){ 
		 $('.modal-collection').hide();
		}
		});//end ajax
		
	}//end droppable
}).sortable({
	items: "li:not(.placeholder)",
	sort: function() {
		// gets added unintentionally by droppable interacting with sortable
		// using connectWithSortable fixes this, but doesn't allow you to customize active/hoverClass options
		$( this ).removeClass( "ui-state-default" );
	}
})};


	start_index='';
	$(document).ready(function(){
		// For adding items to the collection
		//For sidebar drag/drop
		$(document).on('mouseover', "#images li", function() {
			$(this).draggable({
			appendTo: "body",
			helper: "clone"
		})});
		$(document).on('mouseover', ".accordion h2", function() {
			$(this).draggable({
			appendTo: "body",
			helper: "clone"
		})});

		dropMe(".accordion h2");
		//End for sidebar drag/drop

		//For moving items around in the collection
		$('#gallery_container').sortable({
			start: function(event, ui) {
			    start_index=$(this).children().index(ui.item)
			}
		});
		$('#gallery_container').sortable({
			update: function(event, ui) {
				//var fruitOrder = $(this).sortable('toArray').toString();
				var collection_id= $(this).attr('pid');
				// Note: ui.item.attr('id') is id of dragged item 
				var url='/dil_collections/move/' + collection_id + '/' + start_index + '/' + $(this).children().index(ui.item);
				//$.get('update-sort.cfm', {fruitOrder:fruitOrder});

				$.ajax({
				type: "POST",
				url: url,
				async: false,
				success: function(msg){
				}
				});//end ajax
			}
		});
		
		$('.accordion h2 img.collection_plus_minus').live("click", (function() {
		  var collection_id = $(this).closest('h2').attr('id');
		  var theObj = $(this).closest('h2');
		  var doAjax = false;
		
		//The plus/minus
		if(theObj.attr('toggle') == 'plus') {
			theObj.attr('toggle', 'minus');
			theObj.find('img').attr('src', '/assets/listexpander/expanded.gif');
			doAjax = true;
		} else {
			theObj.attr('toggle', 'plus');
			theObj.find('img').attr('src', '/assets/listexpander/collapsed.gif');
			doAjax = false;
		};//End the plus/minus

		if(doAjax) {
			//The Ajax call
			$.getJSON("dil_collections/get_subcollections/" + collection_id, function(data) {
			  var items = [];
			  var title = '';
			  var pid = '';
			  var numSub = 0;
			  var numImages = 0;

			  //Each row
			  $.each(data, function(i, map) {

				title = map['title'];
				pid = map['pid'];
				numSub = map['numSubcollections'];
				numImages = map['numImages'];

			    if (numSub > 0){
			      items.push('<li class="collection"><h2 pid="' + pid + '" title="' + title + '" id="' + pid + '" toggle="plus"><span><img src="/assets/listexpander/collapsed.gif" class="collection_plus_minus" alt = "Plus or Minus"></span><a href="/dil_collections/' + pid + '">' + title + ' (' + numImages + ')</a></h2><div class="outer"><div class="inner"></div></div></li>');
                }
                else{
                  items.push('<li class="collection"><h2 pid="' + pid + '" title="' + title + '" id="' + pid + '"><span> </span><a href="/dil_collections/' + pid + '">' + title + ' (' + numImages + ')</a></h2><div class="outer"><div class="inner"></div></div></li>');
                }

			  });//End each row

			  //Remove existing ul just in case!
			  theObj.siblings('div').children('div.inner').children('ul').remove();

			  $('<ul/>', {
			    'class': 'accordion ui-widget-content',
			    html: items.join('')
			  }).appendTo(theObj.siblings('div').children('div.inner'));
			theObj.siblings('div').children('div.inner').find('h2').each(function(index) { dropMe(this) });
			});//End Ajax call

		} else {
			theObj.siblings('div').children('div.inner').children('ul').fadeOut('fast', function(obj) {
				$(this).remove();
			});
		}
	
	}));

	$('a[data-method="delete"]').bind('confirm:complete', function(e, answer) {
		if(answer)
			$('.modal-collection').show();
	});
});
