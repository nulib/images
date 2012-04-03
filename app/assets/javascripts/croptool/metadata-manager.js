/**
 * @fileoverview This file contains the code that manages the construction and updates for the 
 *	   metadata panel. The metadata panel contains the details that describes a given crop. This
 *	   information includes required elements such as title, size, position, and rotation, but also
 *	   includes site-specific variables defined in the *-persistence-manager.js files. (See these
 *	   files for details.)
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */

MetadataManager = {};

/**
 * Saves information describing the current crop to the persistence manager.
 */

MetadataManager.saveMetadata = function()
{
	if (CropManager.selectedCrop !== null)
	{
		CropManager.selectCrop(CropManager.selectedCrop);
		PersistenceManager.saveCrop(CropManager.selectedCrop);
		this.refresh();
		CropManager.selectCrop(CropManager.selectedCrop);
		ControlManager.showCropControls(crop);
	}
	else
		MetadataManager.hideCropDetails();
};

/**
 * Populates the metadata form with a crop's details.
 *
 * @param {Object} crop The currently-selected crop.
 */
 
MetadataManager.showCropDetails = function(crop)
{
	$("li.crop-list-item").each(function()
	{
		$(this).removeClass("crop-list-selected");
	});
		
	$("li#" + crop.uuid).addClass("crop-list-selected");

	ControlManager.showCropControls(crop);
	ControlManager.toFront();
};

MetadataManager.showDirtyCrop = function(crop)
{
	$("li#" + crop.uuid).addClass("dirty");
};


/**
 * Hide any visible crop details / clear the metadata form. Invoked when no crop is currently 
 *	   selected.
 */

MetadataManager.hideCropDetails = function()
{
	$("div#metadata").css("display", "none");

	$("li.crop-list-item").each(function()
	{
		$(this).removeClass("crop-list-selected");
	});
	
	ControlManager.hideCropControls();
	ControlManager.toFront();
};

/**
 * Refreshes the crop list (typically found in the upper-right) with the latest crops.
 */

MetadataManager.refresh = function()
{
	$("ul#sortable").html("");

	var i = CropManager.crops.length;

	for (i = CropManager.crops.length; i > 0; i--)
	{
		var crop = CropManager.crops[i - 1];
		
		$("ul#sortable").append("<li id=\"" + crop.uuid + "\" class=\"crop-list-item\">" + 
								crop.metadata.title + "</li>");
								
		if (crop.dirty)
		{
			$("li#" + crop.uuid).addClass("dirty");
		}
	}

	// Add a selection handler that loads the metadata (showCropDetails) when an crop is selected
	// from the list.
	
	$("li.crop-list-item").click(function()
	{
		var deselect = $(this).hasClass("crop-list-selected");
		
		$("li.crop-list-item").each(function()
		{
			$(this).removeClass("crop-list-selected");
		});

		if (!deselect)
		{
			var i = 0;
			for (i = 0; i < CropManager.crops.length; i++)
			{
				var crop = CropManager.crops[i];
			
				if (crop.uuid === $(this).attr("id"))
				{
					if (crop.setViewPort !== undefined)
					{
						crop.setViewPort();
					}
					
					CropManager.selectCrop(crop);
				}
			}
		}
		else
		{
			CropManager.selectCrop(null);
		}
	});

	$("#sortable").sortable(
	{
		update: function(event, ui)
		{
			var items = $("#sortable").sortable("toArray");

			var i = 0;
			for (i = items.length; i > 0; i--)
			{
				CropManager.bringToFront(items[i - 1]);
			}

			PersistenceManager.setCropOrder(items);
		}
	});
	
	var pos = $(CropTool.rootDiv).offset();

	$("#collection").css("left", (pos.left + 10) + "px");
	$("#collection").css("top", (pos.top + 10) + "px");

	if (CropManager.crops.length > 1)
		$("#collection").css("display", "block");
	else
		$("#collection").css("display", "none");
};

/**
 * Constructs the HTML for the crop details panel (lower-left) and crop list panel (upper-right).
 */
 
MetadataManager.initializeDetails = function()
{
	MetadataManager.cropController = {};
	
	// Build the details panel...
	
	this.refresh();
};
