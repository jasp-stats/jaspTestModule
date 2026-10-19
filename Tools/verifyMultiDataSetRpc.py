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
                  host_j="", host_k="",
                  assigned_a=None, assigned_b=None, assigned_k=None, rows_c=None, bound_g=None,
                  interaction_d=None, factors_e=None, factors_k=None, pairs_j=None, code_f=None,
                  combo_a="", combo_i="", text_h="", rows_h=5, double_h=1.5, slider_h=0.5,
                  radio_h="mean", gate_h=False, gated_h=10.0, table_l=None,
                  plain_switch=False, show_meta=True):
    opts = {
        "dataSetA": host_a, "dataSetB": host_b, "dataSetC": host_c,
        "dataSetD": host_d, "dataSetF": host_f, "dataSetG": host_g,
        "dataSetJ": host_j, "dataSetK": host_k,
        "assignedA": assigned_a or dict(EMPTY_TERMS),
        "assignedB": assigned_b or dict(EMPTY_TERMS),
        "assignedK": assigned_k or dict(EMPTY_TERMS),
        "rowsC":     rows_c or dict(EMPTY_ROWS),
        "boundG":    bound_g or {"value": []},
        "interactionD": interaction_d or dict(EMPTY_INTER),
        "factorsE":  factors_e or [],
        "factorsK":  factors_k or [],
        "pairsJ":    pairs_j or dict(EMPTY_TERMS),
        "codeF":     code_f or dict(EMPTY_CODEF),
        "comboA": combo_a, "comboI": combo_i, "comboG": "first",
        "textH": text_h, "rowsH": rows_h, "doubleH": double_h, "sliderH": slider_h,
        "radioH": radio_h, "gateH": gate_h, "gatedH": gated_h,
        "plainSwitch": plain_switch,
    }
    if table_l is not None:
        opts["tableL"] = table_l
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

# combobox (Zoo A): plain string value. NB the namespace finding, UPDATED by the mds-zoo
# expansion: comboA's `source` used to be a broken QML binding (`source: zooVarsA` - a bare
# identifier that does not exist; ReferenceError in the runtime log), so the dropdown silently
# had no option list and its value encoded through the analysis-level namespace. With the source
# fixed to the string-name form ("zooVarsA") a dropdown INHERITS ITS SOURCE's host namespace:
# the value now encodes through zooVarsA's host (dataSetA). Run 9 pins that strictly; this
# legacy check keeps its tolerance (the value stays plain and roundtrips either way).
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

# ----------------------------------------------------------------------------
# mds-zoo expansion - the NEW control families (Zoo H-L), the RESULTS side and
# the option flows. The point of the expansion: data and flows must be VISIBLE
# and the verifier must assert RESULTS-SIDE content, not just option roundtrips.
#
# Results inventory asserted below:
#   "Loaded data - <title> (slice <key>...)"  the actual loaded DATA per slice:
#       every column's decoded name AND its first `rowsH` values (head per slice)
#   "Controls provenance"        extended with the new families
#   "Scalar & simple control echoes"  scalar families as received + used-in
#   "Option flows"               the flow demonstrations
#   "Cross-slice computations"   computations across slices/lists of different provenance
#   "encodeThis recode demo"     Zoo E's levels APPLIED to a real column
#   "Gated sub-result"           EXISTS ONLY while gateH is on (a gate means absence)
#
# Flows (trigger -> effect, each verified by a delta run + results-side diff):
#   F1 assignedA content  -> comboI's option list & effective selection (dependent dropdown)
#   F2 gateH checkbox     -> the gated sub-result exists / vanishes; gatedH shifts its numbers
#   F3 rowsH integer      -> preview row count AND Zoo L's table row count
#   F4 interactionD terms -> the interaction-product rows of the cross-slice table
#   F5 tableL cells       -> the multiplier statistic (cells are USED, not just echoed)
#   F6 radioH             -> the radio-driven statistic (sum vs mean)
#
# Expected statistics are computed from the same CSVs the datasets load, so the
# assertions are value-level. Slice column composition follows from the stamped
# namespaces (each asserted row documents where its term was stamped).
# ----------------------------------------------------------------------------

