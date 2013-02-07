/*global $, PersistenceManager, TileManager, CropTool, ImageServer, ControlManager, 
	CoordinateManager, MetadataManager */

/**
 * @fileoverview This file contains the code that manages the display and positioning of crops on 
 *	   the drawable surface.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */

var CropManager = {};

CropManager.editable = false;
CropManager.drawable = false;
CropManager.draw_canvas = null;

CropManager.crops = [];
CropManager.selectedCrop = null;

/**
 * Highlights the selected crop & displays the resize controls when rotation = 0.
 */
 
CropManager.selectCrop = function(crop)
{
	if (CropManager.selectedCrop === crop)
	{
		return;
	}
	
	if (crop !== null)
	{
		if (CropManager.selectedCrop !== null)
		{
			CropManager.selectedCrop.rect.attr("fill-opacity", "0.1");
			CropManager.selectedCrop.setResizable(false);
		}

		CropManager.selectedCrop = crop;
		
		if (crop.rect !== null)
		{
			crop.rect.attr("fill-opacity", "0.5");
		}
	
		if (CropTool.editable && (CropManager.selectedCrop.rotation + CoordinateManager.glass.rotation) === 0)
		{
			CropManager.selectedCrop.setResizable(true);
		}

		MetadataManager.showCropDetails(CropManager.selectedCrop);
	}
	else
	{
		CropManager.selectedCrop.rect.attr("fill-opacity", "0.1");
		CropManager.selectedCrop.setResizable(false);

		CropManager.selectedCrop = null;

		MetadataManager.hideCropDetails();
	}
};

CropManager.createNewCrop = function()
{
	var crop = {};
	crop.uuid = uuid();
			
	crop.flagDirty = function()
	{
		this.dirty = true;
				
		if (MetadataManager !== undefined)
		{
			MetadataManager.showDirtyCrop(this);
		}
	};
	
	crop.setViewPort = function()
	{
		var win_width = $(CropTool.rootDiv).width() - 20;
		var win_height = $(CropTool.rootDiv).height() - 20;

		var side = win_width;
		if (win_height < win_width)
		{
			side = win_height;
		}
		
		var x = this.cx * CoordinateManager.glass.o_width;
		var y = this.cy * CoordinateManager.glass.o_height;
			
		var level = CoordinateManager.base_level;
		var zce = CoordinateManager.zoomCoefficientForLevel(level);

		while (((this.width * ImageServer.details.width) / zce) < side && 
			   ((this.height * ImageServer.details.height) / zce) < side)
		{
			level += 1;
			zce = CoordinateManager.zoomCoefficientForLevel(level);
		}

		//level = level - 1;
		zce = CoordinateManager.zoomCoefficientForLevel(level);
				
		x = (this.cx * ImageServer.details.width) / zce;
		y = (this.cy * ImageServer.details.height) / zce;

		CoordinateManager.setRotation(0);
		CoordinateManager.setViewport(x, y, level);
		CoordinateManager.setRotation(0 - this.rotation);
				
		CropManager.setEditable(true);

		if (CropTool.editable)
		{
		   this.setResizable(true);
		}
	};
	
	crop.metadata = {};
	
	return crop;
};


/**
 * Updates the display and position of the crops when the viewport changes.
 */
 
