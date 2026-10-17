#!/usr/bin/env python3
"""Verify jaspTestModule::multiDataSetFunc end-to-end through JASP's RPC server.

Precondition: JASP (dev build) already running offscreen with RPC enabled, NO datasets.
Steps: load DataSetA + DataSetB (2 datasets in the workspace), create the multi-dataset
test analysis, and drive it the way the GUI dropdowns do: options dataSetA/dataSetB carry
FILTER IDS (form A -> filter 1 = dataset 1, form B -> filter 2 = dataset 2, simultaneously -
the linked-dropdown regression scenario), dependentA = Score (ds1) and dependentB = Score
(same name, ds2!) + Condition (only ds2). Never analysis_setFilter (that is the analysis-
global FilterMenuButton filter). Asserts:
  - 'Datasets in this run' has 2 rows with titles + row/col counts
  - 'Selected variables' rows have n=10 and the right means (Score/Score land on DIFFERENT
    datasets: 12.50 vs 17.73 - no 'variable compared with itself')
  - the metaDump echo audits the post-D3.3 provenance contract as R RECEIVED it:
    options$.meta carries no dataSetId/filterId (C8) and no .filterIds sidecar survives
    the engine-boundary strip (C11); per-form routing is proven at the VALUE level
    (each form's variable resolves against its own selection's slice: 12.50 vs 17.73)
  - no raw JASPColumn_* anywhere (decode on send)
And the C3/VERIFY-live block (mds-plan C3/M5): switch one host's selection mid-session and
assert the next run only shows the LIVE selections - no phantom slice for the abandoned filter,
no provenance stamps on scalars or on the selection options themselves, column values restamped
onto the new filter (there and back).
Exit 0 = all good, 1 = failure (details printed).

Run recipe (scripted crash-repro + verify loop):
  1. ~/.config/JASP/JASP.conf has rpcServerEnabled=true (and no JASP running).
  2. cd <jasp-desktop>/build && QT_QPA_PLATFORM=offscreen ./Desktop/JASP
     (under gdb to capture a backtrace if it dies:
        gdb -batch -ex run -ex bt --args ./Desktop/JASP > /tmp/jasp_run.log 2>&1 &)
  3. python3 Tools/verifyMultiDataSetRpc.py
Before the jasp-desktop fix 785afe486 this died at analysis_create: the SEGV is
reproduced when JASP exits mid-script, backtrace in the gdb log.
"""

# ----------------------------------------------------------------------------
# Minimal JSON-RPC 2.0 client for JASP's RPC server (enabled by the preference
# rpcServerEnabled=true in ~/.config/JASP/JASP.conf; listens on port 48164,
# path /rpc by default).
# ----------------------------------------------------------------------------
import json as _json, time as _time, urllib.request as _urllib

URL = "http://127.0.0.1:48164/rpc"
_id = 0

def _rpc(method, params=None, timeout=60):
    global _id
    _id += 1
    body = _json.dumps({"jsonrpc": "2.0", "id": _id, "method": method,
                        "params": params or {}}).encode()
    req = _urllib.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with _urllib.urlopen(req, timeout=timeout) as r:
        return _json.loads(r.read().decode())

def wait_up(max_wait=120):
    start = _time.time()
    while _time.time() - start < max_wait:
        try:
            r = _rpc("ping", timeout=2)
            if "result" in r:
                return r
        except Exception:
            _time.sleep(0.5)
    raise RuntimeError("RPC server did not come up")

call = _rpc

import sys, json, time, os, re as _re

# Locations (mds-plan C4/S9): nothing machine-specific. The module dir is resolved as
# --module=<dir> (argv) > $JASP_TESTMODULE_DIR > the directory containing this script
# (it lives in <module>/Tools/, so the default is self-locating).
def _findModuleDir():
    for a in sys.argv[1:]:
        if a.startswith("--module="):
            return os.path.abspath(a.split("=", 1)[1])
    env = os.environ.get("JASP_TESTMODULE_DIR")
    if env:
        return os.path.abspath(env)
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

_moduleDir = _findModuleDir()
A_CSV = os.path.join(_moduleDir, "Tools", "testdata", "DataSetA.csv")
B_CSV = os.path.join(_moduleDir, "Tools", "testdata", "DataSetB.csv")

fails = []
def check(name, cond, extra=""):
    print(("PASS " if cond else "FAIL ") + name + (f"  {extra}" if extra else ""))
    if not cond:
        fails.append(name)

def call(method, params=None, timeout=90):
    r = _rpc(method, params, timeout=timeout)
    if "error" in r:
        print(f"RPC error on {method}: {json.dumps(r['error'])[:600]}")
    return r.get("result", r)

wait_up(120)
print("== RPC up ==")

