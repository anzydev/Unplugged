#!/usr/bin/env python3
"""
generate_xcodeproj.py — Unplugged
Generates a minimal but fully functional Unplugged.xcodeproj.

Run from the project root:
    python3 generate_xcodeproj.py

Then open Unplugged.xcodeproj in Xcode.
"""

import os
import uuid
import hashlib

# ── Configuration ─────────────────────────────────────────────────────────────
PROJECT_NAME    = "Unplugged"
BUNDLE_ID       = "com.anzydev.unplugged"
SWIFT_VERSION   = "5.9"
DEPLOY_TARGET   = "13.0"
SCRIPT_DIR      = os.path.dirname(os.path.abspath(__file__))
SOURCE_DIR      = os.path.join(SCRIPT_DIR, PROJECT_NAME)
XCODEPROJ_DIR   = os.path.join(SCRIPT_DIR, f"{PROJECT_NAME}.xcodeproj")

# ── Deterministic UUID generation ─────────────────────────────────────────────
def make_id(seed: str) -> str:
    """Generates a deterministic 24-char uppercase hex string (Xcode PBX ID style)."""
    h = hashlib.md5(seed.encode()).hexdigest().upper()
    return h[:24]

# ── Collect Swift sources ──────────────────────────────────────────────────────
def collect_swift_files(root: str):
    """Returns a list of (abs_path, rel_to_source_dir) for all .swift files."""
    results = []
    for dirpath, _, filenames in os.walk(root):
        for fn in sorted(filenames):
            if fn.endswith(".swift"):
                abs_path = os.path.join(dirpath, fn)
                rel_path = os.path.relpath(abs_path, root)
                results.append((abs_path, rel_path))
    return results

# ── PBXproj generation ────────────────────────────────────────────────────────
def generate_pbxproj(swift_files):
    proj_id         = make_id("project")
    target_id       = make_id("target")
    config_list_proj= make_id("configListProject")
    config_list_tgt = make_id("configListTarget")
    debug_proj_id   = make_id("debugProject")
    release_proj_id = make_id("releaseProject")
    debug_tgt_id    = make_id("debugTarget")
    release_tgt_id  = make_id("releaseTarget")
    sources_phase   = make_id("sourcesPhase")
    frameworks_phase= make_id("frameworksPhase")
    resources_phase = make_id("resourcesPhase")
    main_group      = make_id("mainGroup")
    products_group  = make_id("productsGroup")
    source_group    = make_id("sourceGroup")
    product_ref     = make_id("productRef")
    infoplist_ref   = make_id("infoplistRef")
    entitlements_ref= make_id("entitlementsRef")

    # Build source file entries
    file_refs   = {}
    build_files = {}
    for abs_path, rel in swift_files:
        fid = make_id(rel)
        bid = make_id(rel + "build")
        file_refs[rel] = (fid, abs_path, os.path.basename(rel))
        build_files[rel] = (bid, fid)

    # ── PBXFileReference section ───────────────────────────────────────────────
    file_ref_lines = []
    for rel, (fid, _, fname) in sorted(file_refs.items()):
        file_ref_lines.append(
            f'\t\t{fid} = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
            f'name = "{fname}"; path = "{PROJECT_NAME}/{rel}"; sourceTree = SOURCE_ROOT; }};'
        )

    # Info.plist reference
    file_ref_lines.append(
        f'\t\t{infoplist_ref} = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; '
        f'name = "Info.plist"; path = "{PROJECT_NAME}/Info.plist"; sourceTree = SOURCE_ROOT; }};'
    )
    # Entitlements reference
    file_ref_lines.append(
        f'\t\t{entitlements_ref} = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; '
        f'name = "Unplugged.entitlements"; path = "{PROJECT_NAME}/Unplugged.entitlements"; sourceTree = SOURCE_ROOT; }};'
    )
    # Product reference
    file_ref_lines.append(
        f'\t\t{product_ref} = {{isa = PBXFileReference; explicitFileType = wrapper.application; '
        f'includeInIndex = 0; name = "{PROJECT_NAME}.app"; path = "{PROJECT_NAME}.app"; sourceTree = BUILT_PRODUCTS_DIR; }};'
    )

    # ── PBXBuildFile section ───────────────────────────────────────────────────
    build_file_lines = []
    for rel, (bid, fid) in sorted(build_files.items()):
        build_file_lines.append(
            f'\t\t{bid} = {{isa = PBXBuildFile; fileRef = {fid}; }};'
        )

    # ── PBXSourcesBuildPhase ───────────────────────────────────────────────────
    sources_files = "\n".join(
        f'\t\t\t\t{bid},' for _, (bid, _) in sorted(build_files.items())
    )

    # ── PBXGroup for sources ───────────────────────────────────────────────────
    # Build group hierarchy
    subdirs = {}
    for rel, (fid, _, fname) in file_refs.items():
        parts = rel.split(os.sep)
        if len(parts) == 1:
            subdirs.setdefault("__root__", []).append((fid, fname))
        else:
            subdirs.setdefault(parts[0], []).append((fid, fname))

    subgroup_ids = {}
    subgroup_lines = []
    for subdir, files in sorted(subdirs.items()):
        if subdir == "__root__":
            continue
        sg_id = make_id(f"group_{subdir}")
        subgroup_ids[subdir] = sg_id
        children = "\n".join(f'\t\t\t\t{fid},' for fid, _ in files)
        subgroup_lines.append(f"""
\t\t{sg_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children}
\t\t\t);
\t\t\tname = "{subdir}";
\t\t\tsourceTree = "<group>";
\t\t}};""")

    root_children = "\n".join(
        f'\t\t\t\t{fid},' for fid, _ in subdirs.get("__root__", [])
    )
    subgroup_child_refs = "\n".join(
        f'\t\t\t\t{sg_id},' for sg_id in subgroup_ids.values()
    )

    pbx = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_file_lines)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(file_ref_lines)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase} = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{source_group},
