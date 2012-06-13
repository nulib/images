$ ->
  $("[data-behavior='check-all']").change ->
    master = $(this)[0]
    $("input[type='checkbox']").each (n, element) ->
      if(element != master)
        element.checked = master.checked
        