import csv as _csvmod

def _read_columns(path):
    with open(path) as f:
        rows = list(_csvmod.DictReader(f))
    cols = {}
    for k in rows[0].keys():
        vals = [r[k] for r in rows]
        try:
            cols[k] = [float(v) for v in vals]
        except ValueError:
            cols[k] = vals
    return cols

A = _read_columns(A_CSV)
B = _read_columns(B_CSV)

def fmt(x, nd=2): return f"{x:.{nd}f}"
def mean(v): return sum(v) / len(v)

# the analysis-level namespace of a fresh RPC session: the SHOWN dataset is the last loaded one
# (DataSet 2, filter 2) - hostless panels (the FactorsForm's) stamp there.
ANALYSIS_SLICE = "2"

def find_table(res, title_prefix):
    return next((t for t in tables(res.get("results", res)).values()
                 if str(t.get("title", "")).startswith(title_prefix)), None)

import html as _htmlmod

def table_rows(t):
    if not t: return []
    fields, fm, rks = field_maps(t)
    # jaspBase HTML-escapes string cells ("->" arrives as "-&gt;"); unescape for assertions
    return [{f: _htmlmod.unescape(str(fm[f].get(r))) if isinstance(fm[f].get(r), str) else fm[f].get(r)
             for f in fields} for r in rks]

def no_raw_tokens(res, tag):
    raw = json.dumps(res)
    check(f"{tag}: no raw JASPColumn_* in results", "JASPColumn" not in raw)
    check(f"{tag}: no raw JaspExtraOptions_* in results", "JaspExtraOptions" not in raw)

# --- zoo run 9: the expanded zoo, all new families populated --------------------------------------
# Provenance story (fresh RPC session, shown dataset = DataSet 2):
#   assignedA Score via host A(1) -> slice 1 | assignedB Score via host B(2) -> slice 2
#   assignedK Group+Age via host K(1) -> slice 1 (Group feeds the encodeThis demo, Age is the
#   factor term's source) | pairsJ Score+Age via host J(1) -> slice 1
#   interactionD Score:Age via host D(1) -> slice 1 | factorsK Age -> hostless panel ->
#   ANALYSIS-level namespace (slice 2) - the D3.2 deferral, pinned as behaviour
zr9, zres9 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_b={"types": ["scale"], "value": ["Score"]},
    # NB: the FactorsForm's factors can only hold terms that are in its SOURCE list (assignedK):
    # a term outside the source is silently dropped by the form's model sync (verified live, run
    # 9 originally sent Age here while assignedK held only Group -> "(none)"). Group is needed in
    # the slice for the encodeThis demo, Age for the factor term, so the source carries both.
    assigned_k={"types": ["nominal", "scale"], "value": ["Group", "Age"]},
    interaction_d={"types": [["scale", "scale"]], "value": [{"components": ["Score", "Age"]}], "optionKey": "components"},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    factors_k=[{"name": "Fac1", "title": "Factor 1", "indicators": {"value": ["Age"], "types": [["scale"]]}}],
    pairs_j={"types": ["scale", "scale"], "value": ["Score", "Age"]},
    combo_a="Score", combo_i="Score", text_h="hello zoo", rows_h=4, double_h=2.0, slider_h=0.3,
    radio_h="sum", gate_h=True, gated_h=12.0), "run 9 (expanded zoo: all new families)")

z9 = zoo_rows(zres9)
check("zoo run 9: provenance table present", z9 is not None)

# (a) THE LOADED DATA - per-slice previews with real column names and values
pv1 = find_table(zres9, "Loaded data - DataSet 1")
pv2 = find_table(zres9, "Loaded data - DataSet 2")
check("zoo run 9: loaded-data preview for slice 1 present", pv1 is not None,
      str([t.get('title') for t in tables(zres9.get('results', zres9)).values()]))
