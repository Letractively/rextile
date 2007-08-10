
# Build a page index of all pages matching @all_like@, except for those matching @except_like@.
# 
def index_all_except( all_like, except_like )
  index = []
  dir = File.dirname @rextile_name
  paths = glob( File.join( dir, '*.rextile' ) )
  paths = paths.find_all {|path| path =~ all_like }.reject {|path| path =~ except_like }
  files = paths.map {|path| File.new(path) }
  files = files.sort_by {|file| file.mtime }.reverse

  files.each do |file|
    path = file.path
    puts '  * ' + path
  
    process path # make sure it is fully processed so we can load its DOM
  
    html_path = path.chomp( '.rextile' ) + '.htm'
    dom = Hpricot( read_file( html_path ))
    
    title = (dom%:h1).inner_html
    teaser = (dom%:p).inner_html
    
    link = File.basename( html_path )
    timestamp = file.mtime.getlocal.strftime( '%b %d, %Y' )

    index << "\"#{title}\":#{link} (#{timestamp})\n\n"
    index << "<blockquote>#{teaser} ...<a href=\"#{link}\">more</a></blockquote>\n\n"
  end
  index
end
