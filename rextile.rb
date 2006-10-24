require 'rubygems'
require 'erb'
require 'redcloth'
require 'hpricot'
require 'hpricot/traverse'

# Rextile, a Ruby clone of Xilize.
class Rextile

	SITE_FILE = '_site.rb'

	REXTILE_EXT = '.rextile'
	REXTILE_WRAPPER_FILE = '_wrapper.rextinc'

	XHTML_EXT = '.htm'
	XHTML_WRAPPER_FILE = '_wrapper.xhtml'
	XHTML_SCRIPT_SEL = 'pre.rscript'
	
	CONTENT_MARKER_REGEX = /CONTENT GOES HERE/

	
	def initialize()
		@template_path = ''
		eval readFile( SITE_FILE )
		puts 'Using template ' + template_path unless template_path == ''
		init_per_file()
	end

	# Processes all files in the current directory matching the given glob spec.
	# Default is to process all files in the current directory and its subdirectories.
	def glob( pattern = '**/*' + REXTILE_EXT )
		Dir.glob( pattern ) {|rextileName| process rextileName }
	end
	
	# Processes the single, named file.
	def process( rextileName )
		puts '> ' + rextileName
		init_per_file()
		@rextile_name = rextileName
		@html_name = rextileName.chomp( REXTILE_EXT ) + XHTML_EXT
		@root_path = rootOf( rextileName )
		rextile = wrap( readFile( rextileName ), REXTILE_WRAPPER_FILE )
		textile = to_textile( rextile )
		html = to_html( textile )
		html = run_rscripts_nodes( html )
		writeFile( @html_name, html )
	end

	# Initializes the instance variables which need to be reset for every file processed.
	def init_per_file()
		@root_path = ''
		@rextile_name = ''
		@html_name = ''
		@html_doc = nil
		@html_script_node = nil
	end
	
	# Attributes visible to scripts.
	attr_reader :root_path, :rextile_name, :html_doc, :html_script_node, :html_name, :template_path
	
	# Remove all Rextile-specific markup returning pure Textile for RedCloth, running embedded <%..%>-style scripts.
	def to_textile( rextile )

		# writeFile( @rextile_name + '.~textile.erb', rextile ) if rextile_name == ''
		
		textile = erb( rextile )
		textile.gsub!( /<§/, '§§_' )
		textile.gsub!( /§>/, '_§§' )
		textile
	end

	# Convert Textile to HTML, running embedded <%..%>-style scripts.
	def to_html( textile )
		rc = RexCloth.new( textile )
		html = rc.to_html()
		html.gsub!( /§§_/, '<%' )
		html.gsub!( /_§§/, '%>' )
		html = wrap( html, XHTML_WRAPPER_FILE )
		@html_doc = parseIntoDOM( html )
		erb( html )
	end
	
	# Runs all nodes of the form <span class="rscript">...</span> as Ruby scripts with access to their own location.
	def run_rscripts_nodes( html )
		@html_doc = makeDOM( html )
		html_doc.search( XHTML_SCRIPT_SEL ).each do |node|
			@html_script_node = node
			innerHtml = eval( node.inner_html )
			unless innerHtml == ''
				node.parent.replace_child node, Hpricot( innerHtml ).root
			else
				node.parent.children.delete node
			end
		end
		html_doc.to_html
	end
	
	# Run ERB on the given input.
	def erb( input )
		input = process_includes( input )
		ERB.new( input ).result( binding )
	end
	
	def process_includes( s )
		res = ''
		rest = s
		while rest =~ /(.*?)<%i(.*?)%>(.*)/m
			head, inc, rest = $1, $2, $3
			res += head + eval( inc.strip )
		end
		res + rest
	end
	
	# Setup the plain DOM tree for XPath-lookups in scripts.
	def parseIntoDOM( html )
		makeDOM html.gsub( /<%.*?%>/m, '' )
	end

	# Setup a DOM tree.
	def makeDOM( html )
		begin
			Hpricot( html )
		rescue
			writeFile( @rextile_name + '.~html', html )
			raise
		end
	end

	# Convert the given string into a parsable string constant.
	def string_const( s )
		"tex += <<__LIT__\n" + end_in_newline( s ) + "__LIT__\n\n"
	end
	
	# Ensure the given string ends in a newline. If not, add one.
	def end_in_newline( s )
		if s =~ /.*\n\z/m then s else s + "\n" end
	end

	
	def readClosestFile( fileName )
		files = chainOfFiles( fileName )
		if files.length > 0
			readFile( files[0] )
		else
			''
		end
	end

	def readPrependedFiles( fileName )
		files = chainOfFiles( fileName )
		res = ''
		for file in files
			res = readFile( file ) + "\n" + res
		end
		res
	end
	
	def readAppendedFiles( fileName )
		files = chainOfFiles( fileName )
		res = ''
		for file in files
			res += readFile( file ) + "\n"
		end
		res
	end
	
	def chainOfFiles( fileName )
		res = []
		path = File.dirname( rextile_name )
		while true
			file = File.join( path, fileName )
			res += [file] if File.exists?( file )
			break if path == '.'
			path = File.dirname( path )
		end
		unless template_path == ''
			file = File.join( template_path, fileName )
			res += [file] if File.exists?( file )
		end
		res
	end

	def wrap( content, wrapperName )
		wrapper = readClosestFile( wrapperName )
		if wrapper == '' then content else wrapper.sub( CONTENT_MARKER_REGEX, content ) end
	end
	
	def rootOf( fileName )
		path = fileName
		root = ''
		while true
			path, last = File.split( path )
			break if path == '.'
			root += '../'
		end 
		root
	end

	
	def readFile( fileName )
		File.open( fileName, "r" ) {|file| file.read }
	end

	def writeFile( fileName, content )
		current = if File.exists?( fileName ) then readFile( fileName ) else "" end
		unless current == content
			puts "  -> " + fileName
			File.open( fileName, "w" ) {|file| file.write content } 
		end
	end
	
end


class RexCloth < RedCloth

	QTAGS.reject! {|hc, ht, re, rtype| hc == '-' or hc == '+' }

end


# Main
rx = Rextile.new()
rx.glob()


