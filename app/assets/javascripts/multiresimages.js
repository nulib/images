// For adding and deleting fields for views/multiresimages/_edit_description.html.erb
	
	//user wants to add another text field (also adds a delete button)
	function addField(vraSetName) {
         
          //get id prefix for text field and delete button
          var txtFieldIdPrefix = "multiresimage_" + vraSetName + "Set_display_";
          var deleteBtnIdPrefix = "multiresimage_delete_" + vraSetName + "Set_display_";
          
          //id index for new field
          var newFieldIndex = $('input[id^=' + txtFieldIdPrefix + ']').length;
          
          var newTxtFieldId = "";
          var newDeleteBtnId = "";
          
          //if there is already a text field for the set, clone it
          if (newFieldIndex > 0){
            
            //index of last text field for the set
            var lastFieldIndex = newFieldIndex - 1;
           
            //new text field's id
            newTxtFieldId = txtFieldIdPrefix + newFieldIndex;
		    
		    //last text field's id
		    var lastTxtFieldId = txtFieldIdPrefix + lastFieldIndex;
		  
		    //new button's id
		    newDeleteBtnId = deleteBtnIdPrefix + newFieldIndex;
		    
		    //last button's id
		    var lastDeleteBtnId = deleteBtnIdPrefix + lastFieldIndex;
		
		    //clone the last text field for the set
            var $clone_txt_field = $('input[id=' + lastTxtFieldId + ']').clone();
            
            //insert the clone text field after the last delete button of the set
            $clone_txt_field.insertAfter('input[id=' + lastDeleteBtnId +']');
            
			$("<p>").insertAfter('input[id=' + lastDeleteBtnId +']');

            //assign a new id
            $clone_txt_field.attr("id", newTxtFieldId);
            
            //assign a new name
            $clone_txt_field.attr("name", newTxtFieldId);
            
            //clear the value in the clone
            $clone_txt_field.val("");
          
            //clone button and update attributes
            var $clone_delete_btn= $('input[id=' + lastDeleteBtnId + ']').clone();
            $clone_delete_btn.insertAfter('input[id=' + newTxtFieldId +']');
            $clone_delete_btn.attr("id", newDeleteBtnId);
            $clone_delete_btn.attr("name", "commit");

          }
          
          //there isn't a text field for the set, so clone title (that's a required field)
          else {
            newTxtFieldId = txtFieldIdPrefix + "0";
            newDeleteBtnId = deleteBtnIdPrefix + "0";
            
            //clone the first title field (it's required to be there)
            var $clone_txt_field = $('input[id="multiresimage_titleSet_display_0"]').clone();
            vraSetName = vraSetName.charAt(0).toUpperCase() + vraSetName.substring(1);
            
            //clone text field and update attributes
            $clone_txt_field.insertBefore('input[id=add' + vraSetName + ' ]');
            $clone_txt_field.attr("id", newTxtFieldId);
            $clone_txt_field.attr("name", newTxtFieldId);
            $clone_txt_field.val("");
            
            //clone button and update attributes
            var $clone_delete_btn= $('input[id="multiresimage_delete_titleSet_display_0"]').clone();
            $clone_delete_btn.insertAfter('input[id=' + newTxtFieldId + ']');
            $clone_delete_btn.attr("id", newDeleteBtnId);
            $clone_delete_btn.attr("name", "commit");
            
          }
      
        }
      
     //user wants to delete a text field (also deletes it's delete button)
     function deleteField(field, vraSetName) {
          
          //id of field
          var btnId = field.attr("id");
          
          //button id prefix (without index)
          var btnIdPrefix = "multiresimage_delete_" + vraSetName + "Set_display_";
          
          //to get index number
          var beginIndex = btnId.lastIndexOf("_") + 1;
          var fieldIndex = btnId.substring(beginIndex);
          
          //text field id prefix
          var txtIdPrefix = "multiresimage_" + vraSetName + "Set_display_";
          var txtId = txtIdPrefix + fieldIndex;
          
          //remove button
          $('input[id^=' + btnId + ']').remove();
          
          //remove text box
          $('input[id^=' + txtId + ']').remove();
          
          //update index numbers for each index after the deleted row (example value[2] becomes value[1] if value[1] was deleted)
          var numFields = $('input[id^=' + btnIdPrefix + ']').length;
          fieldIndex++;
          for(i=fieldIndex; i <= numFields; i++){
            updateBtnId = btnIdPrefix + (i);
            newBtnId = btnIdPrefix + (i-1);
            
            updateTxtId = txtIdPrefix + (i);
            newTxtId = txtIdPrefix + (i-1);
            
            $('input[id=' + updateBtnId + ']').attr("id", newBtnId);
            
            $('input[id=' + updateTxtId + ']').attr("id", newTxtId);
          }
          
        }
        
        //Iterate through the set's fields and concanate them, delimited by a semicolon
        //replace the hidden field's value for each set (this maps to the XML, example: titleSet_display_value field maps to 
        // <vra:titleSet><vra:display>title1 ; title 2; title 3</vra:display></vra:titleSet>
        function concatanateFields(vraSetName){
          var newValue = "";
          var txtFieldIdPrefix = "multiresimage_" + vraSetName + "Set_display_";
          var aggregateFieldId = "multiresimage_" + vraSetName + "Set_value";
          
          var numFields = $('input[id^=' + txtFieldIdPrefix + ']').length;
          
          for (i=0; i < numFields; i++){
            if (i !== 0){
              newValue = newValue + " ; ";
            }
            txtFieldId = txtFieldIdPrefix + i;
            newValue = newValue + $('input[id=' + txtFieldId + ']').val();
            $('input[id=' + txtFieldId + ']').removeAttr("name");
          }
          
          $('input[id=' + aggregateFieldId + ']').val(newValue);
          
        }
        
