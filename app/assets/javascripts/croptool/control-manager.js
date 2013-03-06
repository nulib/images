/*global Image, $, CropTool, window, ImageServer, CoordinateManager, CropManager, alert, 
	PersistenceManager, TileManager */

/**
 * @fileoverview JavaScript for constructing and managing the control panel (bottom-left).
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */


var ControlManager = {};
ControlManager.mode = "move";

ControlManager.BASE_SIDE = 32;
ControlManager.FILL = "#424242";
ControlManager.STROKE = "#606060"; // "#919191";

ControlManager.hideCropControls = function()
{
	if (ControlManager.cropControls !== undefined)
	{
		ControlManager.cropControls.frame.remove();
		ControlManager.cropControls.frameIcon.remove();
		
		if (CropTool.editable)
		{
			ControlManager.cropControls.rotation.remove();
			ControlManager.cropControls.clockIcon.remove();
			ControlManager.cropControls.counterIcon.remove();
			ControlManager.cropControls.rotationBar.remove();
			ControlManager.cropControls.rotationSlider.remove();
			ControlManager.cropControls.color.remove();
			ControlManager.cropControls.colorIcon.remove();
			ControlManager.cropControls.save.remove();
			ControlManager.cropControls.saveIcon.remove();
		}

		if (ControlManager.cropControls.dimInfo !== undefined)
		{
			ControlManager.cropControls.dimInfo.remove();
			ControlManager.cropControls.dimText.remove();
		}

		if (ControlManager.cropControls.colorInfo !== undefined)
		{
			ControlManager.cropControls.colorInfo.remove();

			ControlManager.cropControls.black.remove();
			ControlManager.cropControls.blue.remove();
			ControlManager.cropControls.brown.remove();
			ControlManager.cropControls.green.remove();
			ControlManager.cropControls.orange.remove();
			ControlManager.cropControls.red.remove();
			ControlManager.cropControls.violet.remove();
			ControlManager.cropControls.yellow.remove();
			ControlManager.cropControls.white.remove();
		}
		
		delete ControlManager.cropControls;
	}
};

