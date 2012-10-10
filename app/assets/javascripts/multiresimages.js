// For adding and deleting fields for views/multiresimages/_edit_description.html.erb
	$(function() {
		
		$('#btnAddTitle').click(function() {
		  addField("title");
        });
      
        $('#btnAddAgent').click(function() {
		  addField("agent");
        });
        
        $('#btnAddDate').click(function() {
		  addField("date");
        });
        
        $('#btnAddSubject').click(function() {
		  addField("subject");
        });
        
        $('#btnAddLocation').click(function() {
		  addField("location");
        });
        
        $('#btnAddStylePeriod').click(function() {
		  addField("stylePeriod");
        });
        
        $('#btnAddDescription').click(function() {
		  addField("description");
        });
        
        $('#btnAddWorktype').click(function() {
		  addField("worktype");
        });
        
        
        $('input[id^="multiresimage_delete_titleSet_display_"]').click(function() {
		  deleteField($(this), "title");
        });
        
	});
	
	function addField(vraSetName) {
         
          var txtFieldIdPrefix = "multiresimage_" + vraSetName + "Set_display_";
          var deleteBtnIdPrefix = "multiresimage_delete_" + vraSetName + "Set_display_";
        
          var newFieldIndex = $('input[id^=' + txtFieldIdPrefix + ']').length;
          var lastFieldIndex = newFieldIndex - 1;
        
          var newTxtFieldId = txtFieldIdPrefix + newFieldIndex;
		  var lastTxtFieldId = txtFieldIdPrefix + lastFieldIndex;
		  
		  var newDeleteBtnId = deleteBtnIdPrefix + newFieldIndex;
		  var lastDeleteBtnId = deleteBtnIdPrefix + lastFieldIndex;
		
          var $clone_txt_field = $('input[id=' + lastTxtFieldId + ']').clone();
          $clone_txt_field.insertAfter('input[id=' + lastDeleteBtnId +']');
          $clone_txt_field.attr("id", newTxtFieldId); 
          
          var $clone_delete_btn= $('input[id=' + lastDeleteBtnId + ']').clone();
          $clone_delete_btn.insertAfter('input[id=' + newTxtFieldId +']');
          $clone_delete_btn.attr("id", newDeleteBtnId); 
      
        }
    
        

      
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
          
          //update index numbers for each index after the deleted row
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
        


