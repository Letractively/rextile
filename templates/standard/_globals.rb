# Global utility functions for Rextile's standard template.

require 'cgi'


# Returns only the pure text content of the given node.
#
def text_only( node )
	txt = ''
	node.traverse_text{ |tn| txt << tn.content } unless node == nil
	txt
end


# Formats the breadcrumbs accumulated in @crumbs into a series of links, separated by the
# given separator. The last crumb is omitted of the current page's name is "index.rextile".
#
def breadcrumbs( separator )
  res = ''
  pre = ''
  n = @crumbs.length
  if File.basename( rextile_name ) == 'index.rextile'
    n -= 1
    pre = '../'
  end
  if n > 0
    i = n - 1
    while i >= 0
      crumb = @crumbs[ i ]
      if crumb.kind_of?( Array )
        target = crumb[ 1 ]
        crumb = crumb[ 0 ]
      else
        target = pre + 'index.htm'
        pre += '../'
      end
      lk = '<a href="' + target + '">' + crumb + '</a>'
      lk += separator unless res == ''
      res = lk + res
      i -= 1
    end
  end
  if @rootcrumb
	res = separator + res unless res == ''
	res = @rootcrumb + res
  end
  res
end


# Inserts a Rextile XHTML script node which will later build a table of contents of the range of
# headers between "from" and "to". Headers with no existing anchor are given one using the
# specified prefix.
#
# The TOC is enclosed in a <div class="toc">..</div> tag. The individual links are organized
# as nested <ul>s. Each <ul> has the class "toc" and "toc<n>", where <n> is the header level.
# List items with children have the class "withitems". So:
#
#	<div class="toc">
# 		<ul class="toc toc2">
#			<li><a href="#pagetoc__1">Book 1</a></li>
#			<li class="withitems"><a href="#pagetoc__2">Book 2</a>
#				<ul class="toc toc3">
#					<li><a href="#pagetoc__2_1">Chapter 2.1</a></li>
#					<li><a href="#pagetoc__2_2">Chapter 2.2</a></li>
#				</ul>
#			</li>
#			<li><a href="#pagetoc__3">Book 3</a></li>
#		</ul>
#	</div>
#
def toc( from = 2, to = 3, anchor_prefix = 'pagetoc__' )
  "<pre class=\"rscript\">xtoc #{from}, #{to}, '#{anchor_prefix}'</pre>"
end

def xtoc( hfrom = 2, hto = 3, anchor_prefix = 'pagetoc__' )
  wantTag = 'h' + hfrom.to_s
  subs = subs_of( html_script_node, hfrom, hto, [] )
  unless subs == nil
    hs, stops = subs
    '<div class="toc">' + make_toc( hs, hfrom, hto, anchor_prefix, 1, stops ) + '</div>'
  else
    ''
  end
end

def subs_of( h, hfrom, hto, stop_tags )
  hscan = hfrom
  while hscan <= hto
    want_tag = 'h' + hscan.to_s
    subs = list_of_subs_of( h, stop_tags, want_tag )
    if subs.length > 0
      return [subs, stop_tags + [want_tag]]
    end
    stop_tags += [want_tag]
    hscan += 1
  end
  nil
end

def make_toc( hs, hfrom, hto, anchor_prefix, toc_level, collected_tags )
  anchor_number = 1
  toc = ''
  for h in hs 
    if h.parent 
      anchor = anchor_prefix + anchor_number.to_s

      sub_toc = ''
      stop_tags = collected_tags
      hscan = hfrom + 1
      sub_level = toc_level + 1
      while hscan <= hto 
        want_tag = 'h' + hscan.to_s
        subs = list_of_subs_of( h, stop_tags, want_tag )
        if subs.length > 0 
          sub_toc = make_toc( subs, hscan, hto, anchor + "_", sub_level, stop_tags + [want_tag] )
          break
        end
        stop_tags += [want_tag]
        sub_level += 1
        hscan += 1
      end
      
      hentry = make_toc_entry( h, anchor )
      if sub_toc == ""
        toc += '<li>' + hentry + '</li>'
      else
        toc += '<li class="withitems">' + hentry + sub_toc + '</li>'
      end
      anchor_number += 1
    end
  end
  '<ul class="toc toc' + toc_level.to_s + '">' + toc + '</ul>';
end

def make_toc_entry( node, anchor )
  node_html = ""
  chd = node.children.first
  if not chd.text? and chd.name.downcase() == "a"
    node_html = chd.inner_html
    anchor = chd.get_attribute( "name" )
  else
    node_html = node.inner_html
    node.inner_html = '<a name="' + anchor + '">' + node_html + '</a>'
  end
  node_html.gsub!( /\<br\s*\/\>/i, '' )
  '<a href="#' + anchor + '">' + node_html + '</a>'
end

def list_of_subs_of( node, stop_tags, want_tag )
  hs = []
  nodes = node.parent.children
  at = nodes.index( node ) + 1
  while at < nodes.length
    node = nodes[ at ]
    unless node.text?
      atTag = node.name.downcase
      if atTag =~ /h.*/
        break if stop_tags.index( atTag )
        hs += [node] if want_tag == atTag;
      end
    end
    at += 1
  end
  hs
end


# Renders embedded graphviz graph to SVG.
#
def dot(g)
  "<pre class=\"rscript\">xdot '#{g}'</pre>"
end

def xdot(g)
  g = CGI.unescapeHTML(g)
  if not g =~ /^digraph /
    g = "digraph G { " + g + " }"
  end
  s = IO.popen("dot -Tsvg", mode="r+") { |d| d.puts(g); d.close_write; d.readlines }
  e = []
  started = false
  s.each do |l|
    started = true if l =~ /^<svg /
    e << l if started
  end
  e.join("\n")
end
