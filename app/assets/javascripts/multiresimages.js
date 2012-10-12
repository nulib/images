// For adding and deleting fields for views/multiresimages/_edit_description.html.erb
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
        });
        
	});
	
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
            var lastFieldIndex = newFieldIndex - 1;
        
            newTxtFieldId = txtFieldIdPrefix + newFieldIndex;
		    var lastTxtFieldId = txtFieldIdPrefix + lastFieldIndex;
		  
		    newDeleteBtnId = deleteBtnIdPrefix + newFieldIndex;
		    var lastDeleteBtnId = deleteBtnIdPrefix + lastFieldIndex;
		
            var $clone_txt_field = $('input[id=' + lastTxtFieldId + ']').clone();
            $clone_txt_field.insertAfter('input[id=' + lastDeleteBtnId +']');
            $clone_txt_field.attr("id", newTxtFieldId);
            $clone_txt_field.attr("name", newTxtFieldId);
          
            var $clone_delete_btn= $('input[id=' + lastDeleteBtnId + ']').clone();
            $clone_delete_btn.insertAfter('input[id=' + newTxtFieldId +']');
            $clone_delete_btn.attr("id", newDeleteBtnId);
            $clone_delete_btn.attr("name", "commit");
          }
          
          //there isn't a text field for the set, so clone title (that's a required field)
          else {
            newTxtFieldId = txtFieldIdPrefix + "0";
            newDeleteBtnId = deleteBtnIdPrefix + "0";
            
            var $clone_txt_field = $('input[id="multiresimage_titleSet_display_0"]').clone();
            vraSetName = vraSetName.charAt(0).toUpperCase() + vraSetName.substring(1);
            
            $clone_txt_field.insertBefore('input[id=add' + vraSetName + ' ]');
            $clone_txt_field.attr("id", newTxtFieldId);
            $clone_txt_field.attr("name", newTxtFieldId);
            
            var $clone_delete_btn= $('input[id="multiresimage_delete_titleSet_display_0"]').clone();
            $clone_delete_btn.insertAfter('input[id=' + newTxtFieldId + ']');
            $clone_delete_btn.attr("id", newDeleteBtnId);
            $clone_delete_btn.attr("name", "commit");
            
          }
      
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
        