check("zoo run 9: loaded-data preview for slice 2 present", pv2 is not None)
if pv1 and pv2:
    check("zoo run 9: preview titles say 'first 4 rows' (rowsH flow)",
          "first 4 rows" in pv1["title"] and "first 4 rows" in pv2["title"],
          f"{pv1['title']!r} / {pv2['title']!r}")
    r1, r2 = table_rows(pv1), table_rows(pv2)
    check("zoo run 9: preview row count == rowsH (4)", len(r1) == 4 and len(r2) == 4,
          f"{len(r1)}/{len(r2)}")
    # values: slice 1 is DataSetA, slice 2 is DataSetB - the whole point
    check("zoo run 9: slice 1 shows DataSetA's Score values (12.5, 9.1, ...)",
          any(abs((row.get("Score") or -999) - A["Score"][i]) < 1e-9 for i, row in enumerate(r1)),
          json.dumps(r1)[:200])
    check("zoo run 9: slice 2 shows DataSetB's Score values (22.4, 14.8, ...) - NOT a repeat of A",
          any(abs((row.get("Score") or -999) - B["Score"][i]) < 1e-9 for i, row in enumerate(r2)),
          json.dumps(r2)[:200])
    check("zoo run 9: slice 1 shows the Group levels (nominal values, not numbers)",
          any(row.get("Group") in ("A", "B", "C") for row in r1), json.dumps(r1)[:200])
    check("zoo run 9: previews carry decoded names, no raw tokens (fields)",
          all("JASPColumn" not in f for f in [f["name"] for f in pv1["schema"]["fields"]] +
              [f["name"] for f in pv2["schema"]["fields"]]))

# (b) per-family provenance echoes for the new families
dep = find(z9, "dropdown-dependent")
check("zoo run 9: dependent dropdown comboI='Score' resolves in slice 1 via its SOURCE host (12.50)",
      len(dep) == 1 and dep[0]["received"] == "Score" and str(dep[0]["slice"]) == "1" and "12.50" in dep[0]["values"],
      json.dumps(dep))
ca9 = find(z9, "combobox-host")
check("zoo run 9: comboA (fixed source binding) encodes through its SOURCE host namespace -> slice 1",
      len(ca9) == 1 and str(ca9[0]["slice"]) == "1" and "12.50" in ca9[0]["values"], json.dumps(ca9))

pj = find(z9, "pairs-list")
check("zoo run 9: pairsJ one PAIR 'Score + Age', both components in slice 1 (host J)",
      len(pj) == 1 and pj[0]["received"] == "Score + Age" and str(pj[0]["slice"]) == "1", json.dumps(pj))
import statistics as _stats
_r = _stats.correlation(A["Score"], A["Age"])
check("zoo run 9: pairsJ echo computes the pair correlation r=%.3f" % _r,
      len(pj) == 1 and f"r = {fmt(_r, 3)}" in str(pj[0]["values"]), json.dumps(pj))

fk = find(z9, "factors-form")
check("zoo run 9: factorsK Fac1 received with title and var Age",
      len(fk) == 1 and fk[0]["received"] == "Fac1" and "title=Factor 1" in fk[0]["rowChild"]
      and "Age" in fk[0]["rowChild"], json.dumps(fk))
check("zoo run 9: factorsK var Age resolves in the ANALYSIS-level namespace (slice 2) - the D3.2 hostless-panel deferral",
      len(fk) == 1 and str(fk[0]["slice"]) == ANALYSIS_SLICE and "slices: 2" in str(fk[0]["values"]), json.dumps(fk))

fs = [r for r in z9 if r["family"] == "factors-source" and r["received"] == "Group"]
check("zoo run 9: assignedK Group (the factor SOURCE) resolves in ITS OWN host's slice 1 with levels",
      len(fs) == 1 and str(fs[0]["slice"]) == "1" and fs[0]["values"].startswith("A, B, C"), json.dumps(fs))
fs_age = [r for r in z9 if r["family"] == "factors-source" and r["received"] == "Age"]
check("zoo run 9: assignedK Age (second source var) resolves in slice 1 with its values (31, 45, ...)",
      len(fs_age) == 1 and str(fs_age[0]["slice"]) == "1" and str(fs_age[0]["values"]).startswith("31, 45, 28"),
      json.dumps(fs_age))

