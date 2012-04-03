/**
 * @fileoverview Small utility JavaScript for setting up the scenario explorer frame for testing and
 *     development.
 *
 * @author chris@audacious-software.com (Chris Karr, Audacious Software)
 */
 
/* $(document).ready(function()
{
    var scenario_names = ["Djatoka Default", "Fedora Default", "10+ Crops (1)", "10+ Crops (2)", 
                          "Multiple Crops &amp; Rotations (1)",  
                          "Multiple Crops &amp; Rotations (2)", 
                          "Multiple Crops &amp; Rotations (3)", "Polygons (1)", "Polygons (2)", 
                          "Polygons (3)", "Saved Crop (1)", "Saved Crop (2)", "Saved Crop (3)", 
                          "Change Crop ID", "Delete Crop"];
    var scenario_pages = ["djtoka", "fedora-default", "ten-plus", "ten-plus-2", "multi-1", 
                          "multi-2", "multi-3","polygon-1", "polygon-2", "polygon-3", "saved-1", 
                          "saved-2", "saved-3","change-id", "delete"];

    var html = "";
    
    for (var i = 0; i < scenario_names.length && i < scenario_pages.length; i++)
    {
        html += "<option value=\"" + scenario_pages[i] + "\">" + scenario_names[i] + "</option>";
    }
    
    $("select#user-scenarios").html(html);

    $("select#user-scenarios").change(function()
    {
        parent.tool.document.location =  $(this).val() + ".html";
    });
    
    // parent.tool.document.location =  scenario_pages[0] + ".html";
}); */
