/**
 * Site-specific URLs for fetching Crop Tool content.
 */
 
var Site = {};

/**
 * Creates a URL that creates the crop specified by the given dimensions.
 */
 
Site.createCropUrl = function(x, y, width, height, image)
{
	return "/multiresimages/create?x=" + x + "&y=" + y + "&width=" + width + "&height=" + height + "&id=" + image;
};

/**
 * Creates a URL for fetching a single crop by PID.
 */

Site.fetchCropUrl = function(pid)
{
	return "/multiresimages/svg/" + pid ;
};

Site.fetchRawImageUrl = function(pid)
{
	return "/multiresimages/svg/" + pid ;
};

Site.putCropUrl = function(pid)
{
	return "/multiresimages/updatecrop/" + pid;
};

Site.thumbnailImageUrl = function(pid, img_width, img_height, req_width, req_height)
{
	return "http://cecil.library.northwestern.edu:8983/fedora/get/" + pid + "/inu:sdef-image/getCropWithSize?" + "destheight=" + img_height + 
		   "&destwidth=" + img_width + "&x=0&y=0&height=" + Math.floor(req_height) + "&width=" + Math.floor(req_width);
};

Site.tileUrl = function(img_path, level, x, y)
{
	return "/multiresimages/aware_tile?file_path=" + img_path + "&level=" + level + "&x=" + x + "&y=" + y;
};

Site.fetchImageUrl = function(pid)
{
	return Site.fetchCropUrl(pid);
};

Site.iconPath = function()
{
	return "/assets/croptool/";
};

Site.catalogPathForPid = function(pid)
{
	return "/catalog/" + pid;
};