ControlManager.showCropControls = function(crop)
{
	if (ControlManager.cropControls === undefined)
	{
		var controls = {};
		
		var base = ControlManager.BASE_SIDE;

		var frameInfo = function(event)
		{
			if (ControlManager.cropControls.dimInfo !== undefined)
			{
				ControlManager.cropControls.dimInfo.remove();
				ControlManager.cropControls.dimText.remove();
			}

			var y = $(CropTool.rootDiv).height() - base - 40;

			var pathString = "M 20 " + y;
			pathString += "L 80 " + y;
			pathString += "C 80 " + y + " 90 " + y + " 90 " + (y + 10);
			pathString += "L 90 " + (y + 20);
			pathString += "C 90 " + (y + 20) + " 90 " + (y + 30) + " 80 " + (y + 30);
			pathString += "L 20 " + (y + 30);

			pathString += "L 10 " + (y + 40);
			pathString += "L 10 " + (y + 10);
			pathString += "C 10 " + (y + 10) + " 10 " + y + " 20 " + y;
			
			var dimInfo = CropTool.paper.path(pathString);
			dimInfo.attr("fill", "#444");
			dimInfo.attr("stroke", "none");
			dimInfo.attr("fill-opacity", 0.75);
			ControlManager.cropControls.dimInfo = dimInfo;	
			ControlManager.cropControls.dimInfo.toFront();
			
			var crop = CropManager.selectedCrop;

			var dimString = Math.floor(ImageServer.details.width * crop.width) + "x";
			dimString += Math.floor(ImageServer.details.height * crop.height) + "\n";
			dimString += Math.floor(ImageServer.details.width * (crop.cx - (crop.width / 2))) + ", ";
			dimString += Math.floor(ImageServer.details.height * (crop.cy - (crop.height / 2)));

			var dimText = CropTool.paper.text(50, y + 15, dimString);
			dimText.attr("fill", "#fff");
			dimText.attr("stroke", "none");
			ControlManager.cropControls.dimText = dimText;	
			ControlManager.cropControls.dimText.toFront();
		};
		
		var frame = CropTool.paper.rect(0, base, base, base);
		frame.click(frameInfo);
		frame.attr("fill", ControlManager.FILL);
		frame.attr("stroke", ControlManager.STROKE);
		controls.frame = frame; 
		
		var frameIcon = CropTool.paper.image(Site.iconPath() + "ruler-24.png", 8, 8, 24, 24);
		frameIcon.click(frameInfo);
		controls.frameIcon = frameIcon; 

		if (CropTool.editable)
		{
			var rotation = CropTool.paper.rect(base, base, base * 6, base);
			rotation.attr("fill", ControlManager.FILL);
			rotation.attr("stroke", ControlManager.STROKE);
			controls.rotation = rotation;	

			var clockIcon = CropTool.paper.image(Site.iconPath() + "clock-16.png", (base * 6) + 8, (base * 6) + 9, 16, 16);
			clockIcon.click(function(event)
			{
				var rotation = CropManager.selectedCrop.rotation;

				rotation = Math.floor(rotation + 1);
			
				if (rotation >= 0 && rotation < 360)
				{
					CropManager.selectedCrop.rotation = rotation;
					CropManager.updatePosition();
					ControlManager.cropControls.rotationSlider.setRotation(rotation);
				}
				else
					alert("Cannot rotate further.");
			});
			controls.clockIcon = clockIcon; 

			var counterIcon = CropTool.paper.image(Site.iconPath() + "counter-16.png", base + 8, (base * 6) + 9, 16, 16);
			counterIcon.click(function(event)
			{
				var rotation = CropManager.selectedCrop.rotation;

				rotation = Math.floor(rotation - 1);
			
				if (rotation >= 0 && rotation < 360)
				{
					CropManager.selectedCrop.rotation = rotation;
					CropManager.updatePosition();
					ControlManager.cropControls.rotationSlider.setRotation(rotation);
				}
				else
					alert("Cannot rotate further.");
			});
			controls.counterIcon = counterIcon; 

			var rotationBar = CropTool.paper.rect(2 * base, 0, (base * 4), 20, 5);
			rotationBar.attr("fill", "#222");
			rotationBar.attr("stroke", ControlManager.STROKE);
			controls.rotationBar = rotationBar; 

			var rotationSlider = CropTool.paper.rect((2 * base) + 1, 0, 10, 18, 4);
			rotationSlider.attr("fill", "#800");
			rotationSlider.attr("stroke", "none");

			rotationSlider.setRotation = function(degrees)
			{
				var x = rotationBar.attr("x") + 1;
				var ratio = degrees / 360;
				var width = rotationBar.attr("width") - rotationSlider.attr("width") - 1;
		
				rotationSlider.attr("x", x + Math.floor(ratio * width));
			
				TileManager.updatePosition();
				CropManager.updatePosition();		
				ControlManager.toFront();
			}

			var start = function() 
			{
				rotationSlider.ox = rotationSlider.attr("x");
			};

			var move = function(dx, dy) 
			{
				var x = Math.floor(rotationSlider.ox + dx);
		
				if (x > rotationBar.attr("x") && x + rotationSlider.attr("width") < rotationBar.attr("x") + rotationBar.attr("width") - 1)
				{
					rotationSlider.attr("x", x);
			
					var delta = Math.floor(x - rotationBar.attr("x"));
					var width = Math.floor(rotationBar.attr("width") - rotationSlider.attr("width") - 1);
					var degrees = Math.round((delta / width) * 360);
				
					if (degrees > 359 || degrees < 0)
						degrees = 0;

					CropManager.selectedCrop.rotation = degrees;
					TileManager.updatePosition();
					CropManager.updatePosition();		
					ControlManager.toFront();
				}
			};

			var up = function () 
			{

			};
	
			rotationSlider.drag(move, start, up);

			controls.rotationSlider = rotationSlider;	

			var colorClick = function(event)
			{
				if (ControlManager.cropControls.colorInfo !== undefined)
				{
					ControlManager.toFront();
				}

				var setCropColor = function(color)
				{
					CropManager.selectedCrop.color = color;
						
					CropManager.updatePosition();
					ControlManager.toFront();
				};
					
				var x = base * 7.5;
				var y = $(CropTool.rootDiv).height() - base - 100;

				var pathString = "M " + (x + 10) + " " + y;
				pathString += "L " + (x + 80) + " " + y;
				pathString += "C " + (x + 80) + " " + y + " " + (x + 90) + " " + y + " " + (x + 90) + " " + (y + 10);
				pathString += "L " + (x + 90) + " " + (y + 80);
				pathString += "C " + (x + 90) + " " + (y + 80) + " " + (x + 90) + " " + (y + 90) + " " + (x + 80) + " " + (y + 90);
				pathString += "L " + (x + 10) + " " + (y + 90);
				
				pathString += "L " + x + " " + (y + 100);
				pathString += "L " + x + " " + (y + 10);
				pathString += "C " + x + " " + (y + 10) + " " + x + " " + y + " " + (x + 10) + " " + y;
			
				var colorInfo = CropTool.paper.path(pathString);
				colorInfo.attr("fill", "#444");
				colorInfo.attr("stroke", "none");
				colorInfo.attr("fill-opacity", 0.75);
				ControlManager.cropControls.colorInfo = colorInfo;	
				ControlManager.cropControls.colorInfo.toFront();

				controls.black = CropTool.paper.rect(x + 10, y + 10, 20, 20);
				controls.black.attr("fill", "#000");
				controls.black.attr("stroke", "none");
				controls.black.click(function(event)
				{
					setCropColor("#000000");
				});
				controls.black.toFront();
					
				controls.blue = CropTool.paper.rect(x + 35, y + 10, 20, 20);
				controls.blue.attr("fill", "#1F75FE");
				controls.blue.attr("stroke", "none");
				controls.blue.click(function(event)
				{
					setCropColor("#1F75FE");
				});
				controls.blue.toFront();

				controls.brown = CropTool.paper.rect(x + 60, y + 10, 20, 20);
				controls.brown.attr("fill", "#B4674D");
				controls.brown.attr("stroke", "none");
				controls.brown.click(function(event)
				{
					setCropColor("#B4674D");
				});
				controls.brown.toFront();

				controls.green = CropTool.paper.rect(x + 10, y + 35, 20, 20);
				controls.green.attr("fill", "#1CAC78");
				controls.green.attr("stroke", "none");
				controls.green.click(function(event)
				{
					setCropColor("#1CAC78");
				});
				controls.green.toFront();

				controls.orange = CropTool.paper.rect(x + 35, y + 35, 20, 20);
				controls.orange.attr("fill", "#FF7538");
				controls.orange.attr("stroke", "none");
				controls.orange.click(function(event)
				{
					setCropColor("#FF7538");
				});
				controls.orange.toFront();

				controls.red = CropTool.paper.rect(x + 60, y + 35, 20, 20);
				controls.red.attr("fill", "#EE204D");
				controls.red.attr("stroke", "none");
				controls.red.click(function(event)
				{
					setCropColor("#EE204D");
				});
				controls.red.toFront();

				controls.violet = CropTool.paper.rect(x + 10, y + 60, 20, 20);
				controls.violet.attr("fill", "#926EAE");
				controls.violet.attr("stroke", "none");
				controls.violet.click(function(event)
				{
					setCropColor("#926EAE");
				});
				controls.violet.toFront();

				controls.yellow = CropTool.paper.rect(x + 35, y + 60, 20, 20);
				controls.yellow.attr("fill", "#FCE883");
				controls.yellow.attr("stroke", "none");
				controls.yellow.click(function(event)
				{
					setCropColor("#FCE883");
				});
				controls.yellow.toFront();

				controls.white = CropTool.paper.rect(x + 60, y + 60, 20, 20);
				controls.white.attr("fill", "#ffffff");
				controls.white.attr("stroke", "none");
				controls.white.click(function(event)
				{
					setCropColor("#ffffff");
				});
				controls.white.toFront();
			};
		
			var color = CropTool.paper.rect(base * 7, base, base, base);
			color.attr("fill", ControlManager.FILL);
			color.attr("stroke", ControlManager.STROKE);
			color.click(colorClick);
			controls.color = color; 
		
			var colorIcon = CropTool.paper.image(Site.iconPath() + "color-24.png", base, base, 24, 24);
			colorIcon.click(colorClick);
			controls.colorIcon = colorIcon; 

			var saveClick = function(event)
			{
				PersistenceManager.saveCrop(CropManager.selectedCrop);
			};

			var save = CropTool.paper.rect(base * 8, base, base, base);
			save.attr("fill", ControlManager.FILL);
			save.attr("stroke", ControlManager.STROKE);
			save.click(saveClick);
			controls.save = save;	

			var saveIcon = CropTool.paper.image(Site.iconPath() + "save-24.png", base, base, 24, 24);
			saveIcon.click(saveClick);
			controls.saveIcon = saveIcon;	
		}
		
		ControlManager.cropControls = controls;
	}

	var height = $(CropTool.rootDiv).height() - 1;

	var frame = ControlManager.cropControls.frame;
	frame.attr("y", height - ControlManager.BASE_SIDE);
	frame.toFront();

	ControlManager.cropControls.frameIcon.attr("y", frame.attr("y") + 4);
	ControlManager.cropControls.frameIcon.attr("x", frame.attr("x") + 4);
	ControlManager.cropControls.frameIcon.toFront();

	if (CropTool.editable)
	{
		var rotation = ControlManager.cropControls.rotation;
		rotation.attr("y", height - ControlManager.BASE_SIDE);
		rotation.toFront();
	
		ControlManager.cropControls.clockIcon.attr("y", rotation.attr("y") + 8);
		ControlManager.cropControls.counterIcon.attr("y", rotation.attr("y") + 8);

		ControlManager.cropControls.rotationBar.attr("y", rotation.attr("y") + 7);
		ControlManager.cropControls.rotationSlider.attr("y", rotation.attr("y") + 8);

		var color = ControlManager.cropControls.color;
		color.attr("y", height - ControlManager.BASE_SIDE);
		color.toFront();
	
		ControlManager.cropControls.colorIcon.attr("y", color.attr("y") + 4);
		ControlManager.cropControls.colorIcon.attr("x", color.attr("x") + 4);
		ControlManager.cropControls.colorIcon.toFront();
	
		var save = ControlManager.cropControls.save;
		save.attr("y", height - ControlManager.BASE_SIDE);
		save.toFront();

		ControlManager.cropControls.saveIcon.attr("y", save.attr("y") + 4);
		ControlManager.cropControls.saveIcon.attr("x", save.attr("x") + 4);
		ControlManager.cropControls.saveIcon.toFront();

		TileManager.updatePosition();
		CropManager.updatePosition();		
		ControlManager.toFront();
	}
};