tv = find(z9, "tableview")
check("zoo run 9: tableL echo '4 rows x 2 cols' (row count follows rowsH=4 via the QML binding)",
      len(tv) == 1 and "4 rows x 2 cols" in tv[0]["received"], json.dumps(tv))

# (c) scalar echoes
se = table_rows(find_table(zres9, "Scalar & simple control echoes"))
se_map = {r["option"]: r for r in se}
check("zoo run 9: scalar echo table has all 7 scalar families",
      set(se_map) == {"textH", "rowsH", "doubleH", "sliderH", "radioH", "gateH", "gatedH"}, str(sorted(se_map)))
check("zoo run 9: textH echoes verbatim", se_map.get("textH", {}).get("received") == "hello zoo", json.dumps(se))
check("zoo run 9: rowsH/doubleH/sliderH/radioH echo as received",
      se_map.get("rowsH", {}).get("received") == "4" and abs(float(se_map.get("doubleH", {}).get("received") or 0) - 2.0) < 1e-9
      and se_map.get("sliderH", {}).get("received") == "0.3" and se_map.get("radioH", {}).get("received") == "sum",
      json.dumps([se_map.get(k) for k in ("rowsH", "doubleH", "sliderH", "radioH")]))
check("zoo run 9: gateH true and gatedH annotated 'gate OPEN'",
      se_map.get("gateH", {}).get("received") == "TRUE" and "gate OPEN" in str(se_map.get("gatedH", {}).get("received")),
      json.dumps([se_map.get("gateH"), se_map.get("gatedH")]))

# (d) flows table
fl = table_rows(find_table(zres9, "Option flows"))
fl_map = {r["flow"]: r for r in fl}
check("zoo run 9: flows table has the 5 flow rows",
      set(fl_map) == {"dependent dropdown", "checkbox gate", "number field -> shown rows",
                      "radio -> statistic", "variables list -> interaction terms"}, str(sorted(fl_map)))
check("zoo run 9: dependent-dropdown flow observed 'Score -> slice 1'",
      '"Score" -> slice 1' in str(fl_map.get("dependent dropdown", {}).get("observed")), json.dumps(fl))
check("zoo run 9: gate flow observed OPEN", "gate OPEN" in str(fl_map.get("checkbox gate", {}).get("observed")), json.dumps(fl))
check("zoo run 9: rows flow observed rowsH=4, previews 4 rows, tableL 4 rows",
      "rowsH=4" in str(fl_map.get("number field -> shown rows", {}).get("observed"))
      and "4 rows" in str(fl_map.get("number field -> shown rows", {}).get("observed")), json.dumps(fl))

# (e) cross-slice computations - value-level, computed from the CSVs
cs = table_rows(find_table(zres9, "Cross-slice computations"))
cs_map = {r["computation"]: r for r in cs}
_exp_prod = mean([a * b for a, b in zip(A["Score"], A["Age"])])
check("zoo run 9: interaction product mean(Score*Age) in slice 1 = %s" % fmt(_exp_prod, 3),
      f"mean of product {fmt(_exp_prod, 3)}" in str(cs_map.get("interaction product", {}).get("value")), json.dumps(cs))
_exp_cross = mean([a * b for a, b in zip(A["Score"], B["Score"])])
check("zoo run 9: cross-host product Score@1 x Score@2 = %s (two different truths, one number)" % fmt(_exp_cross, 3),
      f"mean of product {fmt(_exp_cross, 3)}" in str(cs_map.get("cross-host column product", {}).get("value"))
      and "DataSet 1" in str(cs_map.get("cross-host column product", {}).get("inputs"))
      and "DataSet 2" in str(cs_map.get("cross-host column product", {}).get("inputs")), json.dumps(cs))
# slice 1's first numeric column is Age (wanted-cols are set-sorted): Age mean 38.00
check("zoo run 9: tableview multipliers mean([1,2,3,4])=2.5 x mean(Age@1)=38.00 -> 95.000",
      "scaled mean 95.000" in str(cs_map.get("tableview multipliers", {}).get("value")), json.dumps(cs))
