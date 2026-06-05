#!/usr/bin/env ruby
# generate_xcodeproj.rb
# Unplugged
#
# Generates Unplugged.xcodeproj using only the Ruby standard library.
# No external gems required.
#
# Usage:
#   /usr/bin/ruby generate_xcodeproj.rb

require 'fileutils'
require 'digest'

PROJECT_NAME    = "Unplugged"
BUNDLE_ID       = "com.anzydev.unplugged"
SWIFT_VERSION   = "5.9"
DEPLOY_TARGET   = "13.0"
SCRIPT_DIR      = File.expand_path("..", __FILE__)
SOURCE_DIR      = File.join(SCRIPT_DIR, PROJECT_NAME)
XCODEPROJ_DIR   = File.join(SCRIPT_DIR, "#{PROJECT_NAME}.xcodeproj")

# ── Deterministic 24-char hex ID ─────────────────────────────────────────────
def make_id(seed)
  Digest::MD5.hexdigest(seed).upcase[0..23]
end

# ── Collect Swift source files ────────────────────────────────────────────────
def collect_swift_files(root)
  Dir.glob("#{root}/**/*.swift").sort.map do |abs_path|
    rel = abs_path.sub("#{root}/", "")
    [abs_path, rel]
  end
end

# ── Generate the pbxproj content ─────────────────────────────────────────────
def generate_pbxproj(swift_files)
  proj_id          = make_id("project_root")
  target_id        = make_id("native_target")
  config_list_proj = make_id("configListProject")
  config_list_tgt  = make_id("configListTarget")
  debug_proj_id    = make_id("debugProject")
  release_proj_id  = make_id("releaseProject")
  debug_tgt_id     = make_id("debugTarget")
  release_tgt_id   = make_id("releaseTarget")
  sources_phase    = make_id("sourcesPhase")
  frameworks_phase = make_id("frameworksPhase")
  resources_phase  = make_id("resourcesPhase")
  main_group       = make_id("mainGroup")
  products_group   = make_id("productsGroup")
  source_group     = make_id("sourceGroup")
  product_ref      = make_id("productRef")
  infoplist_ref    = make_id("infoplistRef")
  entitlements_ref = make_id("entitlementsRef")

  # Build file + ref IDs per source file
  file_refs   = {}
  build_files = {}
  swift_files.each do |abs_path, rel|
    fid = make_id(rel)
    bid = make_id("#{rel}_build")
    file_refs[rel]   = { id: fid, abs: abs_path, name: File.basename(rel) }
    build_files[rel] = { id: bid, ref: fid }
  end

  # PBXFileReference lines
  file_ref_lines = file_refs.sort.map do |rel, info|
    "		#{info[:id]} = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = \"#{info[:name]}\"; path = \"#{PROJECT_NAME}/#{rel}\"; sourceTree = SOURCE_ROOT; };"
  end
  file_ref_lines << "		#{infoplist_ref} = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; name = \"Info.plist\"; path = \"#{PROJECT_NAME}/Info.plist\"; sourceTree = SOURCE_ROOT; };"
  file_ref_lines << "		#{entitlements_ref} = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; name = \"Unplugged.entitlements\"; path = \"#{PROJECT_NAME}/Unplugged.entitlements\"; sourceTree = SOURCE_ROOT; };"
  file_ref_lines << "		#{product_ref} = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; name = \"#{PROJECT_NAME}.app\"; path = \"#{PROJECT_NAME}.app\"; sourceTree = BUILT_PRODUCTS_DIR; };"

  # PBXBuildFile lines
  build_file_lines = build_files.sort.map do |rel, info|
    "		#{info[:id]} = {isa = PBXBuildFile; fileRef = #{info[:ref]}; };"
  end

  # Sources phase files
  sources_files = build_files.sort.map { |_, info| "				#{info[:id]}," }.join("\n")

  # Group hierarchy
  subdirs = {}
  file_refs.each do |rel, info|
    parts = rel.split("/")
    key = parts.length == 1 ? "__root__" : parts[0]
    (subdirs[key] ||= []) << info
  end

  subgroup_ids = {}
  subgroup_entries = []
  subdirs.sort.each do |subdir, files|
    next if subdir == "__root__"
    sg_id = make_id("group_#{subdir}")
    subgroup_ids[subdir] = sg_id
    children = files.map { |info| "				#{info[:id]}," }.join("\n")
    subgroup_entries << <<~GROUP
  		#{sg_id} = {
  			isa = PBXGroup;
  			children = (
  #{children}
  			);
  			name = "#{subdir}";
  			sourceTree = "<group>";
  		};
    GROUP
  end

  root_children      = (subdirs["__root__"] || []).map { |info| "				#{info[:id]}," }.join("\n")
  subgroup_child_refs = subgroup_ids.values.map { |id| "				#{id}," }.join("\n")

  <<~PBXPROJ
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
#{build_file_lines.join("\n")}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
#{file_ref_lines.join("\n")}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		#{frameworks_phase} = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		#{main_group} = {
			isa = PBXGroup;
			children = (
				#{source_group},
				#{products_group},
			);
			sourceTree = "<group>";
		};
		#{products_group} = {
			isa = PBXGroup;
			children = (
				#{product_ref},
			);
			name = Products;
			sourceTree = "<group>";
		};
		#{source_group} = {
			isa = PBXGroup;
			children = (
#{root_children}
#{subgroup_child_refs}
				#{infoplist_ref},
				#{entitlements_ref},
			);
			name = "#{PROJECT_NAME}";
			sourceTree = "<group>";
		};