//click events for each Add and Delete button
 $(function() {
		
		$('#addTitle').live("click", (function() {
		  addField("title");
        }));
      
        $('#addAgent').live("click", (function() {
		  addField("agent");
        }));
        
        $('#addCulturalContext').live("click", (function() {
		  addField("culturalContext");
        }));
        
        $('#addDate').live("click", (function() {
		  addField("date");
        }));
        
        $('#addSubject').live("click", (function() {
		  addField("subject");
        }));
        
        $('#addLocation').live("click", (function() {
		  addField("location");
        }));
        
        $('#addStylePeriod').live("click", (function() {
		  addField("stylePeriod");
        }));
        
        $('#addDescription').live("click", (function() {
		  addField("description");
        }));
        
        $('#addWorktype').live("click", (function() {
		  addField("worktype");
        }));
        
        $('#addMaterial').live("click", (function() {
		  addField("material");
        }));
        
        $('#addMeasurements').live("click", (function() {
		  addField("measurements");
        }));
        
        $('#addInscription').live("click", (function() {
		  addField("inscription");
        }));
        
        $('#addSource').live("click", (function() {
		  addField("source");
        }));
        
        $('#addTechnique').live("click", (function() {
		  addField("technique");
        }));
        
        $('input[id^="multiresimage_delete_agentSet_display_"]').live("click", (function() {
		  deleteField($(this), "agent");
        }));
        
        $('input[id^="multiresimage_delete_titleSet_display_"]').live("click", (function() {
		  deleteField($(this), "title");
        }));
        
        $('input[id^="multiresimage_delete_descriptionSet_display_"]').live("click", (function() {
		  deleteField($(this), "description");
        }));
        
        $('input[id^="multiresimage_delete_dateSet_display_"]').live("click", (function() {
		  deleteField($(this), "date");
        }));
        
        $('input[id^="multiresimage_delete_subjectSet_display_"]').live("click", (function() {
		  deleteField($(this), "subject");
        }));
        
        $('input[id^="multiresimage_delete_locationSet_display_"]').live("click", (function() {
		  deleteField($(this), "location");
        }));
        
        $('input[id^="multiresimage_delete_stylePeriodSet_display_"]').live("click", (function() {
		  deleteField($(this), "stylePeriod");
        }));
        
        $('input[id^="multiresimage_delete_worktypeSet_display_"]').live("click", (function() {
		  deleteField($(this), "worktype");
        }));
        
        $('input[id^="multiresimage_delete_inscriptionSet_display_"]').live("click", (function() {
		  deleteField($(this), "inscription");
        }));
        
        $('input[id^="multiresimage_delete_culturalContextSet_display_"]').live("click", (function() {
		  deleteField($(this), "culturalContext");
        }));
        
        $('input[id^="multiresimage_delete_materialSet_display_"]').live("click", (function() {
		  deleteField($(this), "material");
        }));
        
        $('input[id^="multiresimage_delete_measurementsSet_display_"]').live("click", (function() {
		  deleteField($(this), "measurements");
        }));
        
        $('input[id^="multiresimage_delete_sourceSet_display_"]').live("click", (function() {
		  deleteField($(this), "source");
        }));
        
        $('input[id^="multiresimage_delete_techniqueSet_display_"]').live("click", (function() {
		  deleteField($(this), "technique");
        }));
        
        
        //when submit button is clicked, get all of the fields for each set, concatenate with a semicolon delimiter and
        //replace the hidden field's value for each set (this maps to the XML, example: titleSet_display_value field maps to 
        // <vra:titleSet><vra:display>title1 ; title 2; title 3</vra:display></vra:titleSet>
        
        $('input[class="btn btn-primary"]').click(function() {
		  concatanateFields("title");
		  concatanateFields("agent");
		  concatanateFields("date");
		  concatanateFields("culturalContext");
		  concatanateFields("location");
		  concatanateFields("inscription");
		  concatanateFields("worktype");
		  concatanateFields("description");
		  concatanateFields("subject");
		  concatanateFields("stylePeriod");
		  concatanateFields("material");
		  concatanateFields("measurements");
		  concatanateFields("source");
		  concatanateFields("technique");
        });
        
	});
	
