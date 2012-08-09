/*global $, CoordinateManager, ImageServer, CropTool, CropManager, ControlManager, setTimeout */

/**
 * @fileoverview This file contains the code that manages the display of the tiled images in the 
 *     main view. Works with the image server to obtain tiles.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */

var TileManager = {};

TileManager.cacheImages = [];

TileManager.tiles = [];
TileManager.remaining = 0;

/**
 * Refreshes the position of the individual tiles.
 */
 
TileManager.updatePosition = function()
{
    for (var i = 0; i < TileManager.tiles.length; i++)
    {
        TileManager.tiles[i].updatePosition();
    }
    
    ControlManager.toFront();
};

/**
 * Removes the tiles and resets the display.
 */
 
TileManager.reset = function()
{
    while (TileManager.tiles.length > 0)
    {
        TileManager.tiles.shift().remove();
    }
};

/**
 * Loads a tile for a given position in the grid.
 */
 
TileManager.loadTile = function(i, j, level)
{
    if (i < 0 || j < 0)
        return;
        
    var glass = CoordinateManager.glass;

    var tile_url = ImageServer.tileAt(i, j, level, ImageServer.tile_size);
    
    if (tile_url !== null && glass.loadedTiles[i + "." + j] === undefined)
    {
        glass.loadedTiles[i + "." + j] = true;

        TileManager.remaining += 1;
        
        // After the tile image is fetched, position the tile approriately...

        var callback = function(img_element, context)
        {
            TileManager.remaining -= 1;
    
            if (img_element === null)
            {

            }
            else if (context.level !== CoordinateManager.current_level)
            {

            }
            else
            {
                var cx = context.glass.attr("x") + (context.glass.o_width / 2);
                var cy = context.glass.attr("y") + (context.glass.o_height / 2);
                
                var glass_origin_x = cx - (context.glass.o_width / 2);
                var glass_origin_y = cy - (context.glass.o_height / 2);
                
                var img_width = $(img_element).width(); // .attr("width");
                var img_height = $(img_element).height(); // .attr("height");

                var x = glass_origin_x + (context.i * ImageServer.tile_size);
                var y = glass_origin_y + (context.j * ImageServer.tile_size);
                
                var image = CropTool.paper.image($(img_element).attr("src"), x, y, img_width, 
                								 img_height);
                TileManager.tiles.push(image);

                image.glass = context.glass;
                image.i = context.i;
                image.j = context.j;

                image.updatePosition = function ()
                {
                    var cx = this.glass.attr("x") + (context.glass.o_width / 2);
                    var cy = this.glass.attr("y") + (context.glass.o_height / 2);
                
                    var glass_origin_x = cx - (this.glass.o_width / 2);
                    var glass_origin_y = cy - (this.glass.o_height / 2);

                    var x = glass_origin_x + (this.i * ImageServer.tile_size);
                    var y = glass_origin_y + (this.j * ImageServer.tile_size);
                    
                    this.attr("x", x);
                    this.attr("y", y);

                    this.rotate(this.glass.rotation, cx, cy);

                    image.toFront();
                    context.glass.toFront();
                };

                image.toFront();

                context.glass.toFront();

                CropManager.toFront();
                ControlManager.toFront();
                
                image.rotate(context.glass.rotation, cx, cy);

                $(img_element).remove();
            }   

			// After all tiles are loaded, revert to "move" mode...
			
            if (TileManager.remaining === 0)
            {
                $("body").css("cursor", "move");

/*                if (TileManager.cacheImages.length > 0)
                {
                    while (TileManager.cacheImages.length > 128)
                    {
                        TileManager.cacheImages.shift();
                    }

                    var f = function ()
                    {
                        if (TileManager.cacheImages.length > 0)
                        {
                            var subtile_url = TileManager.cacheImages.pop(); // .shift();
    
                            var cache_callback = function(img_element, context)
                            {
                                $(img_element).remove();

                                setTimeout(f, 100);
                            };
                        
                            ImageServer.queueImage(subtile_url, cache_callback, null);
                        }
                    };

                    setTimeout(f, 100);
                } */
                TileManager.updatePosition();
            }
            
            // Prefetch the four tiles underneath this one for performance reasons...
        
/*            for (var i_offset = 0; i_offset < 2; i_offset++)
            {
                for (var j_offset = 0; j_offset < 2; j_offset++)
                {
                    var subtile_url = ImageServer.tileAt((context.i * 2) + i_offset, (context.j * 2)
                    								     + j_offset, context.level + 1, 
                    								     ImageServer.tile_size);
                
                    if (subtile_url !== null)
                    {
                        TileManager.cacheImages.push(subtile_url);
                    }
                }
            }
  */      };

        var context = {};
        context.i = i; 
        context.j = j;
        context.level = level;
        context.glass = glass;

        ImageServer.queueImage(tile_url, callback, context);
    }
};