ControlManager.updateRotation = function(degrees)
{
	if (ControlManager.controls.rotationSlider !== undefined)
	{
		var x = ControlManager.controls.rotationBar.attr("x") + 1;
		var ratio = degrees / 360;
		var width = ControlManager.controls.rotationBar.attr("width") - ControlManager.controls.rotationSlider.attr("width") - 1;
		
		ControlManager.controls.rotationSlider.attr("x", x + Math.floor(ratio * width));
	}
};

ControlManager.updateZoom = function(zoomLevel)
{
	if (ControlManager.controls !== undefined && ControlManager.controls.zoomSlider !== undefined)
	{
		var top = CoordinateManager.level_count - CoordinateManager.base_level;
		zoomLevel = zoomLevel - CoordinateManager.base_level;
		
		var y = ControlManager.controls.zoomBar.attr("y") + 1;
		var ratio = 1 - (zoomLevel / top);
		var height = ControlManager.controls.zoomBar.attr("height") - ControlManager.controls.zoomSlider.attr("height") - 2;

		ControlManager.controls.zoomSlider.attr("y", y + Math.floor(ratio * height));
		ControlManager.controls.zoomSlider.attr("x", ControlManager.controls.zoomBar.attr("x") + 1);
	}
};

/** 
 * Creates the control panel and binds the actions to the approriate widgets.
 */

