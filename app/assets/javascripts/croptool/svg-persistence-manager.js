/*global alert */

var PersistenceManager = {};

PersistenceManager.initialize = function(image)
{
	this.image = image;
	CropManager.crops = PersistenceManager.fetchCrops();
};

PersistenceManager.requestNewCrop = function()
{
	var vp = CoordinateManager.currentActualViewport();

	if (vp.x < 0)
	{
		vp.width = vp.width + vp.x;
		vp.x = 0;
	}

	if (vp.y < 0)
	{
		vp.height = vp.height + vp.y;
		vp.y = 0;
	}

	if ((vp.x + vp.width) > 	ImageServer.details.width)
		vp.width = ImageServer.details.width - vp.x;
		
	if ((vp.height + vp.y) > ImageServer.details.height)
		vp.height = ImageServer.details.height - vp.y;
	
	var fetch_url = Site.createCropUrl(vp.x, vp.y, vp.width, vp.height, ImageServer.image);

	$.get(fetch_url, function(data) 
	{
		// TODO: Check for <error /> return
		
		var pid = $(data).find("success").attr("pid");

		window.location = Site.catalogPathForPid(pid);
	});
};

PersistenceManager.loadCrop = function(pid)
{
	if (pid === undefined)
	{
		alert("Undefined PID. Check your URLs.");
		
		return;
	}

	var url = Site.fetchCropUrl(pid);

	$.ajax({ url: url, async:false, success: function(data) 
	{
		if (data.length === 0)
		{
			alert("PersistenceManager.loadCrop: Unable to fetch " + url + ". Check that everything is served from the same host.");
			return;
		}

		// Assumes 256x256 size for all tiles...
		
		var img_width = Math.ceil(ImageServer.details.width / ImageServer.tile_size) * ImageServer.tile_size;
		var img_height = Math.ceil(ImageServer.details.height / ImageServer.tile_size) * ImageServer.tile_size;

		var rects = $(data).find("rect");

		if (rects.length == 0)
			rects = $(data).find("svg\\:rect");
		
		rects.each(function()
		{
			var crop = CropManager.createNewCrop();
			crop.pid = pid;
			
			var x = parseInt($(this).attr("x"), 10);
			var y = parseInt($(this).attr("y"), 10);
			var width = parseInt($(this).attr("width"), 10);
			var height = parseInt($(this).attr("height"), 10);

			var cx = x + (width / 2);
			var cy = y + (height / 2);
			
			crop.cx = cx / img_width;
			crop.width = width / img_width;
			crop.cy = cy / img_height;
			crop.height = height / img_height;

			// TODO: More in line with SVG spec...

			// rotate(45 7891 4736.5)

			if ($(this).attr("transform"))
			{
				var transformString = $(this).attr("transform");

				var index = transformString.search("rotate");

				if (index != -1)
				{
					transformString = transformString.substring(index);
	
					var start = 6; // Had trouble doing .search("(")...
					var end = transformString.search(" ");

					if (end != -1)
					{
						var rotate = transformString.substring(start + 1, end);
			
						crop.rotation = parseInt(rotate, 10);
					}
				} 
			}

			if (crop.rotation === undefined)
				crop.rotation = 0;
			
			if ($(this).attr("style"))
			{
				var styleString = $(this).attr("style");
				
				var index = styleString.search("#");

				if (index != -1)
					crop.color = styleString.substring(index, index + 7);
			}
					
			if (crop.color === undefined)
				crop.color = "#888888";

			CropManager.crops.push(crop); // TODO: Add crop method on CropManager...

			MetadataManager.refresh();
			CropManager.updatePosition();				

			ControlManager.toFront();
		});
		
		if (CropManager.crops.length > 0)
		{
			setTimeout(function()
			{
				CropManager.crops[0].setViewPort();
				
				CropManager.setEditable(false);
				
				ControlManager.toFront();
				
			}, 100);
		}
	}, error: function(jqXHR, textStatus, errorThrown)
	{
		alert("PersistenceManager.fetchCrops: Unable to fetch " + url + ". Check that everything is served from the same host.");
	}});
};

PersistenceManager.saveCrop = function(crop)
{
	var prefix = '<?xml version="1.0"?>';
	prefix += '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ct="http://library.northwestern.edu/crop-tool" ';

	prefix += 'height="' + ImageServer.details.o_height + '" width="' + ImageServer.details.o_width + '">';
	
	// TODO: Site URL for xlink:href element...

	prefix += '<image style="overflow: auto" height="' + ImageServer.details.o_height + '" width="'
				 + ImageServer.details.o_width + '" xlink:href="http://example.com/ImageServer/imageserver?viewwidth=' +
				 + Math.floor(ImageServer.details.o_width / 10) + "&amp;viewheight=" 
				 + Math.floor(ImageServer.details.o_height / 10) +"&amp;filename=" + ImageServer.imagePath + '" />';

	var suffix = '</svg>';

	var crop_width = Math.floor(ImageServer.details.width * crop.width);
	var crop_height = Math.floor(ImageServer.details.height * crop.height);
	var crop_x = Math.floor(ImageServer.details.width * (crop.cx - (crop.width / 2)));
	var crop_y = Math.floor(ImageServer.details.height * (crop.cy - (crop.height / 2)));

	var mid_x = crop_x + (crop_width / 2);
	var mid_y = crop_y + (crop_height / 2);

	var rectString = '<rect height="' + crop_height + '" width="' + crop_width + '" x="' + crop_x + '" y="' + crop_y + '" '
					+ 'style="fill:' + crop.color + ';stroke:' + crop.color + ';opacity:0.5;" '
					+ 'transform="rotate(' + crop.rotation + ' ' + mid_x + ' ' + mid_y + ')">';
//						+ 'ct:rotation="' + crop.rotation + '" ct:color="' + crop.color + '">';

	rectString += "</rect>";
		
	var xmlString = prefix + rectString + suffix;

	alert("posting " + xmlString);
		
	var post_url = Site.putCropUrl(crop.pid);
		
	alert("saving to " + post_url);
		
	$.ajax({
		url: post_url,
		contentType: "text/xml",
		data: xmlString,
		type: "POST",
		success:  function(data)
		{
			alert("Crop data saved (" + crop.pid + ").");
		}
	});
};

PersistenceManager.saveCrops = function(crops)
{
	alert("PersistenceManager.saveCrops deprecated. Please check your sources.");
};

PersistenceManager.fetchCrops = function()
{
	PersistenceManager.loadCrop(PersistenceManager.image);

	return CropManager.crops;
};
