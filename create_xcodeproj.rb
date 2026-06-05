#!/usr/bin/env ruby
# create_xcodeproj.rb
# Unplugged
#
# Programmatically generates Unplugged.xcodeproj using the xcodeproj gem.
# Run this script once to create the Xcode project, then open it in Xcode.
#
# Usage:
#   gem install xcodeproj
#   ruby create_xcodeproj.rb
#
# After running, open Unplugged.xcodeproj in Xcode.

require 'xcodeproj'
require 'fileutils'

PROJECT_NAME    = 'Unplugged'
BUNDLE_ID       = 'com.anzydev.unplugged'
DEPLOYMENT_TARGET = '13.0'
SWIFT_VERSION   = '5.9'
PROJECT_ROOT    = File.dirname(__FILE__)
SOURCE_DIR      = File.join(PROJECT_ROOT, 'Unplugged')
XCODEPROJ_PATH  = File.join(PROJECT_ROOT, "#{PROJECT_NAME}.xcodeproj")

# ── Create project ────────────────────────────────────────────────────────────
project = Xcodeproj::Project.new(XCODEPROJ_PATH)

# ── Add macOS application target ──────────────────────────────────────────────
target = project.new_target(:application, PROJECT_NAME, :osx, DEPLOYMENT_TARGET)

# ── Build configurations ───────────────────────────────────────────────────────
shared_settings = {
  'BUNDLE_IDENTIFIER'              => BUNDLE_ID,
  'PRODUCT_NAME'                   => PROJECT_NAME,
  'SWIFT_VERSION'                  => SWIFT_VERSION,
  'MACOSX_DEPLOYMENT_TARGET'       => DEPLOYMENT_TARGET,
  'INFOPLIST_FILE'                 => "#{PROJECT_NAME}/Info.plist",
  'CODE_SIGN_ENTITLEMENTS'         => "#{PROJECT_NAME}/Unplugged.entitlements",
  'ENABLE_APP_SANDBOX'             => 'NO',
  'ENABLE_HARDENED_RUNTIME'        => 'YES',
  'CODE_SIGN_STYLE'                => 'Automatic',
  'ARCHS'                          => 'arm64 x86_64',
  'VALID_ARCHS'                    => 'arm64 x86_64',
  'OTHER_LDFLAGS'                  => '-framework IOKit -framework ServiceManagement -framework UserNotifications',
  'SWIFT_STRICT_CONCURRENCY'       => 'complete',
  'LD_RUNPATH_SEARCH_PATHS'        => '$(inherited) @executable_path/../Frameworks',
  'ALWAYS_SEARCH_USER_PATHS'       => 'NO',
  'CLANG_ENABLE_MODULES'           => 'YES',
}

project.build_configurations.each do |config|
  config.build_settings.merge!(shared_settings)
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = config.name == 'Release' ? '-O' : '-Onone'
end

target.build_configurations.each do |config|
  config.build_settings.merge!(shared_settings)
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = config.name == 'Release' ? '-O' : '-Onone'
end

# ── Add source files ───────────────────────────────────────────────────────────
source_group = project.new_group(PROJECT_NAME, SOURCE_DIR)

def add_files_recursively(group, dir, target)
  Dir.glob("#{dir}/**/*.swift").sort.each do |file|
    relative_dir = File.dirname(file).sub(dir + '/', '').sub(dir, '')
    path_components = relative_dir.empty? ? [] : relative_dir.split('/')

    current_group = group
    path_components.each do |component|
      existing = current_group.groups.find { |g| g.name == component }
      current_group = existing || current_group.new_group(component)
    end

    file_ref = current_group.new_file(file)
    target.add_file_references([file_ref])
  end
end

add_files_recursively(source_group, SOURCE_DIR, target)

# ── Add Info.plist & entitlements as references (not compiled) ─────────────────
source_group.new_file(File.join(SOURCE_DIR, 'Info.plist'))
source_group.new_file(File.join(SOURCE_DIR, 'Unplugged.entitlements'))

# ── Save ───────────────────────────────────────────────────────────────────────
project.save
puts "✅  #{XCODEPROJ_PATH} created successfully."
puts "👉  Open it in Xcode: open #{XCODEPROJ_PATH}"
puts ""
puts "⚠️  Reminder: set your Development Team in Xcode before building."
puts "   Target → Signing & Capabilities → Team"