check("zoo run 9: doubleH=2.0 scaling -> 76.000", "scaled mean 76.000" in str(cs_map.get("real-field scaling", {}).get("value")), json.dumps(cs))
check("zoo run 9: radio-driven statistic sum(Score@1) = 125.00",
      "sum 125.00" in str(cs_map.get("radio-driven statistic", {}).get("value")), json.dumps(cs))

# (f) encodeThis recode demo: factorsE levels APPLIED to the Group column of slice 1
ed = table_rows(find_table(zres9, "encodeThis recode demo"))
ed_map = {r["oldValue"]: r for r in ed}
check("zoo run 9: encodeDemo decodes the extras factor name to 'Group' and finds it in slice 1",
      all(r["slice"] == "1" for r in ed) and len(ed) == 3, json.dumps(ed))
check("zoo run 9: encodeDemo recode A->A (n=4), B->B (n=3), C->B (n=3) - levels applied in order, capped",
      ed_map.get("A", {}).get("newLabel") == "A" and ed_map.get("A", {}).get("n") == 4
      and ed_map.get("B", {}).get("newLabel") == "B" and ed_map.get("B", {}).get("n") == 3
      and ed_map.get("C", {}).get("newLabel") == "B" and ed_map.get("C", {}).get("n") == 3, json.dumps(ed))

# (g) gated sub-result EXISTS while the gate is open; first numeric column of each slice is Age
g9 = table_rows(find_table(zres9, "Gated sub-result"))
def _gated_map(g):
    # slice cell is "1 (DataSet 1)"; meanAbove arrives as a number
    return {(str(r["slice"]).split(" ")[0], r["column"]): r for r in g}

# (g) gated sub-result EXISTS while the gate is open. "First scale column" per slice:
#     slice 1's is Age (scale); slice 2's factor-term Age arrives ORDINAL (the FactorsForm
#     re-types its terms - documented finding) hence as an R factor, so firstScaleColumn
#     picks Score there. Both deterministic.
g9_map = _gated_map(g9)
check("zoo run 9: gated sub-result present with threshold 12 in the title",
      find_table(zres9, "Gated sub-result") is not None
      and "12" in find_table(zres9, "Gated sub-result")["title"], json.dumps(g9))
check("zoo run 9: gated Age@1: all 10 rows above 12 (mean 38.00)",
      g9_map.get(("1", "Age"), {}).get("nAbove") == 10
      and abs((g9_map.get(("1", "Age"), {}).get("meanAbove") or -999) - mean(A["Age"])) < 5e-3, json.dumps(g9))
check("zoo run 9: gated Score@2 (factor-term Age arrives ordinal/factor, skipped): n=8 mean 19.45",
      g9_map.get(("2", "Score"), {}).get("nAbove") == 8
      and abs((g9_map.get(("2", "Score"), {}).get("meanAbove") or -999) - mean([s for s in B["Score"] if s > 12])) < 5e-3,
      json.dumps(g9))

check("zoo run 9: dataSetIds covers both datasets", sorted(zr9.get("dataSetIds", [])) == [1, 2], str(zr9.get("dataSetIds")))
auditz9 = provenance_audit(zres9)
check("zoo run 9: PROVENANCE_AUDIT clean (C8/C11)", auditz9 == ("false", "0"), str(auditz9))
no_raw_tokens(zres9, "zoo run 9")

# --- zoo run 10 (FLOW F1): the dependent dropdown follows its source -------------------------------
# assignedA flips to Condition (host A=2): comboI's option list must follow, its effective
# selection re-encodes through the source's NEW namespace (slice 2), and the RESULTS change.
zr10, zres10 = zoo_run(zoo_full_opts(
    host_a="2", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["nominal"], "value": ["Condition"]},
    assigned_k={"types": ["nominal"], "value": ["Group"]},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    combo_i="Condition", text_h="hello zoo", rows_h=4, double_h=2.0, slider_h=0.3,
    radio_h="sum", gate_h=True, gated_h=12.0), "run 10 (F1: dependent dropdown follows reassigned source)")