CropManager.updatePosition = function()
{
	// Glass is the invisible layer on top of everything that responds to click & drag events.
	
	var glass = CoordinateManager.glass;
	
	if (glass === undefined)
	{
		return;
	}
	
	var cx = glass.attr("x") + (glass.o_width / 2);
	var cy = glass.attr("y") + (glass.o_height / 2);

	var glass_origin_x = cx - (glass.o_width / 2);
	var glass_origin_y = cy - (glass.o_height / 2);

	CoordinateManager.glass.toFront();

	var i = 0;
	
	for (i = 0; i < CropManager.crops.length; i++)
	{
		var crop = CropManager.crops[i];
		
		// Remove the displayed rectangle.
		
		if (crop.rect !== undefined)
		{
			if (crop.drag_rect !== null)
			{
				crop.drag_rect.remove();
			}

			crop.rect.remove();
		}

		if (crop.drag_rect === undefined)
		{
			crop.drag_rect = null;
		}
		
		if (crop.setResizable === undefined)
		{
			// Setup the function that displays the resize controls & responds to resize events...
			
			crop.setResizable = function(is_resizable)
			{
				if (is_resizable === false && this.drag_rect !== null)
				{
					this.drag_rect.crop = null;
					this.drag_rect.remove();
					this.drag_rect = null;
				}
				else if (is_resizable && this.drag_rect === null)
				{
					this.drag_rect = CropTool.paper.rect(this.rect.attr("x") + this.rect.attr("width") - 4, this.rect.attr("y") + this.rect.attr("height") - 4, 8, 8);

					this.drag_rect.attr("stroke", "#000");
					this.drag_rect.attr("fill", "#fff");		
					this.drag_rect.attr("opacity", "1.0");
					this.drag_rect.crop = this;
					
					var s = function () 
					{
						this.o_x = this.attr("x");
						this.o_y = this.attr("y");

						this.rect_o_x = this.crop.rect.attr("x");
						this.rect_o_y = this.crop.rect.attr("y");
						this.rect_o_width = this.crop.rect.attr("width");
						this.rect_o_height = this.crop.rect.attr("height");
					};
	
					var m = function (dx, dy) 
					{
						this.attr("x", this.o_x + dx);
						this.attr("y", this.o_y + dy);
						
						var rect_x = this.rect_o_x;
						var rect_y = this.rect_o_y;

						var rect_width = this.attr("x") + (this.attr("width") / 2) - rect_x;
						var rect_height = this.attr("y") + (this.attr("height") / 2)  - rect_y;

						if (rect_width < 0)
						{
							rect_x = rect_x + rect_width;
						}
						
						if (rect_height < 0)
						{
							rect_y = rect_y + rect_height;
						}
						
						this.crop.rect.attr("x",  rect_x);
						this.crop.rect.attr("y",  rect_y);
						this.crop.rect.attr("width",  Math.abs(rect_width));
						this.crop.rect.attr("height", Math.abs(rect_height));
					};
		
					var u = function () 
					{
						var dx = this.crop.rect.attr("x") + (this.crop.rect.attr("width") / 2) - this.rect_o_x - (this.rect_o_width / 2);
						var dy = this.crop.rect.attr("y") + (this.crop.rect.attr("height") / 2) - this.rect_o_y - (this.rect_o_height / 2);
				
						var d = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));
				
						var angle = Math.atan2(dy, dx) - (CoordinateManager.glass.rotation * (Math.PI / 180));
				
						this.crop.cx += ((d * Math.cos(angle)) / CoordinateManager.glass.o_width);
						this.crop.cy += ((d * Math.sin(angle)) / CoordinateManager.glass.o_height);
			
						this.crop.flagDirty();

						this.crop.width = this.crop.rect.attr("width") / CoordinateManager.glass.o_width;
						this.crop.height = this.crop.rect.attr("height") /	CoordinateManager.glass.o_height;
					};
				
					this.drag_rect.drag(m, s, u);
					this.drag_rect.toFront();
				}
			};
		}

		var x = glass_origin_x + (glass.o_width * crop.cx);
		var y = glass_origin_y + (glass.o_height * crop.cy);

		var width = glass.o_width * crop.width;
		var height = glass.o_height * crop.height;

		var angle = Math.atan2(y - cy, x - cx);
		var d = Math.sqrt(Math.pow(x - cx, 2) + Math.pow(y - cy, 2));

		var real_x = d * Math.cos((glass.rotation * Math.PI / 180) + angle);
		var real_y = d * Math.sin((glass.rotation * Math.PI / 180) + angle);

		// Draw the colored rectangle that visually represents the crop...
		crop.rect = CropTool.paper.rect(cx + real_x - (width / 2), cy + real_y - (height / 2), width, height);
		crop.rect.crop = crop;
		
		$(crop.rect.node).bind('mousewheel', CoordinateManager.mouseZoom);

		crop.rect.rotate(glass.rotation + crop.rotation);
		crop.rect.attr("stroke", crop.color);
		crop.rect.attr("fill", "none");		

		// Setup the various mouse actions (click to select, double-click to edit, drag to move, 
		// etc...
		
		crop.rect.click(function(event)
		{
			CropManager.selectCrop(this.crop);
		});

		crop.rect.mouseover(function (event)
		{
			$("body").css("cursor", "pointer");
		});

		crop.rect.mouseout(function (event)
		{
			$("body").css("cursor", "default");
		});
			
		crop.rect.dblclick(function(event)
		{
			var dx = this.attr("x") - this.o_x;
			var dy = this.attr("y") - this.o_y;

			if (Math.abs(dx) + Math.abs(dy) < 20)
			{
				crop.setViewPort();
			}
		});
		
		var start = function() 
		{
			CropManager.selectCrop(this.crop);
			
			this.o_x = Math.floor(this.attr("x"));
			this.o_y = Math.floor(this.attr("y"));
		};
	
		var move = function(dx, dy) 
		{
			if (CropTool.editable)
			{
				this.attr("x", this.o_x + Math.floor(dx));
				this.attr("y", this.o_y + Math.floor(dy));

				if (this.crop.drag_rect !== null)
				{
					this.crop.drag_rect.attr("x", this.attr("x") + this.attr("width") - (this.crop.drag_rect.attr("width") / 2));
					this.crop.drag_rect.attr("y", this.attr("y") + this.attr("height") - (this.crop.drag_rect.attr("height") / 2));
				}
			}
		};
		
		var up = function() 
		{
			if (CropTool.editable)
			{
				var dx = this.attr("x") - this.o_x;
				var dy = this.attr("y") - this.o_y;
				
				var d = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));
				
				var angle = Math.atan2(dy, dx) - (CoordinateManager.glass.rotation * (Math.PI / 180));
				
				this.crop.cx += ((d * Math.cos(angle)) / CoordinateManager.glass.o_width);
				this.crop.cy += ((d * Math.sin(angle)) / CoordinateManager.glass.o_height);

				this.crop.flagDirty();
			}
		};
		
		crop.rect.drag(move, start, up);
		
		crop.rect.toFront();
		
		if (crop.drag_rect !== null)
		{
			crop.drag_rect.toFront();
		}
	}

	// Update the mode...
	
	CropManager.setEditable(CropManager.editable);
	
	// Bring the glass to the front if crops are not editable (at the moment)...
	
	if (!CropManager.editable)
	{
		CoordinateManager.glass.toFront();
		ControlManager.toFront();
	}
	
	if (CropManager.draw_canvas !== null)
	{
		var dcx = glass.attr("x") + (glass.attr("width") / 2);
		var dcy = glass.attr("y") + (glass.attr("height") / 2);

		CropManager.draw_canvas.rotate(0, true);
		
		CropManager.draw_canvas.attr("x", dcx - (glass.o_width / 2));
		CropManager.draw_canvas.attr("y", dcy - (glass.o_height / 2));
	
		CropManager.draw_canvas.rotate(glass.rotation, true);
		CropManager.draw_canvas.toFront();
	}
	
	ControlManager.toFront();
};