ControlManager.initialize = function ()
{
	var height = $(CropTool.rootDiv).height() - 1;
	var width = $(CropTool.rootDiv).width() - 1;

	var controls = {};
		
	var base = ControlManager.BASE_SIDE;
    
    var mode = CropTool.paper.rect();
	// Draw the area for the move tool
	//var mode = CropTool.paper.rect(width - base, height - base, base, base);
	//mode.attr("fill", ControlManager.FILL);
	//mode.attr("stroke", ControlManager.STROKE);

	var toggleFunction = function(event)
	{
		var currentMode = ControlManager.mode;

		var icon = ControlManager.controls.modeIcon;	
		
		var modeIcon = null;

		if (currentMode === "move")
		{
			modeIcon = CropTool.paper.image(Site.iconPath() + "edit-24.png", icon.attr("x"), icon.attr("y"), 24, 24);

			CropManager.setEditable(true);
			CropManager.setDrawable(false);
		
			if (CropManager.selectedCrop !== null)
				MetadataManager.showCropDetails(CropManager.selectedCrop);

			ControlManager.mode = "edit";
		}
		else
		{
			modeIcon = CropTool.paper.image(Site.iconPath() + "move-24.png", icon.attr("x"), icon.attr("y"), 24, 24);

			MetadataManager.hideCropDetails();
			CropManager.setEditable(false);
			CropManager.setDrawable(false);
			
			ControlManager.mode = "move";
		}

		modeIcon.click(toggleFunction);
		modeIcon.toFront();
		controls.modeIcon = modeIcon;

		icon.remove();
	};

	mode.click(toggleFunction);

	controls.mode = mode;	
	
	//Add the move icon
	var modeIcon = CropTool.paper.image();
	modeIcon.click(toggleFunction);
	controls.modeIcon = modeIcon;	

	if (CropTool.editable)
	{
		var create = CropTool.paper.rect(width - base, 0, base, base);
		create.attr("fill", ControlManager.FILL);
		create.attr("stroke", ControlManager.STROKE);

		var createFunction = function(event)
		{
			if (confirm("Create a new crop using current viewport?"))
				PersistenceManager.requestNewCrop();
		};
	
		create.click(createFunction);

		controls.create = create;	

		var createIcon = CropTool.paper.image(Site.iconPath() + "camera.png", width - base + 6, 7, 20, 20);
		createIcon.click(createFunction);
		controls.createIcon = createIcon;	
	}

	var rotation = CropTool.paper.rect(width - (base * 8), 0, (base * 6), base);
	rotation.attr("fill", ControlManager.FILL);
	rotation.attr("stroke", ControlManager.STROKE);
	controls.rotation = rotation;	

	var clockIcon = CropTool.paper.image(Site.iconPath() + "clock-16.png", width - (base * 3) + 8, 9, 16, 16);
	clockIcon.click(function(event)
	{
		var rotation = CoordinateManager.currentRotation();
		
		var newRotation = Math.floor(rotation + 1);
		
		if (newRotation < 360)
			CoordinateManager.setRotation(newRotation);
		else
			alert("Cannot rotate clockwise further.");
	});
	controls.clockIcon = clockIcon; 

	var counterIcon = CropTool.paper.image(Site.iconPath() + "counter-16.png", width - (base * 8) + 8, 9, 16, 16);
	counterIcon.click(function(event)
	{
		var rotation = CoordinateManager.currentRotation();
		
		var newRotation = Math.floor(rotation - 1);
		
		if (newRotation > 0)
			CoordinateManager.setRotation(newRotation);
		else
			alert("Cannot rotate counter-clockwise further.");
	});
	controls.counterIcon = counterIcon; 

	var rotationBar = CropTool.paper.rect(counterIcon.attr("x") + counterIcon.attr("width") + 8, 6, (base * 4), 20, 5);
	rotationBar.attr("fill", "#222");
	rotationBar.attr("stroke", ControlManager.STROKE);
	controls.rotationBar = rotationBar; 

	var rotationSlider = CropTool.paper.rect(rotationBar.attr("x") + 1, 7, 10, 18, 4);
	rotationSlider.attr("fill", "#800");
	rotationSlider.attr("stroke", "none");

	var start = function() 
	{
		rotationSlider.ox = rotationSlider.attr("x");
	};

	var move = function(dx, dy) 
	{
		var x = Math.floor(rotationSlider.ox + dx);
		
		if (x > rotationBar.attr("x") && x + rotationSlider.attr("width") < rotationBar.attr("x") + rotationBar.attr("width") - 1)
		{
			rotationSlider.attr("x", x);
			
			var delta = Math.floor(x - rotationBar.attr("x"));
			var width = Math.floor(rotationBar.attr("width") - rotationSlider.attr("width") - 1);
			var degrees = Math.round((delta / width) * 360);
			
			if (degrees > 359 || degrees < 0)
				degrees = 0;
				
			CoordinateManager.setRotation(Math.floor(degrees));
		}
	};

	var up = function () 
	{

	};
	
	rotationSlider.drag(move, start, up);

	controls.rotationSlider = rotationSlider;	

	var zoom = CropTool.paper.rect(width - base, base * 2, base, base * 6);
	zoom.attr("fill", ControlManager.FILL);
	zoom.attr("stroke", ControlManager.STROKE);
	controls.zoom = zoom;	

	var zoomInIcon = CropTool.paper.image(Site.iconPath() + "in-16.png", width - base + 8.5, (base * 2) + 8, 16, 16);
	zoomInIcon.click(function(event)
	{
		CoordinateManager.zoomIn();
	});
	controls.zoomInIcon = zoomInIcon;	

	var zoomOutIcon = CropTool.paper.image(Site.iconPath() + "out-16.png", width - base + 8.5, (base * 8) - 24, 16, 16);
	zoomOutIcon.click(function(event)
	{
		CoordinateManager.zoomOut();
	});
	controls.zoomOutIcon = zoomOutIcon; 

	var zoomBar = CropTool.paper.rect(width - base + 6, (base * 3), 20, base * 4, 5);
	zoomBar.attr("fill", "#222");
	zoomBar.attr("stroke", ControlManager.STROKE);
	controls.zoomBar = zoomBar; 

	var zoomSlider = CropTool.paper.rect(zoomBar.attr("x") + 1, zoomBar.attr("y") + 1, 18, 10, 4);
	zoomSlider.attr("fill", "#080");
	zoomSlider.attr("stroke", "none");

	var zoomStart = function() 
	{
		zoomSlider.oy = zoomSlider.attr("y");
	};

	var zoomMove = function(dx, dy) 
	{
		var y = Math.floor(zoomSlider.oy + dy);
		
		if (y > zoomBar.attr("y") && y + zoomSlider.attr("height") < zoomBar.attr("y") + zoomBar.attr("height") - 1)
		{
			zoomSlider.attr("y", y);
			
			var ratio = (zoomSlider.attr("y") + 1 - zoomBar.attr("y")) / (zoomBar.attr("height") - zoomSlider.attr("height"))

			zoomSlider.ratio = 1 - ratio;
		}
	};
	
	var zoomUp = function()
	{
		if (zoomSlider.ratio < 0)
			zoomSlider.ratio = 0;
		else if (zoomSlider.ratio > 1)
			zoomSlider.ratio = 1;
			
		var offset = Math.round((CoordinateManager.level_count - CoordinateManager.base_level) * zoomSlider.ratio);

		CoordinateManager.setZoomRatio(zoomSlider.ratio);
	};

	zoomSlider.drag(zoomMove, zoomStart, zoomUp);

	controls.zoomSlider = zoomSlider;	
		
	ControlManager.controls = controls;
	
	ControlManager.resize(width, height);
	MetadataManager.initializeDetails();
};