z10 = zoo_rows(zres10)
dep10 = find(z10, "dropdown-dependent")
check("zoo run 10: comboI='Condition' received (option list followed assignedA)",
      len(dep10) == 1 and dep10[0]["received"] == "Condition", json.dumps(dep10))
check("zoo run 10: comboI resolves in the source's NEW namespace (slice 2, levels X, Y, Z)",
      len(dep10) == 1 and str(dep10[0]["slice"]) == "2" and str(dep10[0]["values"]).startswith("X, Y, Z"), json.dumps(dep10))
fl10 = {r["flow"]: r for r in table_rows(find_table(zres10, "Option flows"))}
check("zoo run 10: flow row observed the flipped source list and selection",
      "[Condition]" in str(fl10.get("dependent dropdown", {}).get("observed"))
      and '"Condition" -> slice 2' in str(fl10.get("dependent dropdown", {}).get("observed")), json.dumps(fl10))
auditz10 = provenance_audit(zres10)
check("zoo run 10: PROVENANCE_AUDIT clean", auditz10 == ("false", "0"), str(auditz10))
no_raw_tokens(zres10, "zoo run 10")

# --- zoo run 11 (FLOW F2a): gate closed -> the gated sub-result must NOT exist ---------------------
zr11, zres11 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_k={"types": ["nominal"], "value": ["Group"]},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    combo_a="Score", combo_i="Score", text_h="hello zoo", rows_h=4, double_h=2.0, slider_h=0.3,
    radio_h="sum", gate_h=False, gated_h=12.0), "run 11 (F2a: gate closed)")
check("zoo run 11: NO 'Gated sub-result' table while gateH is off (a gate means absence)",
      find_table(zres11, "Gated sub-result") is None,
      str([t.get("title") for t in tables(zres11.get("results", zres11)).values()]))
se11 = {r["option"]: r for r in table_rows(find_table(zres11, "Scalar & simple control echoes"))}
check("zoo run 11: gatedH still RECEIVED but annotated 'gate closed'",
      "gate closed" in str(se11.get("gatedH", {}).get("received")), json.dumps(se11))
fl11 = {r["flow"]: r for r in table_rows(find_table(zres11, "Option flows"))}
check("zoo run 11: gate flow row says closed -> no gated sub-result",
      "gate closed" in str(fl11.get("checkbox gate", {}).get("observed")), json.dumps(fl11))
no_raw_tokens(zres11, "zoo run 11")

# --- zoo run 12 (FLOW F2b): gate open with a different threshold -> numbers move --------------------
zr12, zres12 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_k={"types": ["nominal", "scale"], "value": ["Group", "Age"]},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    factors_k=[{"name": "Fac1", "title": "Factor 1", "indicators": {"value": ["Age"], "types": [["scale"]]}}],
    combo_a="Score", combo_i="Score", text_h="hello zoo", rows_h=4, double_h=2.0, slider_h=0.3,
    radio_h="sum", gate_h=True, gated_h=40.0), "run 12 (F2b: gate open, threshold 40)")
g12 = table_rows(find_table(zres12, "Gated sub-result"))
g12_map = _gated_map(g12)
_a1_above = [a for a in A["Age"] if a > 40]
check("zoo run 12: threshold 40 in the title", "40" in find_table(zres12, "Gated sub-result")["title"], json.dumps(g12))
check("zoo run 12: gated Age@1 n=%d mean %s (threshold moved the numbers)" % (len(_a1_above), fmt(mean(_a1_above))),
      g12_map.get(("1", "Age"), {}).get("nAbove") == len(_a1_above)
      and abs((g12_map.get(("1", "Age"), {}).get("meanAbove") or -999) - mean(_a1_above)) < 5e-3, json.dumps(g12))
check("zoo run 12: NO slice-2 row (its factor-term Age arrives ordinal/factor; nothing numeric survives the threshold)",
      all(not str(r["slice"]).startswith("2") for r in g12), json.dumps(g12))
