@echo off
if not "%~f0" == "~f0" goto WinNT
ruby -x "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofruby
:WinNT
ruby -x "%0" %*
exit /b %errorlevel%
#!/bin/ruby

require 'rubygems'
Gem.manage_gems

require File.join( File.dirname( __FILE__ ), 'lib/rextile' )

exit Rextile.new.glob

__END__
:endofruby