da = call("data_load", {"path": A_CSV, "wait": True, "timeoutMs": 60000})
db = call("data_load", {"path": B_CSV, "wait": True, "timeoutMs": 60000})
check("two datasets loaded (ids 1 and 2)", da.get("dataSetId") == 1 and db.get("dataSetId") == 2,
      f"ids {da.get('dataSetId')}, {db.get('dataSetId')}")
i1 = call("data_info", {"dataSetId": 1})
check("dataset 1 has Group (only in A)", any(c["name"] == "Group" for c in i1.get("columns", [])))

an = call("analysis_create", {"module": "jaspTestModule", "analysis": "multiDataSetFunc"})
check("form created without SEGV, analysis multiDataSetAware", an.get("status") == "success" and an.get("multiDataSetAware") is True)
aid = an.get("analysisId")

# The FilterSelect dropdowns write their selection into options dataSetA/dataSetB (filter ids),
# exactly like the desktop GUI does - no analysis_setFilter anywhere (that is the analysis-GLOBAL
# filter, the FormMenuButton's; per-form selection must never touch it):
r1 = call("analysis_run", {"analysisId": aid, "wait": True, "timeoutMs": 60000, "options": {
    "dataSetA": "1",
    "dependentA": {"types": [], "value": ["Score"]}}})
check("run 1 (dataSetA=f1, dependentA=Score) complete", r1.get("status") == "complete", str(r1.get("status")))

# The real regression scenario: form B selects filter 2 (dataset 2) WHILE form A stays on
# filter 1 - both selections live simultaneously, identically named column from each.
r2 = call("analysis_run", {"analysisId": aid, "wait": True, "timeoutMs": 120000, "options": {
    "dataSetA": "1",
    "dataSetB": "2",
    "dependentA": {"types": [], "value": ["Score"]},
    "dependentB": {"types": [], "value": ["Score", "Condition"]},
    "showMeta": True}})
check("second run complete", r2.get("status") == "complete", str(r2.get("status")))

# poll for completion
for _ in range(30):
    st = call("get_analyses_state", {"analysisIds": [aid], "include_options": True, "include_results": False})
    a = (st.get("analyses") or [{}])[0]
    if a.get("status") in ("complete", "empty", "noData", "running"):
        if a.get("status") != "running":
            break
    time.sleep(1)
check("analysis status complete", a.get("status") == "complete", f"status={a.get('status')} errors={str(a.get('errors'))[:300]}")

res = call("analysis_results", {"analysisId": aid, "wait": True, "timeoutMs": 60000})
open("results_multidataset.json", "w").write(json.dumps(res, indent=1))
import shutil, os
rds = res.get("jaspResultsRds")
if rds and os.path.exists(rds):
    shutil.copy(rds, "jaspResults_copied.rds")
results = res.get("results", res)

def tables(node, path=""):
    out = {}
    if isinstance(node, dict):
        if "schema" in node and "data" in node:
            out[path] = node
        for k, v in node.items():
            out.update(tables(v, f"{path}/{k}"))
    elif isinstance(node, list):
        for i, v in enumerate(node):
            out.update(tables(v, f"{path}[{i}]"))
    return out

tabs = tables(results)
print("tables found:", [(k, t.get("title")) for k, t in tabs.items()][:20])

def field_maps(t):
    """jaspBase json, both layouts: column-major (data[i] is a {rowKey: value} map for schema
    field i) and row-major (data[i] is one {field: value} dict per row, setData(data.frame))."""
    fields = [f["name"] for f in t["schema"]["fields"]]
    data = t["data"]
    if data and all(isinstance(e, dict) and set(e.keys()) <= set(fields) and e.keys() for e in data):
        rows = {f"row{i}": r for i, r in enumerate(data)}
        fm = {f: {k: r.get(f) for k, r in rows.items()} for f in fields}
        return fields, fm, sorted(rows.keys())
    rowkeys = set()
    for entry in data:
        for key, val in entry.items():
            if val is not None and key not in fields:
                rowkeys.add(key)
    return fields, {f: data[i] for i, f in enumerate(fields)}, sorted(rowkeys)

ds = next((t for t in tabs.values() if t.get("title") == "Datasets in this run"), None)
check("'Datasets in this run' table present", ds is not None)
if ds:
    fields, fm, rks = field_maps(ds)
    dump = json.dumps([fm[f].get(r) for r in rks for f in fields])
    check("2 dataset rows", len(rks) == 2, str(rks))
    titles = sorted(str(fm["title"].get(r)) for r in rks)
    check("both dataset titles present (non-empty)", len(titles) == 2 and all(t not in ("None", "") for t in titles), str(titles))
    check("row counts 10/10", all(fm["rows"].get(r) == 10 for r in rks), str([fm["rows"].get(r) for r in rks]))
    check("col counts present", all(isinstance(fm["cols"].get(r), int) for r in rks), str([fm["cols"].get(r) for r in rks]))
    check("no raw JASPColumn_* in overview", "JASPColumn" not in dump, dump[:300])
    print("Datasets-in-this-run rows:", json.dumps([{f: fm[f].get(r) for f in fields} for r in rks]))

