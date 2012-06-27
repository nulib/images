$ ->
  $("[data-behavior='permissions-add']").removeClass('hidden')
  $("[data-behavior='permissions-remove']").removeClass('hidden')
  removeBehavior = (e, button) ->
    e.preventDefault()
    obj = button.attr('data-object')
    field = button.attr('data-field')
    type = button.attr('data-type')
    request = $.ajax({
      type: 'PUT',
      url: button.closest('form').attr('action'),
      data: button.closest('.control-group').find('select,input[type=hidden]').attr('name')+"=none",
      dataType: 'json'
    })
    request.success (data) -> 
      button.closest('.control-group').remove()
    
  $("[data-behavior='permissions-remove']").click (e) ->
    removeBehavior(e, $(this))


  $("[data-behavior='permissions-add']").click (e) ->
    e.preventDefault()
    button = $(this)
    name = button.attr('data-name')
    value = button.attr('data-value')
    new_name = $("##{name}")
    new_perm = $("##{value}")
    request = $.ajax({
      type: 'PUT',
      url: this.form.action,
      data: new_name.attr('name')+"="+new_name.val()+"&"+new_perm.attr('name')+"="+new_perm.val(),
      dataType: 'json'
    })

    request.success (data) ->
      if data.errors
        button.closest('.control-group').before("<div class=\"alert alert-info\"> <button class=\"close\" data-dismiss=\"alert\">×</button> #{data.errors.join()}  </div>")
      else
        record = data.values[0]
        info = { record_name: record.name }
        new_template = $(tmpl(button.attr('data-template'), info))
        button.closest('.control-group').before(new_template)
        new_template.find("[data-behavior='permissions-remove']").click (e) ->
          removeBehavior(e, $(this))
        new_name.val('')
        new_template.find("option[value='#{record.access}']").attr('selected', 'selected')
      
    request.error (jqXHR, textStatus, errorThrown) -> alert "AJAX Error: #{textStatus}."
    
