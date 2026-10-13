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
  - the .meta dump shows per-form provenance (dependentA ds1/f1, dependentB ds2/f2)
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

import sys, json, time, re as _re

A_CSV = "/home/virtuoos/Broncode/JASP/jaspTestModule/Tools/testdata/DataSetA.csv"
B_CSV = "/home/virtuoos/Broncode/JASP/jaspTestModule/Tools/testdata/DataSetB.csv"

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

# T3c: per-form provenance as the engine SAW it - options$.meta must stamp each control with
# ITS OWN form's dataset/filter (showMeta is on), not one global analysis filter.
meta_text = json.dumps(results).replace(chr(92)+chr(34), '"').replace("&quot;", '"').replace("&#34;", '"')
def meta_of(opt):
    i = meta_text.find(f'"{opt}"')
    while i != -1:
        window = meta_text[i:i + 400]
        if "dataSetId" in window and "filterId" in window:
            m_ds = _re.search(r'"dataSetId":\s*"?(-?\d+)', window)
            m_fl = _re.search(r'"filterId":\s*"?(-?\d+)', window)
            if m_ds and m_fl:
                return m_ds.group(1), m_fl.group(1)
        i = meta_text.find(f'"{opt}"', i + 1)
    return None
check("meta.dependentA stamped with form A's dataset/filter (1/1)", meta_of("dependentA") == ("1", "1"), str(meta_of("dependentA")))
check("meta.dependentB stamped with form B's dataset/filter (2/2)", meta_of("dependentB") == ("2", "2"), str(meta_of("dependentB")))

# ----------------------------------------------------------------------------
# C3/VERIFY-live (mds-plan C3/M5): the phantom-slice class. Switch ONE HOST'S SELECTION
# mid-session and check the NEXT run's data shows only the LIVE selections: no slice queued
# for an abandoned filter, no stale filterId stamp left in the options .meta. Scalars and the
# selection options themselves carry no provenance at all now - only column-bearing values do
# (BoundControlBase::createMeta gate), and a switching host restamps those (HostFilterSelection
# ::restampValuesUnderHost). This RPC workspace has one (default) filter per dataset, so the
# mid-session switch here crosses datasets (form A: f1 -> f2 -> f1); the sharp same-dataset/
# other-filter case - where no encoded value changes and only the restamp walk can keep .meta
# honest - is pinned C++/QML-side by
# Tests/qmlTests/tst_dataSetSelectionVariablesForm.qml::test_midsession_switch_restamps_column_values.
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

def meta_window(res, opt):
    """(dataSetId, filterId) of opt's .meta entry as the engine saw it (metaDump), or None."""
    text = json.dumps(res).replace(chr(92) + chr(34), '"').replace("&quot;", '"').replace("&#34;", '"')
    i = text.find(f'"{opt}"')
    while i != -1:
        window = text[i:i + 400]
        if "dataSetId" in window and "filterId" in window:
            m_ds = _re.search(r'"dataSetId":\s*"?(-?\d+)', window)
            m_fl = _re.search(r'"filterId":\s*"?(-?\d+)', window)
            if m_ds and m_fl:
                return m_ds.group(1), m_fl.group(1)
        i = text.find(f'"{opt}"', i + 1)
    return None

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
check("run 3: dependentA restamped onto the live selection (2/2)", meta_window(res3, "dependentA") == ("2", "2"), str(meta_window(res3, "dependentA")))
check("run 3: scalar showMeta carries no provenance", meta_window(res3, "showMeta") is None, str(meta_window(res3, "showMeta")))
check("run 3: scalar guardDemo carries no provenance", meta_window(res3, "guardDemo") is None, str(meta_window(res3, "guardDemo")))
check("run 3: selection option dataSetA carries no provenance", meta_window(res3, "dataSetA") is None, str(meta_window(res3, "dataSetA")))

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
check("run 4: dependentA restamped back onto filter 1 (1/1)", meta_window(res4, "dependentA") == ("1", "1"), str(meta_window(res4, "dependentA")))
a4 = None
sv4 = next((t for t in tables(res4.get("results", res4)).values() if t.get("title") == "Selected variables"), None)
if sv4:
    f4, fm4, rk4 = field_maps(sv4)
    a4 = next((x for x in ({f: fm4[f].get(r) for f in f4} for r in rk4) if x["source"] == "A" and x["variable"] == "Score"), None)
check("run 4: A:Score back on DataSet 1 (mean 12.50)", a4 and str(a4["dataSetId"]) == "1" and "12.50" in str(a4["values"]), json.dumps(a4))

print("\n" + ("ALL CHECKS PASSED" if not fails else f"{len(fails)} FAILURES: {fails}"))
sys.exit(0 if not fails else 1)