no_raw_tokens(zres12, "zoo run 12")

# --- zoo run 13/14 (FLOW F3): the integer field drives the shown row count --------------------------
zr13, zres13 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_k={"types": ["nominal"], "value": ["Group"]},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    combo_a="Score", combo_i="Score", text_h="hello zoo", rows_h=3, double_h=2.0, slider_h=0.3,
    radio_h="sum", gate_h=True, gated_h=12.0), "run 13 (F3: rowsH=3)")
pv13 = find_table(zres13, "Loaded data - DataSet 1")
check("zoo run 13: preview title says 'first 3 rows'", pv13 is not None and "first 3 rows" in pv13["title"],
      pv13["title"] if pv13 else None)
check("zoo run 13: preview DATA has 3 rows", pv13 is not None and len(table_rows(pv13)) == 3)
tv13 = find(z13 := zoo_rows(zres13), "tableview")
check("zoo run 13: Zoo L table shrank to 3 rows (the same integer drives it)",
      len(tv13) == 1 and "3 rows x 2 cols" in tv13[0]["received"], json.dumps(tv13))
fl13 = {r["flow"]: r for r in table_rows(find_table(zres13, "Option flows"))}
check("zoo run 13: rows flow observed rowsH=3", "rowsH=3" in str(fl13.get("number field -> shown rows", {}).get("observed")), json.dumps(fl13))
no_raw_tokens(zres13, "zoo run 13")

zr14, zres14 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_k={"types": ["nominal"], "value": ["Group"]},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    combo_a="Score", combo_i="Score", text_h="hello zoo", rows_h=7, double_h=2.0, slider_h=0.3,
    radio_h="sum", gate_h=True, gated_h=12.0), "run 14 (F3: rowsH=7)")
pv14 = find_table(zres14, "Loaded data - DataSet 1")
check("zoo run 14: preview back to 7 rows (both directions of the flow verified)",
      pv14 is not None and len(table_rows(pv14)) == 7 and "first 7 rows" in pv14["title"])
no_raw_tokens(zres14, "zoo run 14")

# --- zoo run 15 (FLOW F6): the radio group switches the statistic -----------------------------------
zr15, zres15 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_k={"types": ["nominal"], "value": ["Group"]},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    combo_a="Score", combo_i="Score", text_h="hello zoo", rows_h=4, double_h=2.0, slider_h=0.3,
    radio_h="mean", gate_h=True, gated_h=12.0), "run 15 (F6: radio -> mean)")
cs15 = {r["computation"]: r for r in table_rows(find_table(zres15, "Cross-slice computations"))}
check("zoo run 15: radio-driven statistic switched to mean(Score@1) = 12.50 (was sum 125.00 in run 9)",
      "mean 12.50" in str(cs15.get("radio-driven statistic", {}).get("value")), json.dumps(cs15))
se15 = {r["option"]: r for r in table_rows(find_table(zres15, "Scalar & simple control echoes"))}
check("zoo run 15: radioH echo shows 'mean'", se15.get("radioH", {}).get("received") == "mean", json.dumps(se15))
no_raw_tokens(zres15, "zoo run 15")

# --- zoo run 16 (FLOW F4): the variables list drives the interaction terms --------------------------
zr16, zres16 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_k={"types": ["nominal"], "value": ["Group"]},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    interaction_d={"types": [["scale"]], "value": [{"components": ["Score"]}], "optionKey": "components"},
    combo_a="Score", combo_i="Score", text_h="hello zoo", rows_h=4, double_h=2.0, slider_h=0.3,
    radio_h="sum", gate_h=True, gated_h=12.0), "run 16 (F4: interaction reduced to a single component)")
cs16 = table_rows(find_table(zres16, "Cross-slice computations"))
check("zoo run 16: interaction-product row GONE after the list changed (single-component terms make no product)",
      all(r["computation"] != "interaction product" for r in cs16), json.dumps(cs16))
