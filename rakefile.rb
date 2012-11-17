# Make file

VERSION = '1.7'

require 'rake/packagetask'

$:.unshift(File.join( File.expand_path( File.dirname( __FILE__ )), 'lib' ))

task :docs do
	require 'rextile'
	cd "doc" do 
	  Rextile.new.processGlob
	end
	cd "sample" do
		Rextile.new.processGlob
	end
end

task :build => [:docs]

Rake::PackageTask.new( 'rextile', VERSION ) do |p|
	p.need_zip = true
	p.need_tar_gz = true
	p.package_files.include "doc/**/*"
	p.package_files.include "sample/**/*"
	p.package_files.include "templates/**/*"
	p.package_files.include "lib/**/*.rb"
	p.package_files.include "lib/**/*-copyright"
	p.package_files.include "rextile*"
	p.package_files.include "rakefile.rb"
	p.package_files.include ".buildpath"
	p.package_files.include ".project"
end
task "pkg/rextile-#{VERSION}" => :build

task :default => [:clobber, :package]
