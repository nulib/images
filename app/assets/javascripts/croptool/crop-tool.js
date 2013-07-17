/*global $, document, window, Raphael, ImageServer, ControlManager */

/**
 * @fileoverview This file contains the code that initializes Crop Tool and sets up the drawing area
 *     within the current browser window. It includes the functionality that resizes the drawing 
 *     area on browser window resizes.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */
 
var CropTool = {};

CropTool.paper = null;
CropTool.editable = false;
CropTool.isCrop = false;

CropTool.initialize = function(identifier, editable, rootDiv, isCrop)
{
	CropTool.editable = editable;
	CropTool.rootDiv = rootDiv.get(0);
	CropTool.isCrop = isCrop;
	
	// Establish a drawing area with a 10px border from the edges of the browser frame.
	
    var width = $(CropTool.rootDiv).width();
    var height = $(CropTool.rootDiv).height();

	// CropTool.paper is the main area in which all drawing and image placement will happen. This 
	//     is the base "canvas".
	
	var pos = $(CropTool.rootDiv).offset();

    CropTool.paper = Raphael(CropTool.rootDiv, width, height);
    
    // TODO: Remove this...

    CropTool.resize = function ()
    {
        var width = $(CropTool.rootDiv).width();
        var height = $(CropTool.rootDiv).height();

		var pos = $(CropTool.rootDiv).offset();
    
        CropTool.paper.setSize(width, height);

//		$("svg").css("left", (pos.left + 1) + "px");
//		$("svg").css("top", (pos.top + 1) + "px");

//	    $("svg").css("position", "relative");

		ControlManager.resize(width, height);	
		ControlManager.toFront();
    };
    
    $(window).resize(CropTool.resize);

//    $("body").css("overflow", "hidden");

	// Round the corners of the metadata panels. These are setup within another file:
	//     metadata-manager.js

    $("div#metadata").corner("5px");
    $("div#crop-metadata").corner("3px");

	CropTool.identifier = identifier;

	ImageServer.initialize(identifier);
};
