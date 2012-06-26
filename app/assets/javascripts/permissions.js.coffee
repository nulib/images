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
      data: button.closest('.control-group').find('select').attr('name')+"=none",
      dataType: 'json'
    })
    request.success (data) -> 
      button.closest('.control-group').remove()
    
  $("[data-behavior='permissions-remove']").click (e) ->
    removeBehavior(e, $(this))


  $("[data-behavior='permissions-add']").click (e) ->
    e.preventDefault()
    button = $(this)
    obj = button.attr('data-object')
    field = button.attr('data-field')
    type = button.attr('data-type')
    new_name_field = "new_#{type}_name"
    new_perm_field = "new_#{type}_permission"
    new_name = $("##{obj}_#{field}_#{new_name_field}")
    new_perm = $("##{obj}_#{field}_#{new_perm_field}")
    field_data = {}
    field_data[field] = {}
    field_data[field][new_name_field] = new_name.val()
    field_data[field][new_perm_field] = new_perm.val()
    data = {}
    data[obj] = field_data
    request = $.ajax({
      type: 'PUT',
      url: this.form.action,
      data: data,
      dataType: 'json'
    })

    request.success (data) -> 
      record = data[0]
      new_id = "#{obj}_#{field}_#{type}_#{record.name}"
      new_template = $("<div class='control-group'><label class='control-label'>#{record.name}</label><div class='controls'><select class='span2' id='#{new_id}' name='#{obj}[#{field}][#{type}][#{record.name}]'><option value='none'>No Access</option>
<option value='discover'>Discover</option>
<option value='read'>View</option>
<option value='edit'>Edit</option></select> <input class='btn' data-behavior='permissions-remove' data-field='#{field}' data-object='#{obj}' data-type='#{type}' name='commit' type='submit' value='Remove'></div></div>")
      button.closest('.control-group').before(new_template)
      new_template.find("[data-behavior='permissions-remove']").click (e) ->
        removeBehavior(e, $(this))
      new_name.val('')
      $("##{new_id} option[value='#{record.access}']").attr('selected', 'selected')
      
    request.error (jqXHR, textStatus, errorThrown) -> alert "AJAX Error: #{textStatus}."
    