sv = next((t for t in tabs.values() if t.get("title") == "Selected variables"), None)
check("'Selected variables' table present", sv is not None)
if sv:
    fields, fm, rks = field_maps(sv)
    dump = json.dumps({r: {f: fm[f].get(r) for f in fields} for r in rks})
    rows = [{f: fm[f].get(r) for f in fields} for r in rks]
    def row(src, var): return next((x for x in rows if x["source"] == src and x["variable"] == var), None)
    check("3 selected-variable rows (A:Score, B:Score, B:Condition)", len(rows) == 3, dump[:500])
    a_score = row("A", "Score")
    b_score = row("B", "Score")
    b_cond  = row("B", "Condition")
    check("A:Score routed to dataset 1", a_score and a_score["dataSetId"] in (1, "1") and a_score["dataSetName"] == "DataSet 1", json.dumps(a_score))
    check("B:Score (name in BOTH datasets) routed to dataset 2", b_score and b_score["dataSetId"] in (2, "2") and b_score["dataSetName"] == "DataSet 2", json.dumps(b_score))
    check("B:Condition (only in dataset 2) routed there", b_cond and b_cond["dataSetId"] in (2, "2"), json.dumps(b_cond))
    check("n=10 on every row", all(r["n"] == 10 for r in rows), str([r["n"] for r in rows]))
    print("Selected variables rows:")
    for r in rows: print("   ", json.dumps(r))
    check("scale rows show mean, factor row shows levels",
          a_score and str(a_score["values"]).startswith("mean") and b_cond and str(b_cond["values"]) == "X, Y, Z",
          f"{a_score['values'] if a_score else None!r} / {b_cond['values'] if b_cond else None!r}")
    # the headline: same column name, two datasets, two different truths (NOT the same variable):
    check("A:Score is DataSetA's Score (mean 12.50)", a_score and "12.50" in str(a_score["values"]), json.dumps(a_score))
    check("B:Score is DataSetB's Score (mean 17.73), not A's repeated", b_score and "17.73" in str(b_score["values"]), json.dumps(b_score))
    check("A:Score and B:Score are different rows with different data", bool(a_score and b_score and a_score["values"] != b_score["values"]))
    check("decoded names, no raw JASPColumn_*", "JASPColumn" not in dump, dump[:300])

check("analysis references both datasets (dataSetIds in run response)", sorted(r2.get("dataSetIds", [])) == [1, 2], str(r2.get("dataSetIds")))

# T3c (mds-plan D3.3 flip): provenance as R sees it - NONE. The generated Engine json keeps
# .meta provenance-free (C8) and the transient .filterIds sidecar is stripped at the engine
# boundary (C11); the metaDump html (options$showMeta was on) audits exactly that. Per-form
# provenance still routes the DATA (two same-named columns, two truths) - pinned value-level
# above: A:Score 12.50 vs B:Score 17.73.
meta_text = json.dumps(results).replace(chr(92)+chr(34), '"').replace("&quot;", '"').replace("&#34;", '"')
AUDIT_RE = r'filterIdsSeen=(\w+) metaProvenanceKeys=(\d+)'
def provenance_audit(res):
    """(filterIdsSeen, metaProvenanceKeys) from the metaDump echo of a results payload."""
    text = json.dumps(res).replace(chr(92) + chr(34), '"').replace("&quot;", '"').replace("&#34;", '"')
    m = _re.search(AUDIT_RE, text)
    return (m.group(1), m.group(2)) if m else (None, None)
audit2 = provenance_audit(results)
check("metaDump ran (provenance audit present)", audit2[0] is not None, str(audit2))
check("R never sees .filterIds (C11 strip at the engine boundary)", audit2 == ("false", audit2[1]), str(audit2))
check("options$.meta as R received it carries no provenance keys (C8)", audit2[1] == "0", str(audit2))

# ----------------------------------------------------------------------------
# C3/VERIFY-live (mds-plan C3/M5): the phantom-slice class. Switch ONE HOST'S SELECTION
# mid-session and check the NEXT run's data shows only the LIVE selections: no slice queued
# for an abandoned filter, and the run's provenance still C8/C11-clean (the per-run audit).
# Since the D3.3 flip the restamp moves the TYPED term filterIds (HostFilterSelection
# ::restampValuesUnderHost -> ListModel::restampTermsFilterId -> generated `.filterIds`), the
# .meta half is dead. This RPC workspace has one (default) filter per dataset, so the
# mid-session switch here crosses datasets (form A: f1 -> f2 -> f1); the sharp same-dataset/
# other-filter case - where no encoded value changes and only the restamp walk can keep the
# sidecar honest - is pinned C++/QML-side by
# Tests/qmlTests/tst_dataSetSelectionVariablesList.qml::test_midsession_switch_restamps_column_values
# (and tst_generatedOptionsJsonAware.qml::test_aware_midswitch_sidecar_follows_without_stale_ids).
# ----------------------------------------------------------------------------

