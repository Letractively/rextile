# Initialize template-specific variables.

# If set, defines the value for <head><title>. Otherwise, the text of the first <h1> is used.
@page_title = nil

# Use "@crumbs << 'mysection'" in your per-folder _settings.rb file to define the caption 
# for the breadcrumbs backlink.
@crumbs = []

# Use "@rootcrumb = '<a href="http://my.extroot.org/">External Root</a>'" to define a root crumb which is not built automatically.
@rootcrumb = nil

# Use "<% @style << '...' %>" in documents to add custom style definitions to <head><style>.
@styles = []

# Use "<% @body_attrs << '...' %>" in documents to add custom attributes to the <body> tag.
# Useful to add, for example, "onLoad" event code.
@body_attrs = []

# Use <% @head_nodes << '...' %> in documents to add custom header nodes (into <head>..</head>).
@head_nodes = []