itr16 = find(zoo_rows(zres16), "interaction-list")
check("zoo run 16: the provenance echo still shows the received term (order=1)",
      len(itr16) == 1 and "order=1" in itr16[0]["rowChild"], json.dumps(itr16))
fl16 = {r["flow"]: r for r in table_rows(find_table(zres16, "Option flows"))}
check("zoo run 16: flow row observed '1 term(s) received'",
      "1 term(s) received" in str(fl16.get("variables list -> interaction terms", {}).get("observed")), json.dumps(fl16))
no_raw_tokens(zres16, "zoo run 16")

# --- zoo run 17 (FLOW F5): tableL cells are USED, not just echoed ------------------------------------
zr17, zres17 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_k={"types": ["nominal"], "value": ["Group"]},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    combo_a="Score", combo_i="Score", text_h="hello zoo", rows_h=4, double_h=2.0, slider_h=0.3,
    radio_h="sum", gate_h=True, gated_h=12.0,
    table_l=[{"name": "Multiplier", "levels": ["r1", "r2", "r3", "r4"], "values": [2, 2, 2, 2]},
             {"name": "Offset",    "levels": ["r1", "r2", "r3", "r4"], "values": [0, 0, 0, 0]}]),
    "run 17 (F5: explicit tableL multipliers)")
tv17 = find(zoo_rows(zres17), "tableview")
check("zoo run 17: tableL echo shows the SENT cells (2, 2, 2, 2)",
      len(tv17) == 1 and "2, 2, 2, 2" in tv17[0]["rowChild"], json.dumps(tv17))
cs17 = {r["computation"]: r for r in table_rows(find_table(zres17, "Cross-slice computations"))}
check("zoo run 17: multiplier mean 2.00 x mean(Age@1)=38.00 -> scaled mean 76.000 (cells entered the computation)",
      "scaled mean 76.000" in str(cs17.get("tableview multipliers", {}).get("value")), json.dumps(cs17))
no_raw_tokens(zres17, "zoo run 17")

# --- zoo run 18 (REGRESSION, mds-plan post): nominal factor term in a namespace lacking the column --
# Pre-fix this FATALed the whole run (rbridge_readDataSetRequested: "gets 'Group.nominal' but its
# not a columnname at all"): the FactorsForm panel is hostless, its term stamps at the ANALYSIS
# level (DataSet 2, which has no Group), and the collector queued a column that dataset does not
# have. The collector now refuses to queue nonexistent columns; the run must complete with an
# honest unresolved row.
zr18, zres18 = zoo_run(zoo_full_opts(
    host_a="1", host_b="2", host_d="1", host_f="1", host_g="2", host_j="1", host_k="1",
    assigned_a={"types": ["scale"], "value": ["Score"]},
    assigned_k={"types": ["nominal"], "value": ["Group"]},
    factors_e=[{"name": "Group", "levels": ["A", "B"]}],
    factors_k=[{"name": "Fac1", "title": "Factor 1", "indicators": {"value": ["Group"], "types": [["nominal"]]}}],
    combo_a="Score", combo_i="Score", text_h="hello zoo", rows_h=4, double_h=2.0, slider_h=0.3,
    radio_h="sum", gate_h=True, gated_h=12.0), "run 18 (regression: nominal factor term, namespace lacks the column)")
check("zoo run 18: the previously-fatal run COMPLETES", zr18.get("status") == "complete", str(zr18.get("status")))
fk18 = find(zoo_rows(zres18), "factors-form")
check("zoo run 18: the factor's Group term arrives unresolved (honest '-' row, no phantom resolution)",
      len(fk18) == 1 and "Group" in fk18[0]["rowChild"] and str(fk18[0]["slice"]) == "-", json.dumps(fk18))
auditz18 = provenance_audit(zres18)
check("zoo run 18: PROVENANCE_AUDIT clean after the regression case", auditz18 == ("false", "0"), str(auditz18))
no_raw_tokens(zres18, "zoo run 18")

print("\n" + ("ALL CHECKS PASSED" if not fails else f"{len(fails)} FAILURES: {fails}"))
sys.exit(0 if not fails else 1)