def run_and_results(opts, tag):
    r = call("analysis_run", {"analysisId": aid, "wait": True, "timeoutMs": 120000, "options": opts})
    check(f"{tag} complete", r.get("status") == "complete", str(r.get("status")))
    res = call("analysis_results", {"analysisId": aid, "wait": True, "timeoutMs": 60000})
    return r, res

def overview_ids(res):
    t = next((x for x in tables(res.get("results", res)).values() if x.get("title") == "Datasets in this run"), None)
    if not t:
        return None, None
    fields, fm, rks = field_maps(t)
    return sorted(str(fm["id"].get(r)) for r in rks), t

# switch form A to dataset 2's filter (both forms then sit on DataSet 2):
r3, res3 = run_and_results({
    "dataSetA": "2",
    "dataSetB": "2",
    "dependentA": {"types": [], "value": ["Score"]},
    "dependentB": {"types": [], "value": ["Score", "Condition"]},
    "showMeta": True}, "run 3 (form A switched to filter 2 mid-session)")

ids3, _ = overview_ids(res3)
check("run 3: no phantom slice - only DataSet 2 loaded", ids3 == ["2"], str(ids3))
check("run 3: dataSetIds not over-reported", sorted(r3.get("dataSetIds", [])) == [2], str(r3.get("dataSetIds")))
audit3 = provenance_audit(res3)
check("run 3: still no provenance reaches R after the switch (C8/C11)", audit3 == ("false", "0"), str(audit3))
# (old stamp-window checks retired with the meta stamps, mds-plan D3.3: the C8 audit above
# covers scalars and selection options too - NO dataSetId/filterId key may appear ANYWHERE)

sv3 = next((t for t in tables(res3.get("results", res3)).values() if t.get("title") == "Selected variables"), None)
rows3 = []
if sv3:
    f3, fm3, rk3 = field_maps(sv3)
    rows3 = [{f: fm3[f].get(r) for f in f3} for r in rk3]
a3 = next((x for x in rows3 if x["source"] == "A" and x["variable"] == "Score"), None)
check("run 3: A:Score routed through the restamped key to DataSet 2 (mean 17.73)",
      a3 and str(a3["dataSetId"]) == "2" and "17.73" in str(a3["values"]), json.dumps(a3))

# and back: form A returns to filter 1 - DataSet 1 must come back exactly once (no doubled slice):
r4, res4 = run_and_results({
    "dataSetA": "1",
    "dataSetB": "2",
    "dependentA": {"types": [], "value": ["Score"]},
    "dependentB": {"types": [], "value": ["Score", "Condition"]},
    "showMeta": True}, "run 4 (form A switched back to filter 1)")

ids4, _ = overview_ids(res4)
check("run 4: exactly one slice per dataset again", ids4 == ["1", "2"], str(ids4))
check("run 4: dataSetIds reports both datasets", sorted(r4.get("dataSetIds", [])) == [1, 2], str(r4.get("dataSetIds")))
audit4 = provenance_audit(res4)
check("run 4: provenance contract held through the switch-back too (C8/C11)", audit4 == ("false", "0"), str(audit4))
a4 = None
sv4 = next((t for t in tables(res4.get("results", res4)).values() if t.get("title") == "Selected variables"), None)
if sv4:
    f4, fm4, rk4 = field_maps(sv4)
    a4 = next((x for x in ({f: fm4[f].get(r) for f in f4} for r in rk4) if x["source"] == "A" and x["variable"] == "Score"), None)
check("run 4: A:Score back on DataSet 1 (mean 12.50)", a4 and str(a4["dataSetId"]) == "1" and "12.50" in str(a4["values"]), json.dumps(a4))

# ----------------------------------------------------------------------------
# mds-plan D6.3 - the component zoo (jaspTestModule analysis multiDataSetControlsFunc /
# testMultiDataSetControls.qml). Every control family echoes what it RECEIVED (encoded names,
# decoded again on the way out), which slice index each value resolved in, and its row children,
# so per-item provenance is asserted at the value level. The RPC workspace has one default filter
# per dataset (ids 1 and 2), which is exactly two distinct namespaces for the twin cases.
# Checks per family:
#   - same-name columns across two filters in the SAME list (twins) -> distinct encodings,
#     correct per-slice values (the 12.50/17.73 trick per family)
#   - per-row provenance in the TableFields-style row control (row-bearing variables list):
#     twin rows keep their own keep/shift children (the D6.1 TermRowKey re-keying; pre-fix the
#     second row clobbered the first)
#   - FactorLevelList encodeThis roundtrip: factor/level names arrive usable and NOTHING in the
#     final results leaks a raw JaspExtraOptions_ or JASPColumn_ token
#   - interaction terms resolve as one unit in a single slice (uniform term-level filterId)
#   - textarea host: tokens encode through the textarea's own selection and resolve there
#   - cross-host bindTo (D6.2): a typed copy carrying the SOURCE filterId resolves in the
#     SOURCE's slice although the destination list selects the other one
#   - scalars/combos stay plain; PROVENANCE_AUDIT clean on every zoo run
# ----------------------------------------------------------------------------

