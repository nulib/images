// For adding items to the collection

	$(function() {
		$( "#images li" ).draggable({
			appendTo: "body",
			helper: "clone"
		});
		$( "#imageCollection ul li" ).draggable({
			appendTo: "body",
			helper: "clone"
		});
		$( "#imageCollection li" ).droppable({
			activeClass: "ui-state-default",
			hoverClass: "ui-state-hover",
			accept: ":not(.ui-sortable-helper)",
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
				
				
				
				$( "<li></li>" ).text(ui.draggable.attr("title")+" added!").appendTo(this);
				
				$.ajax({
				type: "POST",
				url: "dil_collections/add/" + collectionID + "/" + imageID + "?member_title=" + titleID,
				//data: "id=10",
				async: false,
				success: function(msg){
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
		});
	});
	
	
	
//For moving items around in the collection

	start_index='';
	$(document).ready(function(){
		$('.gallery_container').sortable({
			start: function(event, ui) {
			    start_index=$(this).children().index(ui.item)
			}
		});
		$('.gallery_container').sortable({
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
		
		$('.accordion h2').live("click", (function() {
		  var collection_id = $(this).attr('id');
		  var theObj = $(this);
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

			  //Each row
			  $.each(data, function(i, map) {

				title = map['title'];
				pid = map['pid'];
				numSub = map['numSubcollections'];
				if(numSub > 0)
			    	items.push('<li pid="' + pid + '" title="' + title + '" class="collection"><h2 id="' + pid + '"><span><img src="/assets/listexpander/collapsed.gif" alt = "Plus or Minus"></span><a href="/dil_collections/' + pid + '">' + title + ' (' + numSub + ')</a></h2><div class="inner"></div></li>');
				else
		    		items.push('<li pid="' + pid + '" title="' + title + '" class="collection"><h2 id="' + pid + '"><span></span><a href="/dil_collections/' + pid + '">' + title + ' (' + numSub + ')</a></h2><div class="inner"></div></li>');

			  });//End each row

			  $('<ul/>', {
			    'class': 'accordion ui-widget-content',
			    html: items.join('')
			  }).appendTo(theObj.siblings('div'));
			});//End Ajax call

		} else {
			theObj.siblings('div').children('ul').fadeOut('fast', function(obj) {
				$(this).remove();
			});
		}
	}));
});
