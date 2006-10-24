# Initialize template-specific variables.

@page_title = ''
	# If set, defines the value for <head><title>. Otherwise, the text of the first <h1> is used.

@crumbs = []
	# Use "@crumbs += ['mysection']" in your per-folder _settings.rb file to define the caption 
	# for the breadcrumbs backlink.

@styles = []
	# Use "<% @style += ['...'] %>" in documents to add custom style definitions to <head><style>.

@body_attrs = []
	# Use "<% @body_attrs += ['...'] %>" in documents to add custom attributes to the <body> tag.
	# Useful to add, for example, "onLoad" event code.

@head_nodes = []
	# Use <% @head_nodes += ['...'] %> in documents to add custom header nodes (into <head>..</head>).