zoo = call("analysis_create", {"module": "jaspTestModule", "analysis": "multiDataSetControlsFunc"})
check("zoo form created, analysis multiDataSetAware", zoo.get("status") == "success" and zoo.get("multiDataSetAware") is True)
zid = zoo.get("analysisId")

def zoo_run(opts, tag):
    r = call("analysis_run", {"analysisId": zid, "wait": True, "timeoutMs": 120000, "options": opts})
    check(f"zoo {tag} complete", r.get("status") == "complete", str(r.get("status")))
    res = call("analysis_results", {"analysisId": zid, "wait": True, "timeoutMs": 60000})
    return r, res

def zoo_rows(res):
    t = next((x for x in tables(res.get("results", res)).values() if x.get("title") == "Controls provenance"), None)
    if not t:
        return None
    fields, fm, rks = field_maps(t)
    return [{f: fm[f].get(r) for f in fields} for r in rks]

def zoo_slice_ids(res):
    t = next((x for x in tables(res.get("results", res)).values() if x.get("title") == "Datasets in this run"), None)
    if not t:
        return None
    fields, fm, rks = field_maps(t)
    return sorted(str(fm["id"].get(r)) for r in rks)

def find(rows, family, pred=lambda r: True):
    return [r for r in (rows or []) if r["family"] == family and pred(r)]

# analysis_run options are a DELTA (form->parseOptions binds only the given members, everything
# else keeps its current bound value - verified live): every zoo run below sends the FULL explicit
# option set (families emptied, hosts deselected) so slice/dataSetIds expectations are exact.
EMPTY_TERMS = {"types": [], "value": []}
EMPTY_ROWS  = {"types": [], "value": [], "optionKey": "variable"}
EMPTY_INTER = {"types": [], "value": [], "optionKey": "components"}
EMPTY_CODEF = {"modelOriginal": "", "model": "", "columns": []}

def zoo_full_opts(host_a="1", host_b="", host_c="", host_d="", host_f="", host_g="",
                  assigned_a=None, assigned_b=None, rows_c=None, bound_g=None,
                  interaction_d=None, factors_e=None, code_f=None, combo_a="",
                  plain_switch=False, show_meta=True):
    opts = {
        "dataSetA": host_a, "dataSetB": host_b, "dataSetC": host_c,
        "dataSetD": host_d, "dataSetF": host_f, "dataSetG": host_g,
        "assignedA": assigned_a or dict(EMPTY_TERMS),
        "assignedB": assigned_b or dict(EMPTY_TERMS),
        "rowsC":     rows_c or dict(EMPTY_ROWS),
        "boundG":    bound_g or {"value": []},
        "interactionD": interaction_d or dict(EMPTY_INTER),
        "factorsE":  factors_e or [],
        "codeF":     code_f or dict(EMPTY_CODEF),
        "comboA": combo_a, "comboG": "first", "plainSwitch": plain_switch,
    }
    if show_meta:
        opts["showMeta"] = True
    return opts

# --- zoo run 1: sanity - plain list through host A, audit on -------------------------------------
zr1, zres1 = zoo_run({
    "dataSetA": "1",
    "assignedA": {"types": ["scale"], "value": ["Score"]},
    "showMeta": True}, "run 1 (plain list via host A)")
z1 = zoo_rows(zres1)
check("zoo run 1: provenance table present", z1 is not None)
a1 = find(z1, "assigned-list")
check("zoo run 1: assignedA Score resolves in slice 1 (12.50)",
      len(a1) == 1 and str(a1[0]["slice"]) == "1" and "12.50" in str(a1[0]["values"]), json.dumps(a1))
auditz1 = provenance_audit(zres1)
check("zoo run 1: PROVENANCE_AUDIT clean (C8/C11)", auditz1 == ("false", "0"), str(auditz1))
zslices1 = zoo_slice_ids(zres1) or []
check("zoo run 1: slice 1 queued (host A), nothing beyond the workspace's two slices",
      "1" in zslices1 and set(zslices1) <= {"1", "2"}, str(zslices1))