//JQuery tooltip for batch_select checkboxes
$(function() {
  $("input[id^='batch_select_']").attr('title', 'Allows you to select multiple images to drag-and-drop to a collection').tooltip();
});

//JQuery tooltip for batch_select checkboxes
$(function() {
  $("input[id='dil_collection_title']").attr('title', 'Create a new collection by entering the name.  You can then drag-and-drop images to it.').tooltip();
});

//When a user clicks the checkbox for batch selecting images
$('input[id^="batch_select_"]').live("click", (function() {
  //"batch_select_" is prepended to each checkbox
  item_id = $(this).attr("id").substring(13);
  
  //if checked, add to batch_select list
  if ($(this).attr("checked")!=null && $(this).attr("checked")=="checked"){
    url="dil_collections/add_to_batch_select/" + item_id;
    $(this).parent().addClass("thumbnailSelected");
  }
  //if unchecked, remove from batch_select list
  else {
    url="dil_collections/remove_from_batch_select/" + item_id;
    $(this).parent(   ).removeClass("thumbnailSelected");
  }

    $.ajax({
      type: "POST",
      url: url,
      dataType: 'json',
      success: function(output){
        //Change the selected items count
        $('div[id="batch_select_count"]').text(output.size);
      },
		
    error: function(output){
    }
  });//end ajax

}));

$(document).ready(function(){
  $('input[checked="checked"]').closest('.listing').addClass("thumbnailSelected");
  
  // When a user wants to add an image to a collection from the image show view, they click a button.
  // This will get the collection titles and pids by calling an API and show a select list with the collections
  $("#addToImageGroupBtn").live("click",(function() {
   
   if ($("#collection_list").length==0){
     //make ajax call to get collections and build select list
     var select_list = "<select id='collection_list'>"
     $.ajax({
        type: "GET",
        url: '/dil_collections/get_collections.json',
        dataType: 'json',
        success: function(jsonObject){
          //loop through each collection the json
          var selectList = "<select id='collection_list'>"
          $.each(jsonObject, function(){
            selectList += "<option val='" + this.id + "' id='" + this.id + "'>" + this.title_tesim[0] + "</option>" 
          });
        
          selectList += "</select>"
          $("#downloads").append(selectList);
          $("#downloads").append("<br/><div id='submitCollectionDiv' style='position:relative;'><button class='btn btn-primary' id='submitCollectionBtn'>Save</button><span id='spinnerElement' style='position:absolute; top:12px; left:68px; background-color:red;'></span></div><br/><br/><br/>");
        },
		
      error: function(output){
        alert("Could not add image to Image Group");
      }
     });//end ajax
   }//end if
  }));
  
  
  // This method is called when a user clicks the Save button to add an image to an image group from the image show view.
  // An API is called to add the image to the collection.
  $("#submitCollectionBtn").live("click", (function() {
    //get the collection pid from the select list selected option 
    var collectionPid = $("#collection_list option:selected").attr("id");
    //get the image pid from the url
    var imagePid = $("[name='id']")[0].value;

    
    //This is spin.js code to show a spinner
    var spinOpts = {
      lines: 8, // The number of lines to draw
      length: 4, // The length of each line
      width: 4, // The line thickness
      radius: 4, // The radius of the inner circle
      top: 'auto', // Top position relative to parent in px
      left: 'auto' // Left position relative to parent in px
    };
    var target = document.getElementById('spinnerElement');
    var spinner = new Spinner(spinOpts).spin(target);
    
    //make the API call
    $.ajax({
      type: "POST",
      url: "/dil_collections/add/" + collectionPid + "/" + imagePid,
      success: function(jsonObject){
        spinner.stop();
      },
		
    error: function(output){
      alert("Could not add image to Image Group");
      spinner.stop();
    }
  });//end ajax
     
  }));
  
  
});

  


