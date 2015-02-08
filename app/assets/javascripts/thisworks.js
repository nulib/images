

$(document).ready(function(){
  // This method is called when a user clicks the Save button to add an image to an image group from the image show view.
  // An API is called to add the image to the collection.
$("#downloads").append("<div id='thanksObama'>Save</div>");
$("#thanksObama").on("click", (function() {
      //get the collection pid from the select list selected option
      console.log("thanks Obama");
      // var collectionPid = $("#collection_list option:selected").attr("id");
      // //get the image pid from the url
      // var imagePid = $("[name='id']")[0].value;


      //This is spin.js code to show a spinner
      // var spinOpts = {
      //   lines: 8, // The number of lines to draw
      //   length: 4, // The length of each line
      //   width: 4, // The line thickness
      //   radius: 4, // The radius of the inner circle
      //   top: 'auto', // Top position relative to parent in px
      //   left: 'auto' // Left position relative to parent in px
      // };
      // var target = document.getElementById('spinnerElement');
      // var spinner = new Spinner(spinOpts).spin(target);

      // //make the API call
      // $.ajax({
      //   type: "POST",
      //   url: "/dil_collections/add/" + collectionPid + "/" + imagePid,
      //   success: function(jsonObject){
      //     //spinner.stop();
      //   },

      // error: function(output){
      //   alert("Could not add image to Image Group");
      //   spinner.stop();
      // }
      // });//end ajax
}));



  console.log('bib number');

   //$('input[checked="checked"]').closest('.listing').addClass("thumbnailSelected");

    // When a user wants to add an image to a collection from the image show view, they click a button.
    // This will get the collection titles and pids by calling an API and show a select list with the collections
    // $("#addToImageGroupBtn").on("click",(function() {
    //  console.log('i have no idea what you are talking about')
    //  if ($("#collection_list").length==0){
    //    //make ajax call to get collections and build select list
    //    var select_list = "<select id='collection_list'>"
    //    $.ajax({
    //       type: "GET",
    //       url: '/dil_collections/get_collections.json',
    //       dataType: 'json',
    //       success: function(jsonObject){
    //         //loop through each collection the json
    //         var selectList = "<select id='collection_list'>"
    //         $.each(jsonObject, function(){
    //           selectList += "<option val='" + this.id + "' id='" + this.id + "'>" + this.title_tesim[0] + "</option>"
    //         });

    //         selectList += "</select>"
    //         $("#downloads").append(selectList);
    //         //$("#downloads").append("<div id='thanksObama'>Save</div>");
    //       },

    //     error: function(output){
    //       alert("Could not add image to Image Group");
    //     }
    //    });//end ajax
    //  }//end if
    // }));

  // Edit image group name toggle show form
  // $('.edit_dil_collection').hide();
  // $('#rename_image_group_link').on('click', function(){
  //   $('.edit_dil_collection').slideToggle();
  // });


});