\t\t\t\t{products_group},
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{products_group} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{product_ref},
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{source_group} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{root_children}
{subgroup_child_refs}
\t\t\t\t{infoplist_ref},
\t\t\t\t{entitlements_ref},
\t\t\t);
\t\t\tname = "{PROJECT_NAME}";
\t\t\tsourceTree = "<group>";
\t\t}};
{''.join(subgroup_lines)}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_id} = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {config_list_tgt};
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase},
\t\t\t\t{frameworks_phase},
\t\t\t\t{resources_phase},
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = {PROJECT_NAME};
\t\t\tpackageProductDependencies = (
\t\t\t);
\t\t\tproductName = {PROJECT_NAME};
\t\t\tproductReference = {product_ref};
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{proj_id} = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {config_list_proj};
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group};
\t\t\tproductRefGroup = {products_group};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_id},
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase} = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase} = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{sources_files}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debug_proj_id} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tARCHS = "arm64 x86_64";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = {DEPLOY_TARGET};
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_proj_id} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tARCHS = "arm64 x86_64";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = {DEPLOY_TARGET};
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{debug_tgt_id} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_IDENTIFIER = "{BUNDLE_ID}";
\t\t\t\tCODE_SIGN_ENTITLEMENTS = "{PROJECT_NAME}/Unplugged.entitlements";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tENABLE_APP_SANDBOX = NO;
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = NO;
\t\t\t\tINFOPLIST_FILE = "{PROJECT_NAME}/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = {DEPLOY_TARGET};
\t\t\t\tOTHER_LDFLAGS = ("-framework IOKit", "-framework ServiceManagement", "-framework UserNotifications");
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "{BUNDLE_ID}";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_tgt_id} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_IDENTIFIER = "{BUNDLE_ID}";
\t\t\t\tCODE_SIGN_ENTITLEMENTS = "{PROJECT_NAME}/Unplugged.entitlements";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tENABLE_APP_SANDBOX = NO;
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = NO;
\t\t\t\tINFOPLIST_FILE = "{PROJECT_NAME}/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = {DEPLOY_TARGET};
\t\t\t\tOTHER_LDFLAGS = ("-framework IOKit", "-framework ServiceManagement", "-framework UserNotifications");
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "{BUNDLE_ID}";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{config_list_proj} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_proj_id},
\t\t\t\t{release_proj_id},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{config_list_tgt} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_tgt_id},
\t\t\t\t{release_tgt_id},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {proj_id};
}}
"""
    return pbx


def main():
    swift_files = collect_swift_files(SOURCE_DIR)
    if not swift_files:
        print(f"❌  No Swift files found in {SOURCE_DIR}")
        return

    print(f"Found {len(swift_files)} Swift source file(s):")
    for _, rel in swift_files:
        print(f"   {rel}")

    pbxproj_content = generate_pbxproj(swift_files)

    os.makedirs(XCODEPROJ_DIR, exist_ok=True)
    pbxproj_path = os.path.join(XCODEPROJ_DIR, "project.pbxproj")

    with open(pbxproj_path, "w", encoding="utf-8") as f:
        f.write(pbxproj_content)

    print(f"\n✅  Generated: {pbxproj_path}")
    print(f"👉  Open in Xcode:")
    print(f"    open \"{XCODEPROJ_DIR}\"")
    print()
    print("⚠️  After opening, set your Development Team in:")
    print("    Target → Signing & Capabilities → Team")


if __name__ == "__main__":
    main()