#{subgroup_entries.join}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		#{target_id} = {
			isa = PBXNativeTarget;
			buildConfigurationList = #{config_list_tgt};
			buildPhases = (
				#{sources_phase},
				#{frameworks_phase},
				#{resources_phase},
			);
			buildRules = (
			);
			dependencies = (
			);
			name = #{PROJECT_NAME};
			productName = #{PROJECT_NAME};
			productReference = #{product_ref};
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		#{proj_id} = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					#{target_id} = {
						CreatedOnToolsVersion = 15.0;
					};
				};
			};
			buildConfigurationList = #{config_list_proj};
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = #{main_group};
			productRefGroup = #{products_group};
			projectDirPath = "";
			projectRoot = "";
			targets = (
				#{target_id},
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		#{resources_phase} = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		#{sources_phase} = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
#{sources_files}
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		#{debug_proj_id} = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ARCHS = "arm64 x86_64";
				CLANG_ENABLE_MODULES = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");
				MACOSX_DEPLOYMENT_TARGET = #{DEPLOY_TARGET};
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		#{release_proj_id} = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ARCHS = "arm64 x86_64";
				CLANG_ENABLE_MODULES = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_OPTIMIZATION_LEVEL = s;
				MACOSX_DEPLOYMENT_TARGET = #{DEPLOY_TARGET};
				MTL_FAST_MATH = YES;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		#{debug_tgt_id} = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_IDENTIFIER = "#{BUNDLE_ID}";
				CODE_SIGN_ENTITLEMENTS = "#{PROJECT_NAME}/Unplugged.entitlements";
				CODE_SIGN_STYLE = Automatic;
				ENABLE_APP_SANDBOX = NO;
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				INFOPLIST_FILE = "#{PROJECT_NAME}/Info.plist";
				LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");
				MACOSX_DEPLOYMENT_TARGET = #{DEPLOY_TARGET};
				OTHER_LDFLAGS = ("-framework IOKit", "-framework ServiceManagement", "-framework UserNotifications");
				PRODUCT_BUNDLE_IDENTIFIER = "#{BUNDLE_ID}";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = #{SWIFT_VERSION};
			};
			name = Debug;
		};
		#{release_tgt_id} = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_IDENTIFIER = "#{BUNDLE_ID}";
				CODE_SIGN_ENTITLEMENTS = "#{PROJECT_NAME}/Unplugged.entitlements";
				CODE_SIGN_STYLE = Automatic;
				ENABLE_APP_SANDBOX = NO;
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				INFOPLIST_FILE = "#{PROJECT_NAME}/Info.plist";
				LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");
				MACOSX_DEPLOYMENT_TARGET = #{DEPLOY_TARGET};
				OTHER_LDFLAGS = ("-framework IOKit", "-framework ServiceManagement", "-framework UserNotifications");
				PRODUCT_BUNDLE_IDENTIFIER = "#{BUNDLE_ID}";
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = #{SWIFT_VERSION};
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		#{config_list_proj} = {
			isa = XCConfigurationList;
			buildConfigurations = (
				#{debug_proj_id},
				#{release_proj_id},
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		#{config_list_tgt} = {
			isa = XCConfigurationList;
			buildConfigurations = (
				#{debug_tgt_id},
				#{release_tgt_id},
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = #{proj_id};
}
  PBXPROJ
end

# ── Main ──────────────────────────────────────────────────────────────────────
swift_files = collect_swift_files(SOURCE_DIR)

if swift_files.empty?
  puts "ERROR: No Swift files found in #{SOURCE_DIR}"
  exit 1
end

puts "Found #{swift_files.size} Swift source files:"
swift_files.each { |_, rel| puts "   #{rel}" }

pbxproj = generate_pbxproj(swift_files)

FileUtils.mkdir_p(XCODEPROJ_DIR)
pbxproj_path = File.join(XCODEPROJ_DIR, "project.pbxproj")
File.write(pbxproj_path, pbxproj)

puts "\n✅  Generated: #{pbxproj_path}"
puts "👉  Open in Xcode: open \"#{XCODEPROJ_DIR}\""
puts "\n⚠️  After opening in Xcode:"
puts "   1. Target → Signing & Capabilities → set your Team"
puts "   2. Build & Run (Cmd+R)"