ControlManager.toFront = function()
{
	if (ControlManager.cropControls !== undefined)
	{
		ControlManager.cropControls.frame.toFront();
		ControlManager.cropControls.frameIcon.toFront();
		
		if (CropTool.editable)
		{
			ControlManager.cropControls.rotation.toFront();
			ControlManager.cropControls.clockIcon.toFront();
			ControlManager.cropControls.counterIcon.toFront();
			ControlManager.cropControls.rotationBar.toFront();
			ControlManager.cropControls.rotationSlider.toFront();
			ControlManager.cropControls.color.toFront();
			ControlManager.cropControls.colorIcon.toFront();
			ControlManager.cropControls.save.toFront();
			ControlManager.cropControls.saveIcon.toFront();
		}
		
		if (ControlManager.cropControls.dimInfo !== undefined)
		{
			ControlManager.cropControls.dimInfo.remove();
			ControlManager.cropControls.dimText.remove();
		}

		if (ControlManager.cropControls.colorInfo !== undefined)
		{
			ControlManager.cropControls.colorInfo.remove();
			ControlManager.cropControls.black.remove();
			ControlManager.cropControls.blue.remove();
			ControlManager.cropControls.brown.remove();
			ControlManager.cropControls.green.remove();
			ControlManager.cropControls.orange.remove();
			ControlManager.cropControls.red.remove();
			ControlManager.cropControls.violet.remove();
			ControlManager.cropControls.yellow.remove();
			ControlManager.cropControls.white.remove();
		}
	}

	if (ControlManager.controls !== undefined)
	{
		ControlManager.controls.mode.toFront(); 
		ControlManager.controls.modeIcon.toFront(); 

		if (ControlManager.controls.create !== undefined)
		{
			ControlManager.controls.create.toFront();	
			ControlManager.controls.createIcon.toFront();	
		}

		ControlManager.controls.rotation.toFront(); 
		ControlManager.controls.clockIcon.toFront();	
		ControlManager.controls.counterIcon.toFront();	
		ControlManager.controls.rotationBar.toFront();	
		ControlManager.controls.rotationSlider.toFront();	
		ControlManager.controls.zoom.toFront(); 
		ControlManager.controls.zoomInIcon.toFront();	
		ControlManager.controls.zoomOutIcon.toFront();	
		ControlManager.controls.zoomBar.toFront();	
		ControlManager.controls.zoomSlider.toFront();	
	}
};

