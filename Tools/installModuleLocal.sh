#!/usr/bin/env bash
# installModuleLocal.sh - (re)install the built jaspTestModule bundle into JASP's
# user module library WITHOUT the GUI "Add module -> From file" click.
#
# What it does (all via JASP's own mechanism, see references below):
#   1. Runs jaspModuleBundleManager::installJaspModuleBundle(installPath, bundlePath) -
#      exactly the R call JASP's "Add module -> From file" makes
#      (jasp-desktop/Desktop/modules/dynamicmodules.cpp:310-345, getJsonForBundleInstallRequest).
#      It untars the bundle's L0 package archives into
#      ~/.local/share/JASP/JASP/Modules/binary_pkgs/<sha256>/, writes
#      Modules/manifests/jaspTestModule_manifest.json and creates the module's private
#      R library Modules/module_libs/jaspTestModule/<pkg> -> ../../binary_pkgs/<hash>.
#      On reinstall it first uninstalls the previous version (removes only binary_pkgs
#      not referenced by any remaining manifest).
#   2. Rewrites the installed manifest's "version" field to a plain string ("0.96.2").
#      Reason: JASP scans Modules/manifests/jasp*.json at startup to (re)load installed
#      modules (Desktop/modules/installedmodules.cpp, getAllAvailableModules -> parseModuleInfo).
#      parseModuleInfo() calls version.isMember("Version") which, with the jsoncpp in this
#      build, THROWS on the array format [[0,96,2]] that the bundle tooling emits
#      ("Could not parse module manifest ... requires objectValue or nullValue") ->
#      the module is silently skipped on every restart. The string format is one of the
#      formats parseModuleInfo explicitly supports (root["version"].isString() branch).
#   3. Makes sure the two JASP preferences needed for a *dev* module are set
#      (Qt QSettings INI at ~/.config/JASP/JASP.conf - there is no preferences.json):
#        developerMode=true          - without it getModules() erases jaspTestModule
#                                      (installedmodules.cpp:86-87)
#        modulesRemembered=...jaspTestModule... - modulesRemember defaults to true, so a
#                                      remembered module is enabled (ribbon button shown)
#                                      at startup (ribbonmodel.cpp, loadModules()).
#
# Usage:
#   Tools/installModuleLocal.sh [path-to-bundle] [--verify]
#     bundle default: <module dir>/bundles_out/jaspTestModule.JASPModule
#     --verify        afterwards run the dev JASP headless (offscreen) and grep the log
#                     for proof that the module loads at startup.
#   Env overrides: JASP_MODULES_DIR, JASP_CONF, JASP_MODULE_TOOLLIB, JASP_DESKTOP_DIR, JASP_BIN
#
# After this script, every "jasp-desktop/build/Desktop/JASP" start shows jaspTestModule;
# rerun it after each rebuild of the bundle. JASP must not be running.
set -euo pipefail

MODULE_NAME=jaspTestModule
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$MODULE_DIR")"

BUNDLE="$MODULE_DIR/bundles_out/$MODULE_NAME.JASPModule"
VERIFY=0
for a in "$@"; do
  case "$a" in
    --verify) VERIFY=1 ;;
    *) BUNDLE="$a" ;;
  esac
done

MODULES_DIR="${JASP_MODULES_DIR:-$HOME/.local/share/JASP/JASP/Modules}"
CONF="${JASP_CONF:-$HOME/.config/JASP/JASP.conf}"
JASP_BIN="${JASP_BIN:-${JASP_DESKTOP_DIR:-$ROOT_DIR/jasp-desktop}/build/Desktop/JASP}"

[ -f "$BUNDLE" ] || { echo "ERROR: bundle not found: $BUNDLE (build it with Tools/buildBundle.R)" >&2; exit 1; }
command -v Rscript >/dev/null || { echo "ERROR: Rscript not on PATH" >&2; exit 1; }
if pgrep -f "build/Desktop/JASP( |$)" >/dev/null 2>&1; then
  echo "ERROR: JASP appears to be running; quit it first (install replaces module_libs/manifests)." >&2; exit 1
fi

