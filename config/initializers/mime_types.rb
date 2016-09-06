# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register_alias "text/html", :textile
Mime::Type.register_alias "text/html", :inline

Mime::Type.register "application/vnd.openxmlformats-officedocument.presentationml.presentation", :pptx