#!/usr/bin/env ruby

# This script runs from the command line to upload photos from an SD card.
# If you don't pass it the name of an SD card, it looks for a volume mounted
# that follows the below naming scheme.  After uploading photos, it runs
# the rename-photos script

require 'date'
require 'find'

# Where the photos are and where they're going.
FLASH_CARD = ENV['FLASH_CARD'] || '/Volumes/CAMERA*'
PHOTO_DIR  = ENV['PHOTO_DIR']  || '/Volumes/Fatman/Dropbox/Photos'
UPLOAD_DIR = ENV['UPLOAD_DIR'] || "#{PHOTO_DIR}/Incoming"

# Valid files to upload
PHOTO_EXT = 'jpe?g|png|mov|mp4|avi|gif'
photo_exp = /\.(#{PHOTO_EXT})$/i

# Script to run to rename files to their final names
RENAME_PHOTOS = File.expand_path('rename-photos.rb', File.dirname(__FILE__))
unless File.executable?(RENAME_PHOTOS)
  abort "Error: Missing #{RENAME_PHOTOS}"
end

# List of files we will upload
photo_files = []

# Use glob to handle multiple SD cards
Dir[FLASH_CARD].each do |dir|
  puts "Uploading from card: #{dir}" if ENV['DEBUG']

  Find.find(dir) do |path|
    if FileTest.directory?(path) and File.basename(path)[0] == ?.
      Find.prune       # Don't look any further into this directory.
    elsif File.file?(path) and File.extname(path) =~ photo_exp
      photo_files << path
    end
  end
end

# Move files into place
system(RENAME_PHOTOS, *photo_files)