# --- zoo run 2: the whole zoo ---------------------------------------------------------------------
# rowsC arrives in the STORAGE term-object shape: same-name twin rows 'Score' behind filter 1
# (keep=true, shift=1) and filter 2 (keep=false, shift=7). The applier must keep BOTH rows' own
# children (D6.1) and each token must encode/resolve through ITS filter's view.
# boundG receives a typed copy of a list on filter 1 (Score@1) while its OWN selection is filter 2:
# the destination rule must not requalify the foreign stamp (D6.2) - it resolves in slice 1.
# codeF's host selects filter 1 while the workspace's SHOWN dataset is B (filter 2): the textarea's
# bind-time encodeRScript must go through the HOST's view (C13 host-bound) - a Score token
# resolving in slice 1 (12.50) proves it; the analysis-level fallback would have yielded 17.73.
zr2, zres2 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_b={"types": ["nominal"], "value": ["Condition"]},
    rows_c={"value": [{"variable": {"name": "Score", "types": ["scale"], "filterId": 1}, "keep": True, "shift": 1},
                      {"variable": {"name": "Score", "types": ["scale"], "filterId": 2}, "keep": False, "shift": 7}],
            "optionKey": "variable"},
    bound_g={"value": [{"name": "Score", "types": ["scale"], "filterId": 1}]},
    interaction_d={"types": [["scale", "scale"]], "value": [{"components": ["Score", "Age"]}], "optionKey": "components"},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    code_f={"modelOriginal": "Score + Age", "model": "Score + Age", "columns": []},
    combo_a="Score", plain_switch=True), "run 2 (full zoo)")
z2 = zoo_rows(zres2)
dump2 = json.dumps(z2) if z2 is not None else ""
check("zoo run 2: provenance table present", z2 is not None)
print("zoo run 2 rows:")
for r in (z2 or []):
    print("   ", json.dumps(r))

# components-rows: the D6.1 flagship - twins with OWN children, distinct slices + values
rc = find(z2, "components-rows")
rc1 = next((r for r in rc if str(r["slice"]) == "1"), None)
rc2 = next((r for r in rc if str(r["slice"]) == "2"), None)
check("zoo run 2: rowsC twin rows kept DISTINCT encodings (two rows, slices 1 and 2)",
      len(rc) == 2 and rc1 is not None and rc2 is not None, dump2[:400])
check("zoo run 2: twin row @1 carries its OWN children keep=true shift=1 (+ 12.50)",
      rc1 and "keep=TRUE" in rc1["rowChild"] and "shift=1," in rc1["rowChild"] + "," and "12.50" in rc1["values"], json.dumps(rc1))
check("zoo run 2: twin row @2 carries its OWN children keep=false shift=7 (+ 17.73)",
      rc2 and "keep=FALSE" in rc2["rowChild"] and "shift=7" in rc2["rowChild"] and "17.73" in rc2["values"], json.dumps(rc2))
check("zoo run 2: decoded names, no raw JASPColumn_* in any row", "JASPColumn" not in dump2, dump2[:300])

# cross-host bindTo (D6.2)
bg = find(z2, "bindto-cross-host")
check("zoo run 2: boundG typed copy resolves in the SOURCE slice 1 (12.50) while its own host selects filter 2",
      len(bg) == 1 and str(bg[0]["slice"]) == "1" and "12.50" in str(bg[0]["values"]), json.dumps(bg))

# assigned-host (Zoo B)
ab = find(z2, "assigned-host")
check("zoo run 2: assignedB (own host) Condition resolves in slice 2 with its levels",
      len(ab) == 1 and str(ab[0]["slice"]) == "2" and ab[0]["values"].startswith("X"), json.dumps(ab))

# combobox (Zoo A): plain string value; NOTE the namespace finding - a DropDown is not a list
# host (no dataSetSelectionOption, resolvedSelectionHost stays the analysis level per C13), so
# its value encodes through the FORM namespace (shown filter = DataSet 2 here), not zooVarsA's.
# The zoo asserts the honest contract: value stays a plain string (never term-objectified,
# landmine 4) and roundtrips encoded->decoded intact.
ca = find(z2, "combobox-host")
check("zoo run 2: comboA 'Score' stays plain and resolves in exactly one slice (analysis-level namespace)",
      len(ca) == 1 and ca[0]["received"] == "Score" and str(ca[0]["slice"]) in ("1", "2"), json.dumps(ca))

# interaction (Zoo D): one term, components share the slice
itr = find(z2, "interaction-list")
check("zoo run 2: interaction Score:Age (host D=1) resolves as one unit in slice 1",
      len(itr) == 1 and str(itr[0]["slice"]) == "1" and "share slice 1" in str(itr[0]["values"]), json.dumps(itr))

# factor levels (Zoo E): extras roundtrip - names usable, decoded, no leakage
fe = find(z2, "factor-levels")
check("zoo run 2: factorsE echoes Group with levels A, B (decoded and usable)",
      len(fe) == 1 and fe[0]["received"] == "Group" and "A, B" in fe[0]["rowChild"], json.dumps(fe))

