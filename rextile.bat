@echo off
if not "%~f0" == "~f0" goto WinNT
ruby -x "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofruby
:WinNT
ruby -x "%~f0" %*
exit /b %errorlevel%
#!/bin/ruby

require 'rubygems'

$:.unshift(File.join( File.expand_path( File.dirname( __FILE__ )), 'lib' ))

require 'rextile'

exit Rextile.new.processGlob

__END__
:endofruby
