/*global $, window, TileManager, CropManager */

/**
 * @fileoverview This file contains the code that manages the viewport of the image.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */

var CoordinateManager = {};

CoordinateManager.currentRotation = function()
{
	return CoordinateManager.glass.rotation;
};

/**
 * Sets up the data structures for tracking the viewport.
 */
 
CoordinateManager.initialize = function(frame_width, frame_height, levels)
{
    var viewport_width = $(CropTool.rootDiv).width() - 20;
    var viewport_height = $(CropTool.rootDiv).height() - 20;

    this.frame_width = frame_width;
    this.frame_height = frame_height;
    this.viewport_width = viewport_width;
    this.viewport_height = viewport_height;
    
    var image_width = frame_width;
    var image_height = frame_height;
    
    this.level_count = levels; // level = level_count => full zoom

    var viewport_max = viewport_width;
    var image_max = frame_width;
        
    if (viewport_height / viewport_width < frame_height / frame_width)
    {
        viewport_max = viewport_height;
        image_max = frame_height;
    }

    for (this.base_level = this.level_count; image_max > viewport_max && this.base_level > 0; this.base_level = this.base_level - 1)
    {
        image_max = image_max / 2;
        
        image_width = image_width / 2;
        image_height = image_height / 2;
    }

    $(window).resize(function()
    {
        CoordinateManager.viewport_width = $(CropTool.rootDiv).width() - 20;
        CoordinateManager.viewport_height = $(CropTool.rootDiv).height() - 20;
    });

    this.current_level = this.base_level;

    var width = ImageServer.details.width / CoordinateManager.zoomCoefficient();
    var height = ImageServer.details.height / CoordinateManager.zoomCoefficient();

    this.setViewport((width / 2), (height / 2), this.current_level);
};

CoordinateManager.currentActualViewport = function()
{
	var vp = {};
	
	var zoom = this.zoomCoefficient();
	
	vp.x = (0 - CoordinateManager.glass.attr("x")) * zoom;
	vp.y = (0 - CoordinateManager.glass.attr("y")) * zoom;
	
    vp.width = $(CropTool.rootDiv).width() * zoom;
    vp.height = $(CropTool.rootDiv).height() * zoom;

	alert("Start crop with dimensions (" + vp.x + ", " + vp.y + " -- " + vp.width + "x" + vp.height + ")");

	return vp;
}
/**
 * Update the rotation of the viewport.
 */
 
CoordinateManager.setRotation = function(degrees)
{
    var viewport_width = $(CropTool.rootDiv).width() - 20;
    var viewport_height = $(CropTool.rootDiv).height() - 20;

    var vpcx = viewport_width / 2;
    var vpcy = viewport_height / 2;

    var delta = degrees - CoordinateManager.glass.rotation;
    CoordinateManager.glass.rotate(0 - CoordinateManager.glass.rotation);

    var cx = CoordinateManager.glass.attr("x") + (CoordinateManager.glass.attr("width") / 2);
    var cy = CoordinateManager.glass.attr("y") + (CoordinateManager.glass.attr("height") / 2);
                    
    var dx = cx - vpcx;
    var dy = cy - vpcy;

    var d = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));
                    
    var current_angle = Math.atan2(dy, dx);
    var angle = (delta * Math.PI) / 180;
    
    var nx = vpcx + (Math.cos(angle + current_angle) * d) - (CoordinateManager.glass.attr("width") / 2);
    var ny = vpcy + (Math.sin(angle + current_angle) * d) - (CoordinateManager.glass.attr("height") / 2);

    CoordinateManager.glass.attr("x", nx);
    CoordinateManager.glass.attr("y", ny);
                    
    CoordinateManager.glass.rotate(degrees);
    
    CoordinateManager.glass.rotation = degrees;

    if (CropManager.selectedCrop !== null)
        CropManager.selectedCrop.setResizable(false);

    TileManager.updatePosition();
    CropManager.updatePosition();
    ControlManager.updateRotation(degrees);
    ControlManager.toFront();
};

/**
 * Fetch the current zoom level/coefficient.
 */
 
CoordinateManager.zoomCoefficient = function()
{
    return Math.pow(2, this.level_count - this.current_level);
};

/**
 * Get the coefficient for a given zoom level.
 */
 
CoordinateManager.zoomCoefficientForLevel = function(level)
{
    return Math.pow(2, this.level_count - level);
};

/**
 * Set the zoom level based on the mouse event. Regular click = zoom in, right-click = zoom out.
 */
 