# textarea host (Zoo F): tokens resolved through dataSetF's slice (1) - the SHARP host-bound proof:
# the workspace's shown dataset is B (filter 2), so 17.73 here would mean the analysis-level
# fallback won and the host declaration was ignored.
tf = find(z2, "textarea-host")
tf_scores = [r for r in tf if r["received"] == "Score"]
tf_ages   = [r for r in tf if r["received"] == "Age"]
tf_texts  = [r for r in tf if r["option"] == "codeF(text)"]
check("zoo run 2: codeF host-1 tokens: Score resolves in slice 1 (12.50, NOT the shown-dataset 17.73)",
      len(tf_scores) >= 1 and all(str(r["slice"]) == "1" for r in tf_scores) and any("12.50" in r["values"] for r in tf_scores), json.dumps(tf_scores))
check("zoo run 2: codeF host-1 tokens: Age resolves in slice 1",
      len(tf_ages) >= 1 and all(str(r["slice"]) == "1" for r in tf_ages) and any(r["values"] not in ("", "None", None) for r in tf_ages), json.dumps(tf_ages))
check("zoo run 2: codeF model text round-trips (decoded on the way out)",
      len(tf_texts) == 1 and tf_texts[0]["received"] == "Score + Age", json.dumps(tf_texts))

# scalars stay plain (M5): echo rows exist with the plain values
sc = find(z2, "scalar")
cg = find(z2, "combobox-plain")
check("zoo run 2: scalar plainSwitch echoes plain true (never provenanced)", len(sc) == 1 and sc[0]["received"].upper() == "TRUE", json.dumps(sc))
check("zoo run 2: plain combo comboG echoes 'first' (never term-objectified)", len(cg) == 1 and cg[0]["received"] == "first", json.dumps(cg))

# slices: hosts on filters 1+2 (A,D on 1; B,F,G on 2) + every referenced value's slice
zslices2 = zoo_slice_ids(zres2)
check("zoo run 2: both slices present, no phantom", zslices2 == ["1", "2"], str(zslices2))
auditz2 = provenance_audit(zres2)
check("zoo run 2: PROVENANCE_AUDIT clean", auditz2 == ("false", "0"), str(auditz2))
fullres2 = json.dumps(zres2)
check("zoo run 2: NO raw JASPColumn_* anywhere in results", "JASPColumn" not in fullres2)
check("zoo run 2: NO raw JaspExtraOptions_ leakage anywhere in results", "JaspExtraOptions" not in fullres2)

# --- zoo run 3: same-name twins in the PLAIN assigned list (storage term objects) -----------------
zr3, zres3 = zoo_run(zoo_full_opts(
    host_a="1",
    assigned_a={"value": [{"name": "Score", "types": ["scale"], "filterId": 1},
                          {"name": "Score", "types": ["scale"], "filterId": 2}]},
    show_meta=False), "run 3 (plain-list twins, everything else reset)")
z3 = zoo_rows(zres3)
al = find(z3, "assigned-list")
t1 = next((r for r in al if str(r["slice"]) == "1"), None)
t2 = next((r for r in al if str(r["slice"]) == "2"), None)
check("zoo run 3: assignedA twin rows distinct (both 'Score', two slices, two truths)",
      len(al) == 2 and t1 and t2 and "12.50" in t1["values"] and "17.73" in t2["values"], json.dumps(al))
check("zoo run 3: dataSetIds covers both datasets", sorted(zr3.get("dataSetIds", [])) == [1, 2], str(zr3.get("dataSetIds")))

# --- zoo run 4: reset to a single plain family on host A (baseline for the mid-session switch) ----
zr4, zres4 = zoo_run(zoo_full_opts(host_a="1",
                                   assigned_a={"types": ["scale"], "value": ["Score"]}),
                     "run 4 (reset: plain list only, host A=1)")
z4 = zoo_rows(zres4)
a4z = find(z4, "assigned-list")
check("zoo run 4: assignedA Score on slice 1 (12.50)",
      len(a4z) == 1 and "12.50" in a4z[0]["values"] and str(a4z[0]["slice"]) == "1", json.dumps(a4z))

# --- zoo run 5: mid-session host switch (delta run: only the host option changes) -----------------
# NB: the value IS re-sent (same terms as run 4) - analysis_run options are a delta, but the
# point here is the RE-ENCODE through the NEW host namespace, which only happens when the option
# is part of the run (an untouched option keeps its already-encoded value). The zoo's primary
# slice (the analysis' own dataset) is queued besides the sidecar, so only "no dataset beyond
# the workspace's two" can be asserted here - the sharp claim is the row: Score must now resolve
# in slice 2 (17.73), i.e. the restamp walk + sidecar followed host A to DataSet 2.
zr5, zres5 = zoo_run(zoo_full_opts(host_a="2",
                                   assigned_a={"types": ["scale"], "value": ["Score"]}),
                     "run 5 (mid-session switch host A -> filter 2)")
