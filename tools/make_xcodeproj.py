"""Generates ios/Tact.xcodeproj (Xcode 16+ format with folder-synced groups).

Folders Tact/, Shared/ and TactKeyboard/ are synchronized: any file you add to them in Finder or Xcode
is picked up automatically, so this script only needs re-running if targets or settings change.
"""
import hashlib
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "ios")
BUNDLE = "com.deancarson.tact"


def oid(name: str) -> str:
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()


I = {k: oid(k) for k in [
    "project", "mainGroup", "productsGroup", "supportGroup",
    "sync.Tact", "sync.Shared", "sync.TactKeyboard",
    "ref.app", "ref.appex", "ref.entApp", "ref.entKb", "ref.infoApp", "ref.infoKb", "ref.storekit",
    "t.app", "t.kb",
    "app.sources", "app.frameworks", "app.resources", "app.embed",
    "kb.sources", "kb.frameworks", "kb.resources",
    "bf.embed", "dep.kb", "proxy.kb",
    "cl.project", "cl.app", "cl.kb",
    "cfg.project.debug", "cfg.project.release", "cfg.app.debug", "cfg.app.release", "cfg.kb.debug", "cfg.kb.release",
]}


def settings(d: dict, indent: int = 4) -> str:
    tab = "\t" * indent
    out = []
    for k in sorted(d):
        v = d[k]
        if isinstance(v, list):
            items = "".join(f"{tab}\t{q(x)},\n" for x in v)
            out.append(f"{tab}{k} = (\n{items}{tab});")
        else:
            out.append(f"{tab}{k} = {q(v)};")
    return "\n".join(out)


def q(v) -> str:
    s = str(v)
    if s and all(c.isalnum() or c in "._/" for c in s) and not s[0].isdigit() or s.isdigit():
        return s
    return '"' + s.replace('"', '\\"') + '"'


COMMON = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "COPY_PHASE_STRIP": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "MTL_FAST_MATH": "YES",
    "SDKROOT": "iphoneos",
}
DEBUG = {**COMMON,
         "DEBUG_INFORMATION_FORMAT": "dwarf",
         "ENABLE_TESTABILITY": "YES",
         "GCC_DYNAMIC_NO_PIC": "NO",
         "GCC_OPTIMIZATION_LEVEL": "0",
         "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
         "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
         "ONLY_ACTIVE_ARCH": "YES",
         "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
         "SWIFT_OPTIMIZATION_LEVEL": "-Onone"}
RELEASE = {**COMMON,
           "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
           "ENABLE_NS_ASSERTIONS": "NO",
           "MTL_ENABLE_DEBUG_INFO": "NO",
           "SWIFT_COMPILATION_MODE": "wholemodule",
           "VALIDATE_PRODUCT": "YES"}

APP = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_ENTITLEMENTS": "Support/Tact.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": "",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": "Support/Tact-Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Tact",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.lifestyle",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait",
    "INFOPLIST_KEY_UIUserInterfaceStyle": "Dark",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE,
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1",
}
KB = {
    "CODE_SIGN_ENTITLEMENTS": "Support/TactKeyboard.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": "",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": "Support/TactKeyboard-Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Tact",
    "INFOPLIST_KEY_NSHumanReadableCopyright": "",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE + ".keyboard",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SKIP_INSTALL": "YES",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1",
}


def cfg(key, name, d):
    return f"""		{I[key]} /* {name} */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings(d)}
			}};
			name = {name};
		}};"""


def phase(key, isa, name):
    return f"""		{I[key]} /* {name} */ = {{
			isa = {isa};
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};"""


def sync(key, path):
    return f"""		{I[key]} /* {path} */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			path = {path};
			sourceTree = "<group>";
		}};"""


def fileref(key, path, ftype, name=None):
    return f"""		{I[key]} /* {name or path} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {q(path)}; sourceTree = "<group>"; }};"""


pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 77;
	objects = {{

/* Begin PBXBuildFile section */
		{I["bf.embed"]} /* TactKeyboard.appex in Embed Foundation Extensions */ = {{isa = PBXBuildFile; fileRef = {I["ref.appex"]} /* TactKeyboard.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		{I["proxy.kb"]} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {I["project"]} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {I["t.kb"]};
			remoteInfo = TactKeyboard;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXCopyFilesBuildPhase section */
		{I["app.embed"]} /* Embed Foundation Extensions */ = {{
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 13;
			files = (
				{I["bf.embed"]} /* TactKeyboard.appex in Embed Foundation Extensions */,
			);
			name = "Embed Foundation Extensions";
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXCopyFilesBuildPhase section */

/* Begin PBXFileReference section */
		{I["ref.app"]} /* Tact.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Tact.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{I["ref.appex"]} /* TactKeyboard.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = TactKeyboard.appex; sourceTree = BUILT_PRODUCTS_DIR; }};
{fileref("ref.entApp", "Tact.entitlements", "text.plist.entitlements")}
{fileref("ref.entKb", "TactKeyboard.entitlements", "text.plist.entitlements")}
{fileref("ref.infoApp", "Tact-Info.plist", "text.plist.xml")}
{fileref("ref.infoKb", "TactKeyboard-Info.plist", "text.plist.xml")}
{fileref("ref.storekit", "Tact.storekit", "text")}
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
{sync("sync.Tact", "Tact")}
{sync("sync.Shared", "Shared")}
{sync("sync.TactKeyboard", "TactKeyboard")}
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
{phase("app.frameworks", "PBXFrameworksBuildPhase", "Frameworks")}
{phase("kb.frameworks", "PBXFrameworksBuildPhase", "Frameworks")}
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{I["mainGroup"]} = {{
			isa = PBXGroup;
			children = (
				{I["sync.Tact"]} /* Tact */,
				{I["sync.Shared"]} /* Shared */,
				{I["sync.TactKeyboard"]} /* TactKeyboard */,
				{I["supportGroup"]} /* Support */,
				{I["ref.storekit"]} /* Tact.storekit */,
				{I["productsGroup"]} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{I["productsGroup"]} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{I["ref.app"]} /* Tact.app */,
				{I["ref.appex"]} /* TactKeyboard.appex */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{I["supportGroup"]} /* Support */ = {{
			isa = PBXGroup;
			children = (
				{I["ref.entApp"]} /* Tact.entitlements */,
				{I["ref.entKb"]} /* TactKeyboard.entitlements */,
				{I["ref.infoApp"]} /* Tact-Info.plist */,
				{I["ref.infoKb"]} /* TactKeyboard-Info.plist */,
			);
			path = Support;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{I["t.app"]} /* Tact */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {I["cl.app"]} /* Build configuration list for PBXNativeTarget "Tact" */;
			buildPhases = (
				{I["app.sources"]} /* Sources */,
				{I["app.frameworks"]} /* Frameworks */,
				{I["app.resources"]} /* Resources */,
				{I["app.embed"]} /* Embed Foundation Extensions */,
			);
			buildRules = (
			);
			dependencies = (
				{I["dep.kb"]} /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				{I["sync.Tact"]} /* Tact */,
				{I["sync.Shared"]} /* Shared */,
			);
			name = Tact;
			packageProductDependencies = (
			);
			productName = Tact;
			productReference = {I["ref.app"]} /* Tact.app */;
			productType = "com.apple.product-type.application";
		}};
		{I["t.kb"]} /* TactKeyboard */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {I["cl.kb"]} /* Build configuration list for PBXNativeTarget "TactKeyboard" */;
			buildPhases = (
				{I["kb.sources"]} /* Sources */,
				{I["kb.frameworks"]} /* Frameworks */,
				{I["kb.resources"]} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				{I["sync.TactKeyboard"]} /* TactKeyboard */,
				{I["sync.Shared"]} /* Shared */,
			);
			name = TactKeyboard;
			packageProductDependencies = (
			);
			productName = TactKeyboard;
			productReference = {I["ref.appex"]} /* TactKeyboard.appex */;
			productType = "com.apple.product-type.app-extension";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{I["project"]} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{I["t.app"]} = {{
						CreatedOnToolsVersion = 16.0;
					}};
					{I["t.kb"]} = {{
						CreatedOnToolsVersion = 16.0;
					}};
				}};
			}};
			buildConfigurationList = {I["cl.project"]} /* Build configuration list for PBXProject "Tact" */;
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {I["mainGroup"]};
			minimizedProjectReferenceProxies = 1;
			preferredProjectObjectVersion = 77;
			productRefGroup = {I["productsGroup"]} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{I["t.app"]} /* Tact */,
				{I["t.kb"]} /* TactKeyboard */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
{phase("app.resources", "PBXResourcesBuildPhase", "Resources")}
{phase("kb.resources", "PBXResourcesBuildPhase", "Resources")}
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
{phase("app.sources", "PBXSourcesBuildPhase", "Sources")}
{phase("kb.sources", "PBXSourcesBuildPhase", "Sources")}
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{I["dep.kb"]} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {I["t.kb"]} /* TactKeyboard */;
			targetProxy = {I["proxy.kb"]} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
{cfg("cfg.project.debug", "Debug", DEBUG)}
{cfg("cfg.project.release", "Release", RELEASE)}
{cfg("cfg.app.debug", "Debug", APP)}
{cfg("cfg.app.release", "Release", APP)}
{cfg("cfg.kb.debug", "Debug", KB)}
{cfg("cfg.kb.release", "Release", KB)}
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{I["cl.project"]} /* Build configuration list for PBXProject "Tact" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{I["cfg.project.debug"]} /* Debug */,
				{I["cfg.project.release"]} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{I["cl.app"]} /* Build configuration list for PBXNativeTarget "Tact" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{I["cfg.app.debug"]} /* Debug */,
				{I["cfg.app.release"]} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{I["cl.kb"]} /* Build configuration list for PBXNativeTarget "TactKeyboard" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{I["cfg.kb.debug"]} /* Debug */,
				{I["cfg.kb.release"]} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {I["project"]} /* Project object */;
}}
"""

scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES" buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{I["t.app"]}" BuildableName = "Tact.app" BlueprintName = "Tact" ReferencedContainer = "container:Tact.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES" shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{I["t.app"]}" BuildableName = "Tact.app" BlueprintName = "Tact" ReferencedContainer = "container:Tact.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
      <StoreKitConfigurationFileReference identifier = "../../Tact.storekit">
      </StoreKitConfigurationFileReference>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{I["t.app"]}" BuildableName = "Tact.app" BlueprintName = "Tact" ReferencedContainer = "container:Tact.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

proj = os.path.join(ROOT, "Tact.xcodeproj")
os.makedirs(os.path.join(proj, "xcshareddata", "xcschemes"), exist_ok=True)
with open(os.path.join(proj, "project.pbxproj"), "w") as f:
    f.write(pbx)
with open(os.path.join(proj, "xcshareddata", "xcschemes", "Tact.xcscheme"), "w") as f:
    f.write(scheme)
print("wrote", proj)