CoordinateManager.mouseZoom = function(event, delta)
{
    var now = new Date();
    
    if (CoordinateManager.lastMouseZoom !== undefined && now.getTime() - CoordinateManager.lastMouseZoom.getTime() < 500)
        return;
                
    CoordinateManager.lastMouseZoom = now;
            
    var shift_click = false;

    if (delta < 0)
        shift_click = true;

    var width = $(CropTool.rootDiv).width() - 20;
    var height = $(CropTool.rootDiv).height() - 20;
    
    var click_x = (width / 2) - 10 - CoordinateManager.glass.attr("x");
    var click_y = (height / 2) - 10 - CoordinateManager.glass.attr("y");

    var new_level = CoordinateManager.current_level + 1;
            
    if (shift_click)
    {
        new_level = CoordinateManager.current_level - 1;
    }
            
    if (new_level > CoordinateManager.level_count || new_level < CoordinateManager.base_level)
    {
        new_level = CoordinateManager.current_level;
    }
    else if (shift_click)
    {
        click_x = click_x / 2;
        click_y = click_y / 2;
    }
    else
    {
        click_x = click_x * 2;
        click_y = click_y * 2;
    }

    CoordinateManager.setViewport(click_x, click_y, new_level);
};

/**
 * Sets the drawable area's viewport. Works with other elements (ControlManager, TileManager, etc.) 
 *     to reflect the proper viewport.
 */
 
CoordinateManager.setViewport = function(cx, cy, level)
{
    var ratio_level = (level - CoordinateManager.base_level) / (CoordinateManager.level_count - 
                       CoordinateManager.base_level);

    if (CoordinateManager.glass === undefined)
    {
        CoordinateManager.glass = CropTool.paper.rect(10, 10,  10, 10);
        CoordinateManager.glass.rotation = 0;
        CoordinateManager.glass.loadedTiles = {};
            
        var start = function () 
        {
            this.ox = this.attr("x");
            this.oy = this.attr("y");

            TileManager.updatePosition();
            CropManager.updatePosition();       
            ControlManager.toFront();
        };
    
        var move = function (dx, dy) 
        {   
            this.rotate(0 - this.rotation);
        
            this.attr({x: this.ox + dx, y: this.oy + dy});
    
            this.rotate(this.rotation);

            TileManager.updatePosition();       
            CropManager.updatePosition();       
            ControlManager.toFront();
        };
        
        var up = function () 
        {
            CoordinateManager.setViewport((CoordinateManager.viewport_width / 2) - 
                                          CoordinateManager.glass.attr("x"), 
                                          (CoordinateManager.viewport_height / 2) - 
                                          CoordinateManager.glass.attr("y"),
                                          CoordinateManager.current_level);
            ControlManager.toFront();
        };

        CoordinateManager.glass.dblclick(function(evt)
        {
            var shift_click = evt.shiftKey;
            
            var pos = $(CropTool.rootDiv).offset();

            var click_x = evt.clientX - 10 - CoordinateManager.glass.attr("x") - pos.left;
            var click_y = evt.clientY - 10 - CoordinateManager.glass.attr("y") - pos.top;

            var new_level = CoordinateManager.current_level + 1;
            
            if (shift_click)
            {
                new_level = CoordinateManager.current_level - 1;
            }
            
            if (new_level > CoordinateManager.level_count || new_level < 
                CoordinateManager.base_level)
            {
                new_level = CoordinateManager.current_level;
            }
            else if (shift_click)
            {
                click_x = click_x / 2;
                click_y = click_y / 2;
            }
            else
            {
                click_x = click_x * 2;
                click_y = click_y * 2;
            }

            CoordinateManager.setViewport(click_x, click_y, new_level);
        });
        
        $(CoordinateManager.glass.node).bind('mousewheel', CoordinateManager.mouseZoom);

        CoordinateManager.glass.drag(move, start, up);

        CoordinateManager.glass.attr("fill", "#f00");
        CoordinateManager.glass.attr("opacity", "0.0");
//        CoordinateManager.glass.attr("opacity", "0.5");
    }

    CoordinateManager.glass.rotate(0 - CoordinateManager.glass.rotation);
    
    if (level !== CoordinateManager.current_level)
    {
        CoordinateManager.glass.loadedTiles = {};

        TileManager.reset();
    }
    
    CoordinateManager.current_level = level;
    
    var width = ImageServer.details.width / CoordinateManager.zoomCoefficientForLevel(level);
    var height = ImageServer.details.height / CoordinateManager.zoomCoefficientForLevel(level);

    var x = (CoordinateManager.viewport_width / 2) - cx;
    var y = (CoordinateManager.viewport_height / 2) - cy;

//	alert(ImageServer.details.width + " xx  " + ImageServer.details.height);

    CoordinateManager.glass.o_width = width;
    CoordinateManager.glass.o_height = height;

	width = Math.ceil(width / ImageServer.tile_size) * ImageServer.tile_size;
	height = Math.ceil(height / ImageServer.tile_size) * ImageServer.tile_size;

    CoordinateManager.glass.attr("x", x);
    CoordinateManager.glass.attr("y", y);
    CoordinateManager.glass.attr("width", width);
    CoordinateManager.glass.attr("height", height);

    CoordinateManager.glass.toFront();

    var dx = cx - (CoordinateManager.glass.attr("width") / 2); 
    var dy = cy - (CoordinateManager.glass.attr("height") / 2); 

    var d = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));

    var angle = Math.atan2(dy, dx);
    
    dx = d * Math.cos(angle - (CoordinateManager.glass.rotation * (Math.PI / 180)));
    dy = d * Math.sin(angle - (CoordinateManager.glass.rotation * (Math.PI / 180)));

    cx = (CoordinateManager.glass.attr("width") / 2) + dx;
    cy = (CoordinateManager.glass.attr("height") / 2) + dy;

    CoordinateManager.glass.rotate(CoordinateManager.glass.rotation);

    var side = Math.sqrt(Math.pow(CoordinateManager.viewport_width / 2, 2), 
                         Math.pow(CoordinateManager.viewport_height / 2, 2));

    var left = cx - side;
    var top = cy - side;
    
    var x_offset = Math.floor(left / ImageServer.tile_size);
    var y_offset = Math.floor(top / ImageServer.tile_size);
    