z5 = zoo_rows(zres5)
a5z = find(z5, "assigned-list")
check("zoo run 5: mid-session switch re-encoded the value to slice 2 (17.73)",
      len(a5z) == 1 and str(a5z[0]["slice"]) == "2" and "17.73" in a5z[0]["values"], json.dumps(a5z))
check("zoo run 5: slice 2 queued, nothing beyond the workspace's two datasets",
      "2" in (zoo_slice_ids(zres5) or []) and set(zoo_slice_ids(zres5) or []) <= {"1", "2"}, str(zoo_slice_ids(zres5)))
check("zoo run 5: dataSetIds covers DataSet 2 and nothing else",
      2 in zr5.get("dataSetIds", []) and set(zr5.get("dataSetIds", [])) <= {1, 2}, str(zr5.get("dataSetIds")))
auditz5 = provenance_audit(zres5)
check("zoo run 5: PROVENANCE_AUDIT clean after the switch", auditz5 == ("false", "0"), str(auditz5))

# --- zoo run 6: and back ---------------------------------------------------------------------------
zr6, zres6 = zoo_run(zoo_full_opts(host_a="1",
                                   assigned_a={"types": ["scale"], "value": ["Score"]}),
                     "run 6 (switch back host A -> filter 1)")
z6 = zoo_rows(zres6)
a6z = find(z6, "assigned-list")
check("zoo run 6: switched back, Score resolves in slice 1 again (12.50)",
      len(a6z) == 1 and str(a6z[0]["slice"]) == "1" and "12.50" in a6z[0]["values"], json.dumps(a6z))

# --- zoo runs 7/8 (D6.2): the cross-host typed copy against live host switches ---------------------
# run 7: source host A on filter 2, destination host G on filter 1; assignedA binds unqualified
# (intake stamps it @2) and boundG receives the typed copy Score@2. Both values must resolve in
# slice 2 - the copy through its SOURCE stamp, not through its own host's filter 1.
zr7, zres7 = zoo_run(zoo_full_opts(
    host_a="2", host_g="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    bound_g={"value": [{"name": "Score", "types": ["scale"], "filterId": 2}]}), "run 7 (D6.2: copy @2, dest host on 1)")
z7 = zoo_rows(zres7)
a7z = find(z7, "assigned-list")
bg7 = find(z7, "bindto-cross-host")
check("zoo run 7: assignedA (own host A=2) resolves in slice 2 (17.73)",
      len(a7z) == 1 and str(a7z[0]["slice"]) == "2" and "17.73" in a7z[0]["values"], json.dumps(a7z))
check("zoo run 7: boundG typed copy keeps the SOURCE stamp: slice 2 (17.73) although its own host G=1",
      len(bg7) == 1 and str(bg7[0]["slice"]) == "2" and "17.73" in bg7[0]["values"], json.dumps(bg7))
check("zoo run 7: dataSetIds covers source (ds2) and destination host (ds1)", sorted(zr7.get("dataSetIds", [])) == [1, 2], str(zr7.get("dataSetIds")))
auditz7 = provenance_audit(zres7)
check("zoo run 7: PROVENANCE_AUDIT clean", auditz7 == ("false", "0"), str(auditz7))

# run 8: switch the SOURCE host A back to filter 1 (delta run: boundG is NOT re-sent, its typed
# term state carries the foreign stamp 2). The owns-the-stamp rule (D3.5) must restamp ONLY the
# host-owned term: assignedA follows A to slice 1, boundG stays on the SOURCE stamp @2 - the copy
# is a stable stamp, not a live reference; requalification to the (now matching) filter 1 would
# show up as 12.50 and fail here.
zr8, zres8 = zoo_run({"dataSetA": "1", "showMeta": True}, "run 8 (D6.2: source host switched, copy not re-sent)")
z8 = zoo_rows(zres8)
a8z = find(z8, "assigned-list")
bg8 = find(z8, "bindto-cross-host")
check("zoo run 8: assignedA followed its OWN host to slice 1 (12.50)",
      len(a8z) == 1 and str(a8z[0]["slice"]) == "1" and "12.50" in a8z[0]["values"], json.dumps(a8z))
check("zoo run 8: boundG foreign stamp NOT requalified by the source-host switch (still slice 2, 17.73)",
      len(bg8) == 1 and str(bg8[0]["slice"]) == "2" and "17.73" in bg8[0]["values"], json.dumps(bg8))
auditz8 = provenance_audit(zres8)
check("zoo run 8: PROVENANCE_AUDIT clean", auditz8 == ("false", "0"), str(auditz8))

print("\n" + ("ALL CHECKS PASSED" if not fails else f"{len(fails)} FAILURES: {fails}"))
sys.exit(0 if not fails else 1)
