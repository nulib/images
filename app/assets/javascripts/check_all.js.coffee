$ ->
  $("[data-behavior='check-all']").change ->
    master = $(this)[0]
    $("input[type='checkbox']").each (n, element) ->
      if($(element)[0] != master)
        console.log "Need to uncheck to " + master.checked
        console.log $(element)
        $(element).attr("checked", master.checked)
        
