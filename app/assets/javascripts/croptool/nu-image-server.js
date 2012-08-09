/*global $, CoordinateManager, Image */

// Fedora: ***REMOVED***

var ImageServer = {};

ImageServer.tile_size = 255;

function setImageParameters(element)
{
	ImageServer.imagePath = $(element).attr("xlink:href");

	ImageServer.details = {};

	ImageServer.details.levels = 0; // FIX

	ImageServer.details.o_width = parseInt($(element).attr("width"), 10);
	ImageServer.details.o_height = parseInt($(element).attr("height"), 10);

	ImageServer.details.width = ImageServer.tile_size * Math.ceil(ImageServer.details.o_width / (ImageServer.tile_size + 1));
	ImageServer.details.height = ImageServer.tile_size * Math.ceil(ImageServer.details.o_height / (ImageServer.tile_size + 1));

	var min_side = ImageServer.details.o_width;

	if (ImageServer.details.height > ImageServer.details.width)
		min_side = ImageServer.details.o_height;
		
	for (ImageServer.details.levels = 0; min_side >= (ImageServer.tile_size + 1); ImageServer.details.levels++)
		min_side = min_side / 2;

	CoordinateManager.initialize(ImageServer.details.width, ImageServer.details.height, ImageServer.details.levels);
	PersistenceManager.initialize(CropTool.identifier);
	ControlManager.initialize();
//	ControlManager.updateZoomWidget();
//	ControlManager.updateZoom(CoordinateManager.current_level);
};

ImageServer.initialize = function(image)
{
	this.image = image; 

/*
<svg:svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svg="http://www.w3.org/2000/svg">
	<svg:image x="0" y="0" width="5700" height="7200" xlink:href="inu-wint/inu-wint-26.10.jp2">
    	<svg:clipPath>
        	<svg:rect type="crop_then_rotate" x="3124" y="2841" width="1337" height="2039" transform="rotate(90)"></svg:rect>
                     
			<svg:rect type="rotate_then_crop" x="2320" y="3124" width="2039" height="1337" transform="rotate(90)"></svg:rect>
        </svg:clipPath>
	</svg:image>
</svg:svg>

-- OR --

<svg:svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svg="http://www.w3.org/2000/svg">
	<svg:image x="0" y="0" width="13210" height="9990" xlink:href="inu-wint/inu-wint-9.6.jp2">
		<svg:clipPath>
			<svg:rect x="2580" y="516" width="10630" height="8441"></svg:rect>
		</svg:clipPath>
	</svg:image>
</svg:svg>
*/

	var url = Site.fetchImageUrl(this.image);

	var me = this;
	
	$.ajax({ url: url, success: function(data) 
	{
		if (data.length === 0)
		{
			alert("ImageServer.initialize: Unable to fetch " + url + ". Check that everything is served from the same host.");
			return;
		}

		var svg_use = $(data).find("use");

		if (svg_use.length == 0)
			svg_use = $(data).find("svg\\:use");
		
		if (svg_use.length > 0) // Crop or parent?
		{
			svg_use.each(function() 
			{
				var use_url = $(this).attr("xlink:href");
				
				var toks = use_url.split("/");

				ImageServer.initialize(toks[5]);
			});
		}
		else
		{
			var svg_image = $(data).find("svg\\:image");
			
			if (svg_image.length == 0)
				svg_image = $(data).find("image");
				
			svg_image.each(function() 
			{
				setImageParameters(this);
			});
		}
	}, error: function(jqXHR, textStatus, errorThrown)
	{
		alert("ImageServer.initialize: Unable to fetch " + url + ". Check that everything is served from the same host.");
	}});

	CropTool.resize();
};

// Generic
ImageServer.queueImage = function (img_url, callback, context)
{
	var img = new Image();

	$(img).load(function()
	{
		$(this).hide();
		$("body").append(this);

		callback(this, context);
			
	}).error(function() 
	{
		callback(null, context); 

		$(this).remove();
	}).attr("src", img_url);
};

ImageServer.tileAt = function(i, j, level, size)
{
	if (i * size * Math.pow(2, ImageServer.details.levels - level) > ImageServer.details.width)
		return null;

	if (j * size * Math.pow(2, ImageServer.details.levels - level) > ImageServer.details.height)
		return null;

	return Site.tileUrl(ImageServer.imagePath, level, i, j)
};

ImageServer.fetchThumbnail = function(width, height, callback)
{
	var req_height = ImageServer.details.height;
	var req_width = ImageServer.details.width;
	
	if ((width / height) > (ImageServer.details.width / ImageServer.details.height))
	{
		width = Math.floor(ImageServer.details.width * (height / ImageServer.details.height));
	}
	else
	{
		height = Math.floor(ImageServer.details.height * (width / ImageServer.details.width));
	}
	
	if (req_width / width < req_height / height)
	{
		req_width = width * Math.floor(req_height / height);
		req_height = height * Math.floor(req_height / height);
	}
	else
	{
		req_width = width * Math.floor(req_width / width);
		req_height = height * Math.floor(req_width / width);
	}

	var url = Site.thumbnailImageUrl(this.image, width, height, req_width, req_height);

	var img = new Image();

	$(img).load(function()
	{
		$(this).hide();
		$("body").append(this);

		callback(this);
	}).attr("src", url);
};

ImageServer.ratioCoordinatesForRect = function(left, top, width, height, level)
{
	level = ImageServer.details.levels - level;
	
	var coords = {};
	coords.abs_top = top * Math.pow(2, level);
	coords.abs_left = left * Math.pow(2, level);
	coords.abs_width = width * Math.pow(2, level);
	coords.abs_height = height * Math.pow(2, level);

	coords.top = coords.abs_top / ImageServer.details.height;
	coords.left = coords.abs_left / ImageServer.details.width;
	coords.width = coords.abs_width / ImageServer.details.width;
	coords.height = coords.abs_height / ImageServer.details.height;
	
	return coords;
};