# --- find a library containing jaspModuleBundleManager (+ fs/rjson/stringr/archive) --------
find_tool_lib() {
  local c
  for c in "${JASP_MODULE_TOOLLIB:-}" \
           "$ROOT_DIR/jasp-desktop/build/Modules/Tools/jaspModuleBundleManager_library" \
           "$ROOT_DIR/.toolLib"; do
    [ -n "$c" ] && [ -d "$c/jaspModuleBundleManager" ] && [ -d "$c/archive" ] && { echo "$c"; return; }
  done
  return 1
}
TOOL_LIB="$(find_tool_lib)" || { echo "ERROR: no R library with jaspModuleBundleManager found (set JASP_MODULE_TOOLLIB)" >&2; exit 1; }
echo "==> tool lib : $TOOL_LIB"
echo "==> bundle   : $BUNDLE"
echo "==> install  : $MODULES_DIR"

# --- 1. install the bundle exactly like the GUI does ---------------------------------------
Rscript --vanilla -e "
  .libPaths(c('$TOOL_LIB', .libPaths()))
  p <- jaspModuleBundleManager::installJaspModuleBundle(
         installPath = '$MODULES_DIR',
         bundlePath  = '$BUNDLE')
  cat('installed module lib:', as.character(p), '\n')
"

# --- 2. normalize manifest version to the string format JASP's startup parser accepts ------
MANIFEST="$MODULES_DIR/manifests/${MODULE_NAME}_manifest.json"
[ -f "$MANIFEST" ] || { echo "ERROR: expected manifest not written: $MANIFEST" >&2; exit 1; }
Rscript --vanilla -e "
  .libPaths(c('$TOOL_LIB', .libPaths()))
  m <- rjson::fromJSON(file = '$MANIFEST')
  if (!is.character(m\$version)) {
    v <- unlist(m\$version)
    m\$version <- paste(v, collapse = '.')
    writeLines(rjson::toJSON(m, indent = 1), '$MANIFEST')
    cat('manifest version normalized ->', m\$version, '\n')
  } else cat('manifest version already a string:', m\$version, '\n')
"

# --- 3. preferences (Qt QSettings INI): developerMode + remembered/enabled module ----------
if [ -f "$CONF" ]; then
  cp -f "$CONF" "$CONF.bak-lastinstall"
else
  mkdir -p "$(dirname "$CONF")"; printf '[General]\n' > "$CONF"
fi
awk -v mod="$MODULE_NAME" '
  BEGIN { dev=0; rem=0; remHas=0; out="" }
  /^[[:space:]]*developerMode[[:space:]]*=/  { dev=1;   sub(/=.*/,"=true"); print; next }
  /^[[:space:]]*modulesRemembered[[:space:]]*=/ {
    rem=1
    if ($0 ~ ("(^|\\|)[[:space:]]*" mod "([[:space:]]*\\||[[:space:]]*$)")) { print; remHas=1; next }
    sub(/[[:space:]]*$/, "")
    if ($0 ~ /=$/) print $0 mod; else print $0 "|" mod
    next
  }
  { print }
  END {
    if (!dev)   print "developerMode=true"
    if (!rem)   print "modulesRemembered=" mod
  }
' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
echo "==> prefs    : $CONF (developerMode=true, modulesRemembered includes $MODULE_NAME)"

echo "==> installed tree:"
ls -ld "$MODULES_DIR/module_libs/$MODULE_NAME" >/dev/null && \
  echo "   $MODULES_DIR/module_libs/$MODULE_NAME  ($(ls "$MODULES_DIR/module_libs/$MODULE_NAME" | wc -l) pkgs)"
grep -o '"version": *"[^"]*"' "$MANIFEST" | sed 's/^/   manifest /'

# --- 4. optional offscreen verification -----------------------------------------------------
if [ "$VERIFY" = 1 ]; then
  [ -x "$JASP_BIN" ] || { echo "ERROR: JASP binary not found: $JASP_BIN (set JASP_BIN)" >&2; exit 1; }
  LOG=/tmp/opencode/jasp_load.log; mkdir -p /tmp/opencode
  echo "==> starting $JASP_BIN (offscreen, 25s) -> $LOG"
  timeout 25 env QT_QPA_PLATFORM=offscreen "$JASP_BIN" --newData >"$LOG" 2>&1 || true
  echo "==> proof:"
  grep -in "could not parse module manifest" "$LOG" && { echo "FAIL: manifest still rejected"; exit 1; }
  grep -in "jaspTestModule" "$LOG" | head -5
  grep -in "Modules::EntryBase\|RibbonButton.*is ready" "$LOG" | head -3
  echo "==> OK: no manifest parse error and $MODULE_NAME activity present in $LOG"
fi
