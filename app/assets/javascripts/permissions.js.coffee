$ ->
  $("[data-behavior='permissions-add-existing']").removeClass('hidden')
  $("[data-behavior='permissions-remove-existing']").removeClass('hidden')
  $("[data-behavior='permissions-add-new']").removeClass('hidden')
  $("[data-behavior='permissions-remove-new']").removeClass('hidden')

  removeExistingBehavior = (e, button) ->
    e.preventDefault()
    request = $.ajax({
      type: 'PUT',
      url: button.closest('form').attr('action'),
      data: button.closest('[data-behavior="access-entry"]').find('select,input[type=hidden]').attr('name')+"=none",
      dataType: 'json'
    })
    request.success (data) -> 
      button.closest('[data-behavior="access-entry"]').remove()

  removeBehavior = (e, button) ->
    e.preventDefault()
    button.closest('[data-behavior="access-entry"]').remove()

  addNewBehavior = (e, button) ->
    e.preventDefault()
    name = button.attr('data-name')
    value = button.attr('data-value')
    new_name = $("##{name}")
    new_perm = $("##{value}")
    info = { record_name: new_name.val() }
    new_template = $(tmpl(button.attr('data-template'), info))
    button.closest('[data-behavior="access-entry"]').before(new_template)
    new_template.find("[data-behavior='permissions-remove-new']").click (e) ->
      removeBehavior(e, $(this))
    new_name.val('')
    new_template.find("option[value='#{new_perm.val()}']").attr('selected', 'selected')
    
  $("[data-behavior='permissions-remove-existing']").click (e) ->
    removeExistingBehavior(e, $(this))

  $("[data-behavior='permissions-remove-new']").click (e) ->
    removeBehavior(e, $(this))

  $("[data-behavior='permissions-add-new']").click (e) ->
    addNewBehavior(e, $(this))

  $("[data-behavior='permissions-add-existing']").click (e) ->
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
        button.closest('[data-behavior="access-entry"]').before("<div class=\"alert alert-info\"> <button class=\"close\" data-dismiss=\"alert\">×</button> #{data.errors.join()}  </div>")
      else
        record = data.values[0]
        info = { record_name: record.name }
        new_template = $(tmpl(button.attr('data-template'), info))
        button.closest('[data-behavior="access-entry"]').before(new_template)
        new_template.find("[data-behavior='permissions-remove-existing']").click (e) ->
          removeExistingBehavior(e, $(this))
        new_name.val('')
        new_template.find("option[value='#{record.access}']").attr('selected', 'selected')
      
    request.error (jqXHR, textStatus, errorThrown) -> alert "AJAX Error: #{textStatus}."
    