//    TileManager.clearTileQueue();

    for (var i = -1; (i * ImageServer.tile_size) < (2 * side) + ImageServer.tile_size; i++)
    {
        for (var j = -1; (j * ImageServer.tile_size) < (2 * side) + ImageServer.tile_size; j++)
        {
            var i_index = x_offset + i;
            var j_index = y_offset + j;
            
            TileManager.loadTile(i_index, j_index, level);
        }
    }

    TileManager.updatePosition();       
    CropManager.updatePosition();
    ControlManager.viewportUpdated(cx, cy, level);
};

CoordinateManager.setZoomRatio = function(ratio)
{
    var levels = CoordinateManager.level_count - CoordinateManager.base_level;
    
    var offset = Math.round(levels * ratio);

    var width = $(CropTool.rootDiv).width() - 20;
    var height = $(CropTool.rootDiv).height() - 20;
    
    var x = (width / 2) - 10 - CoordinateManager.glass.attr("x");
    var y = (height / 2) - 10 - CoordinateManager.glass.attr("y");

    var dest_level = CoordinateManager.base_level + offset;
    
    if (CoordinateManager.base_level + offset > CoordinateManager.current_level)
    {
        while (CoordinateManager.base_level + offset > CoordinateManager.current_level)
        {
            x = x * 2;
            y = y * 2;
        
            offset -= 1;
        }
    }
    else if (CoordinateManager.base_level + offset < CoordinateManager.current_level)
    {
        while (CoordinateManager.base_level + offset < CoordinateManager.current_level)
        {
            x = x / 2;
            y = y / 2;

            offset += 1;
        }
    }

    CoordinateManager.setViewport(x, y, dest_level);
};

/**
 * Zooms in the viewport.
 */
 
CoordinateManager.zoomIn = function ()
{
    if (CoordinateManager.current_level >= CoordinateManager.level_count)
    {
        alert("Cannot zoom in further.");
        return;
    }
    
    var width = $(CropTool.rootDiv).width() - 20;
    var height = $(CropTool.rootDiv).height() - 20;

    var x = (width / 2) - 10 - CoordinateManager.glass.attr("x");
    var y = (height / 2) - 10 - CoordinateManager.glass.attr("y");

    CoordinateManager.setViewport((x * 2), (y * 2), CoordinateManager.current_level + 1);
};

/**
 * Zoom out the viewport.
 */

CoordinateManager.zoomOut = function ()
{
    if (CoordinateManager.current_level <= CoordinateManager.base_level)
    {
        alert("Cannot zoom out further.");
        return;
    }
        
    var width = $(CropTool.rootDiv).width() - 20;
    var height = $(CropTool.rootDiv).height() - 20;

    var x = (width / 2) - 10 - CoordinateManager.glass.attr("x");
    var y = (height / 2) - 10 - CoordinateManager.glass.attr("y");

    CoordinateManager.setViewport((x / 2), (y / 2), CoordinateManager.current_level - 1);
};
