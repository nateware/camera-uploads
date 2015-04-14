#!/usr/bin/env ruby

# This is designed as a standalone script, or something that can be
# run from a Mac Image Capture action.  You need to create an Automator
# action that links this script to an image upload.  The Automator action
# needs to supply the files as command line arguments. To copy the script:
# pbcopy < rename-photos.rb

require 'date'
require 'fileutils'

# Where the photos are and where they're going.
PHOTO_DIR  = ENV['PHOTO_DIR']  || "#{ENV['HOME']}/Pictures"
UPLOAD_DIR = ENV['UPLOAD_DIR'] || "#{PHOTO_DIR}/Incoming"
FLASH_CARD = '/Volumes/CAMERA*'

# The format for the new file names.
DATE_SUBDIR = "%Y/%Y-%m-%d"
FILE_FORMAT = "%Y-%m-%d %H.%M.%S" # strtime

# Log if run from a script
unless STDOUT.isatty
  fh = File.open('/tmp/camera-uploads.log','a')
  STDOUT.reopen(fh)
  STDERR.reopen(fh)
end

# Return the date/time on which the given photo was taken.
def photo_date(file)
  output = `sips -g creation "#{file}"`.chomp.split(/\n/)[1]
  if output.nil? || output =~ /error|<nil>/i
    # fallback to file date
    File.mtime(file)
  else
    date = output.sub(/^\s*creation:\s*/, '')
    DateTime.strptime(date, "%Y:%m:%d %H:%M:%S")
  end
rescue => e
  puts "#{e}: #{output}"
  File.mtime(file)
end

# Simple path helper
def make_path(outdir, newname, extension)
  "#{outdir}/#{newname}#{extension.downcase}"
end

# Sanity check
abort "Missing image dir: #{PHOTO_DIR}" unless File.directory?(PHOTO_DIR)

# Figure out if we were given a list of photos on the command line
photos =
  if ARGV.length > 0
    ARGV
  else
    Dir["#{UPLOAD_DIR}/*"]
  end

# Copy photos into year and month subfolders. Name the copies according to
# their timestamps. If more than one photo has the same timestamp, add
# suffixes 'a', 'b', etc. to the names.
for photo in photos
  unless File.file?(photo)
    puts "File does not exist: #{photo}"
    next
  end

  date = photo_date(photo)
  basename  = File.basename(photo)
  extension = File.extname(photo)
  puts "Processing #{photo} (#{extension}) from #{date}" if ENV['DEBUG']

  subdir = date.strftime(DATE_SUBDIR)
  outdir = "#{PHOTO_DIR}/#{subdir}"
  FileUtils.mkdir_p(outdir) unless File.directory?(outdir)

  # watch for duplicates shot on the same second - very possible
  newname = date.strftime(FILE_FORMAT)
  newpath = make_path(outdir, newname, extension)
  suffix  = 'a'
  while File.exists?(newpath)
    newname = date.strftime(FILE_FORMAT) + suffix
    suffix  = (suffix.ord+1).chr
    newpath = make_path(outdir, newname, extension)
  end

  puts "#{photo} -> #{newpath}"
  abort "File exists somehow: #{newpath}" if File.exists?(newpath)
  FileUtils.mv(photo, newpath) unless ENV['TEST']

  # Delete from flash card
  # NO: This throws off the Image Capture app
  # sources = Dir["#{FLASH_CARD}/**/#{basename}"]
  # unless sources.length == 1
  #   abort "Expecting exactly one source for #{basename}: #{sources}"
  # end
  # orig = sources.first
  # puts "rm #{orig}"
  # File.unlink(orig)
end