ControlManager.viewportUpdated = function(left, top, level)
{
	ControlManager.updateZoom(level);
};

/**
 * Update the position and display of the contrl panel in light of resize events?
 */
 
ControlManager.resize = function (width, height)
{
	var base = ControlManager.BASE_SIDE;

	if (ControlManager.controls !== undefined)
	{
		ControlManager.controls.mode.attr({x: width - base, y: height - base});
		ControlManager.controls.modeIcon.attr({x: width - base + 5, y: height - base + 5});

		if (ControlManager.controls.create !== undefined)
		{
			ControlManager.controls.create.attr({x: width - base, y: 0});
			ControlManager.controls.createIcon.attr({x: width - base + 6, y: 7});
		}

		ControlManager.controls.rotation.attr({x: width - (base * 8), y: 0});
		ControlManager.controls.clockIcon.attr({x: width - (base * 3) + 7.5, y: 8.5});
		ControlManager.controls.counterIcon.attr({x: width - (base * 8) + 7.5, y: 8.5});
		ControlManager.controls.rotationBar.attr({x: ControlManager.controls.counterIcon.attr("x") + ControlManager.controls.counterIcon.attr("width") + 8, y: 6});

		ControlManager.updateRotation(CoordinateManager.currentRotation());

		ControlManager.controls.zoom.attr({x: width - base, y: base * 2});
		ControlManager.controls.zoomInIcon.attr({x: width - base + 8.5, y: (base * 2) + 8});
		ControlManager.controls.zoomOutIcon.attr({x: width - base + 8.5, y: (base * 8) - 24});
		ControlManager.controls.zoomBar.attr({x: width - base + 6, y: base * 3});

		ControlManager.updateZoom(CoordinateManager.current_level);
	}
};