/**
 * Bring the drawable elements to the front of the view stack.
 */
 
CropManager.toFront = function()
{
	var i = 0;
	
	for (i = 0; i < CropManager.crops.length; i++)
	{
		var crop = CropManager.crops[i];
		
		if (crop.rect !== undefined)
		{
			crop.rect.toFront();
		}
		
		if (crop.drag_rect !== undefined && crop.drag_rect !== null)
		{
			crop.drag_rect.toFront();
		}
	}
};

/**
 * Bring the selected crop to the front for editing...
 */
 
CropManager.bringToFront = function(crop_id)
{
	var i = 0;
	
	for (i = 0; i < CropManager.crops.length; i++)
	{
		var crop = CropManager.crops[i];
		
		if (crop.uuid === crop_id)
		{
			if (crop.rect !== undefined)
			{
				crop.rect.toFront();
			}
		
			if (crop.drag_rect !== undefined && crop.drag_rect !== null)
			{
				crop.drag_rect.toFront();
			}
			
			CropManager.crops.splice(i, 1);
			CropManager.crops.push(crop);
		}
	}
};

/**
 * Setup the crop for editing.
 */
 
CropManager.setEditable = function(is_editable)
{
	CropManager.editable = is_editable;
		
	var i = 0;
	
	for (i = 0; i < CropManager.crops.length; i++)
	{
		var crop = CropManager.crops[i];
		
		if (crop.rect !== undefined)
		{
			if (crop.setResizable !== undefined)
			{
				crop.setResizable(false);
			}
			
			if (is_editable)
			{
				crop.rect.attr("fill", crop.color);		
				crop.rect.attr("fill-opacity", "0.10");
	
				if (crop === CropManager.selectedCrop)
				{
					crop.rect.attr("fill-opacity", "0.5");

					if (CropTool.editable && crop.rotation + CoordinateManager.glass.rotation === 0)
					{
						CropManager.selectedCrop.setResizable(true);
					}

					if (crop.drag_rect !== null)
					{
						CropManager.selectedCrop.drag_rect.attr("x", CropManager.selectedCrop.rect.attr("x") + CropManager.selectedCrop.rect.attr("width") - (CropManager.selectedCrop.drag_rect.attr("width") / 2));
						CropManager.selectedCrop.drag_rect.attr("y", CropManager.selectedCrop.rect.attr("y") + CropManager.selectedCrop.rect.attr("height") - (CropManager.selectedCrop.drag_rect.attr("height") / 2));
					}
				}

				crop.rect.toFront();

				if (crop.drag_rect !== null)
				{
					crop.drag_rect.toFront();
				}
			}
			else
			{
				crop.rect.attr("fill", "none");		
			}
		}
	}
};

