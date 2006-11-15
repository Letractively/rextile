require 'rubygems'
require 'erb'
require 'redcloth'
require 'hpricot'
require 'hpricot/traverse'
require 'forwardable'

# Rextile, a Ruby clone of Xilize.
class Rextile

  SITE_FILE = '_site.rb'

  REXTILE_EXT = '.rextile'
  REXTILE_WRAPPER_FILE = '_wrapper.rextinc'
  
  XHTML_EXT = '.htm'
  XHTML_WRAPPER_FILE = '_wrapper.xhtmlinc'
  XHTML_SCRIPT_SEL = 'pre.rscript'

  CONTENT_MARKER_REGEX = /CONTENT GOES HERE/

  INSTALL_PATH = File.dirname( File.dirname( __FILE__ ))


  def initialize( site_file = SITE_FILE )
    @template_path = ''
    @processed = {}
    @warnings = 0
    eval read_file( site_file )
    puts 'Using template ' + template_path unless template_path == ''
  end

  attr_reader :template_path

  # Processes all files in the current directory matching the given glob spec.
  # Default is to process all files in the current directory and its subdirectories.
  def glob( pattern = '**/*' + REXTILE_EXT )
    processAll Dir.glob( pattern )
  end

  # Processes all files in the list.
  def processAll( files )
    files.each {|file| process file }
    recap_warnings
  end

  # Processes the single, named file.
  def process( file )
    if not @processed[ file ]
      puts '> ' + file
      @processed[ file ] = true
      Processor.new( self, file ).run
    end
  end

  def read_file( path )
    File.open( path, "r" ) {|file| file.read }
  end

  def write_file( path, content ) 
    current = if File.exists?( path ) then read_file( path ) else "" end
    unless current == content
      puts "  -> " + path
      File.open( path, "w" ) {|file| file.write content }
    end
  end
  
  def warn( msg )
    @warnings += 1
    puts '  WARNING: ' + msg
  end
  
  def recap_warnings()
    if @warnings > 0
      puts "\n#{@warnings} warning(s)"
      1
    else
      0
    end
  end


  # Helper class that processes single files.
  class Processor
    extend Forwardable


    # Initializes the instance variables which need to be reset for every file processed.
    def initialize( rextile, name )
      @rextile = rextile
      @rextile_name = name
      @html_name = name.chomp( REXTILE_EXT ) + XHTML_EXT
      @root_path = rootOf( name )
      @html_doc = nil
      @html_script_node = nil
    end

    # Attributes visible to scripts.
    attr_reader :rextile, :root_path, :rextile_name, :html_name, :html_doc, :html_script_node

    # Processes the single, named file.
    def run()
      rextile = wrap( read_file( rextile_name ), REXTILE_WRAPPER_FILE )
      textile = to_textile( rextile )
      html = to_html( textile )
      html = run_rscripts_nodes( html )
      write_file( @html_name, html )
    end

    def read_closest_file( name )
      files = chain_of_files( name )
      if files.length > 0
        read_file( files[0] )
      else
        ''
      end
    end

    def read_prepended_files( name )
      files = chain_of_files( name )
      res = ''
      for file in files
        res = read_file( file ) + "\n" + res
      end
      res
    end

    def read_appended_files( name )
      files = chain_of_files( name )
      res = ''
      for file in files
        res += read_file( file ) + "\n"
      end
      res
    end

    def chain_of_files( name )
      res = []
      path = File.dirname( rextile_name )
      while true
        file = File.join( path, name )
        res << file if File.exists?( file )
        break if path == '.'
        path = File.dirname( path )
      end
      unless template_path == ''
        file = File.join( template_path, name )
        res << file if File.exists?( file )
      end
      res
    end

    def wrap( content, wrapper_name )
      wrapper = read_closest_file( wrapper_name )
      if wrapper == '' then content else wrapper.sub( CONTENT_MARKER_REGEX, content ) end
    end

    def rootOf( path )
      root = ''
      while true
        path, last = File.split( path )
        break if path == '.'
        root += '../'
      end
      root
    end
    
    def_delegators :@rextile, :template_path, :read_file, :write_file, :process, :warn

  private

    # Remove all Rextile-specific markup returning pure Textile for RedCloth, running embedded <%..%>-style scripts.
    def to_textile( rextile )

      # write_file( @rextile_name + '.~textile.erb', rextile ) if rextile_name == 'index.rextile'

      textile = erb( rextile )
      textile.gsub!( /<�/, '��_' )
      textile.gsub!( /�>/, '_��' )
      textile
    end

    # Convert Textile to HTML, running embedded <%..%>-style scripts.
    def to_html( textile )
      rc = RexCloth.new( textile )
      html = rc.to_html()
      flag_undefined_deferred_links html 
      html.gsub!( /��_/, '<%' )
      html.gsub!( /_��/, '%>' )
      html = wrap( html, XHTML_WRAPPER_FILE )
      html = process_includes( html )
      @html_doc = parse_into_dom( html )
      erb( html )
    end
    
    # Issues warnings for all undefined deferred links. This relies on you using the format
    # "text":-abbr for links with deferred targets.
    def flag_undefined_deferred_links( html )
      html.gsub( /<a href=\"\-.+\">/i ) do |match|
        warn "Undefined deferred link #{match}."
        match
      end
    end

    # Runs all nodes of the form <span class="rscript">...</span> as Ruby scripts with access to their own location.
    def run_rscripts_nodes( html )
      @html_doc = make_dom( html )
      html_doc.search( XHTML_SCRIPT_SEL ).each do |node|
        @html_script_node = node
        inner_html = eval( node.inner_html )
        if inner_html == ''
          node.parent.children.delete node
        else
          node.parent.replace_child node, Hpricot( inner_html ).root
        end
      end
      html_doc.to_html
    end

    # Run ERB on the given input.
    def erb( input )
      ERB.new( input ).result( binding )
    end

    def process_includes( s )
      s.gsub( /<%i(.*?)%>/m ) { |match| eval( $1.strip ) }
    end

    # Setup the plain DOM tree for XPath-lookups in scripts.
    def parse_into_dom( html )
      make_dom html.gsub( /<%.*?%>/m, '' )
    end

    # Setup a DOM tree.
    def make_dom( html )
      begin
        Hpricot( html )
      rescue
        write_file( @rextile_name + '.~html', html )
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

  end # class Processor


  class RexCloth < RedCloth
  
    QTAGS.reject! {|hc, ht, re, rtype| hc == '-' or hc == '+' }

    def textile_dt( tag, atts, cite, content )
      r = ''
      s = content
      while (p = (s =~ /\s\:/m))
        d = s.slice( 0, p )
        s = s.slice( p + 2, s.length )
        r << '<dt>' << d.strip << '</dt>'
      end
      "<dl>\n" << r << '<dd>' << s.strip << "</dd>\n</dl>"
    end
    
    def to_html
      merge_dls super()
    end
    
    def merge_dls( html )
      html.gsub( /<\/dl>(\s|\n)*<dl>/, '' )
    end
    
  end

  
end # class Rextile