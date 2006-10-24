# Global utility functions for Rextile's standard template.


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
			lk = '<a href="' + pre + 'index.htm">' + @crumbs[ i ] + '</a>'
			lk += separator unless res == ''
			res = lk + res
			pre += '../'
			i -= 1
		end
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
	subs = subsOf( html_script_node, hfrom, hto, [] )
	unless subs == nil
		hs, stops = subs
		'<div class="toc">' + makeToc( hs, hfrom, hto, anchor_prefix, 1, stops ) + '</div>'
	else
		''
	end
end

def subsOf( h, hfrom, hto, stopTags )
	hscan = hfrom
	while hscan <= hto
		wantTag = 'h' + hscan.to_s
		subs = listOfSubsOf( h, stopTags, wantTag )
		if subs.length > 0
			return [subs, stopTags + [wantTag]]
		end
		stopTags += [wantTag]
		hscan += 1
	end
	nil
end

def makeToc( hs, hfrom, hto, anchor_prefix, toc_level, collectedTags )
	anchor_number = 1
	toc = ''
	for h in hs 
		if h.parent 
			anchor = anchor_prefix + anchor_number.to_s

			sub_toc = ''
			stopTags = collectedTags
			hscan = hfrom + 1
			sub_level = toc_level + 1
			while hscan <= hto 
				wantTag = 'h' + hscan.to_s
				subs = listOfSubsOf( h, stopTags, wantTag )
				if subs.length > 0 
					sub_toc = makeToc( subs, hscan, hto, anchor + "_", sub_level, stopTags + [wantTag] )
					break
				end
				stopTags += [wantTag]
				sub_level += 1
				hscan += 1
			end
			
			hentry = makeTocEntry( h, anchor )
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

def makeTocEntry( node, anchor )
	nodeHtml = ""
	chd = node.children.first
	if not chd.text? and chd.name.downcase() == "a"
		nodeHtml = chd.inner_html
		anchor = chd.get_attribute( "name" )
	else
		nodeHtml = node.inner_html
		node.innerHTML = '<a name="' + anchor + '">' + nodeHtml + '</a>'
	end
	'<a href="#' + anchor + '">' + nodeHtml + '</a>'
end

def listOfSubsOf( node, stopTags, wantTag )
	hs = []
	nodes = node.parent.children
	at = nodes.index( node ) + 1
	while at < nodes.length
		node = nodes[ at ]
		unless node.text?
			atTag = node.name.downcase
			if atTag =~ /h.*/
				break if stopTags.index( atTag )
				hs += [node] if wantTag == atTag;
			end
		end
		at += 1
	end
	hs
end