/**
 * Removes the selected crop from the display.
 */

CropManager.removeSelectedCrop = function()
{
	if (CropManager.selectedCrop !== null)
	{
		if (confirm("Clear selected region from image?"))
		{
			if (CropManager.selectedCrop.drag_rect !== null)
			{
				CropManager.selectedCrop.drag_rect.remove();
			}

			if (CropManager.selectedCrop.rect !== null)
			{
				CropManager.selectedCrop.rect.remove();
			}
			
			var index = -1;
		
			var i = 0;
			
			for (i = 0; i < CropManager.crops.length; i++)
			{
				if (CropManager.selectedCrop === CropManager.crops[i])
				{
					index = i;
				}
			}	
		
			if (index >= 0)
			{
				CropManager.crops.splice(index, 1);
			}
			
			CropManager.selectCrop(null);
			
			CropManager.updatePosition();
		}
	}
};

/**
 * Set the display layer to a "drawable" mode.
 */
 
CropManager.setDrawable = function(is_drawable)
{
	CropManager.drawable = is_drawable;
	
	if (CropManager.drawable)
	{
		var glass = CoordinateManager.glass;
		
		var cx = glass.attr("x") + (glass.attr("width") / 2);
		var cy = glass.attr("y") + (glass.attr("height") / 2);
		
		CropManager.draw_canvas = CropTool.paper.rect(cx - (glass.o_width / 2), cy - (glass.o_height / 2), glass.o_width, glass.o_height);
		CropManager.draw_canvas.attr("stroke", "#fff");
		CropManager.draw_canvas.attr("fill", "#fff");		
		CropManager.draw_canvas.attr("fill-opacity", "0.0");		

		CropManager.draw_canvas.rotate(glass.rotation);

		CropManager.draw_canvas.draw_rect = null;		

		// Draw crop methods...
		
		CropManager.draw_canvas.mousedown(function(event) 
		{
			CropManager.draw_canvas.start_x = event.clientX - 10;
			CropManager.draw_canvas.start_y = event.clientY - 10;
			
			CropManager.draw_canvas.draw_rect = CropTool.paper.rect(CropManager.draw_canvas.start_x, CropManager.draw_canvas.start_y, 1, 1);
			CropManager.draw_canvas.draw_rect.attr("stroke", crop.color);
		});

		var start = function () 
		{

		};
	
		var move = function (dx, dy) 
		{
			if (CropManager.draw_canvas.draw_rect !== null)
			{
				CropManager.draw_canvas.draw_rect.attr("width", Math.abs(dx));
				CropManager.draw_canvas.draw_rect.attr("height", Math.abs(dy));
				
				if (dx < 0)
				{
					CropManager.draw_canvas.draw_rect.attr("x", CropManager.draw_canvas.start_x + dx);
				}
				else					
				{
					CropManager.draw_canvas.draw_rect.attr("x", CropManager.draw_canvas.start_x);
				}

				if (dy < 0)
				{
					CropManager.draw_canvas.draw_rect.attr("y", CropManager.draw_canvas.start_y + dy);
				}
				else					
				{
					CropManager.draw_canvas.draw_rect.attr("y", CropManager.draw_canvas.start_y);
				}
			}
		};
		
		var up = function () 
		{
			if (CropManager.draw_canvas.draw_rect !== null)
			{
				var crop = {};
				crop.color = "#ff0000";

				crop.metadata = {};
				
				var fields = PersistenceManager.getFields();
				
				var i = 0;
				
				for (i = 0; i < fields.length; i++)
				{
					var field = fields[i];
					
					crop.metadata[field.field] = field.value;
				}
			
				var canvas_width = CropManager.draw_canvas.attr("width");
				var canvas_height = CropManager.draw_canvas.attr("height");

				var canvas_cx = CropManager.draw_canvas.attr("x") + (canvas_width / 2);
				var canvas_cy = CropManager.draw_canvas.attr("y") + (canvas_height / 2);
				
				var width = CropManager.draw_canvas.draw_rect.attr("width");
				var height = CropManager.draw_canvas.draw_rect.attr("height");
				
				var rect_cx = CropManager.draw_canvas.draw_rect.attr("x") + (width / 2);
				var rect_cy = CropManager.draw_canvas.draw_rect.attr("y") + (height / 2);
				
				var delta_x = rect_cx - canvas_cx;
				var delta_y = rect_cy - canvas_cy;
				
				var d = Math.sqrt(Math.pow(delta_x, 2) + Math.pow(delta_y, 2));
				var angle = Math.atan2(delta_y, delta_x) - (CoordinateManager.glass.rotation * (Math.PI / 180));

				var cx = (((d * Math.cos(angle)) + canvas_cx) - CropManager.draw_canvas.attr("x")) / canvas_width;
				var cy = (((d * Math.sin(angle)) + canvas_cy) - CropManager.draw_canvas.attr("y")) / canvas_height;
				
				crop.cx = cx;
				crop.cy = cy;
				crop.uuid = uuid();
				
				crop.width = width / canvas_width;
				crop.height = height / canvas_height;

				crop.rotation = 0 - CoordinateManager.glass.rotation;

				CropManager.crops.push(crop);
				
				MetadataManager.refresh();
			
				CropManager.draw_canvas.draw_rect.remove();
				
				CropManager.draw_canvas.draw_rect = null;
				
				CropManager.editable = true;

				CropManager.updatePosition();				
				
				ControlManager.setMode("edit");

				CropManager.selectCrop(crop);
			}
			
			CropManager.setDrawable(false);
			
			CropManager.updatePosition();
		};

		CropManager.draw_canvas.drag(move, start, up);

		CropManager.draw_canvas.toFront();
	}
	else
	{
		if (CropManager.draw_canvas !== null)
		{
			CropManager.draw_canvas.remove();
		
			CropManager.draw_canvas = null;
		}
	}

	ControlManager.toFront();
};

