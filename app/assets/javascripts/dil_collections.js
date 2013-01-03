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
		
		$('.accordion h2').click(function() {
		  
		  var collection_id = $(this).attr('id')	
		  $.ajax({
				type: "POST",
				url: "dil_collections/get_subcollections/" + collection_id,
				//data: "id=10",
				async: false,
				success: function(msg){
				}
				});//end ajax
		});
	});


