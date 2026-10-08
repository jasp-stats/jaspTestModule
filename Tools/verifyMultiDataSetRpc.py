#!/usr/bin/env python3
"""Verify jaspTestModule::multiDataSetFunc end-to-end through JASP's RPC server.

Precondition: JASP (dev build) already running offscreen with RPC enabled, NO datasets.
Steps: load DataSetA + DataSetB (2 datasets in the workspace), create the multi-dataset
test analysis, bind dependentA to a column of dataset 1 and dependentB to a column that
exists in BOTH datasets plus one that exists only in dataset 2, run, fetch results and
assert:
  - 'Datasets in this run' has 2 rows with titles + row/col counts
  - 'Selected variables' rows have n=10 and mean/levels values (not empty, not JASPColumn_*)
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

import sys, json, time

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

# bind form A's variable while the analysis runs on dataset 1 (filter 1)
print(call("analysis_setFilter", {"analysisId": aid, "filterId": 1}).get("status"))
r1 = call("analysis_run", {"analysisId": aid, "wait": True, "timeoutMs": 60000, "options": {
    "dependentA": {"types": [], "value": ["Score"]}}})
check("first run (dependentA=Score @dataset1) complete", r1.get("status") == "complete",
      str(r1.get("status")))

# switch to dataset 2 and add form B's variables: dependentA is unchanged so its ds1
# provenance survives the rebind (BoundControlBase::setBoundValue early-returns)
print(call("analysis_setFilter", {"analysisId": aid, "filterId": 2}).get("status"))
r2 = call("analysis_run", {"analysisId": aid, "wait": True, "timeoutMs": 120000, "options": {
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
    """jaspBase json: data[i] is a {rowKey: value} map for schema field i."""
    fields = [f["name"] for f in t["schema"]["fields"]]
    rowkeys = set()
    for entry in t["data"]:
        for key, val in entry.items():
            if val is not None and key not in fields:
                rowkeys.add(key)
    return fields, {f: t["data"][i] for i, f in enumerate(fields)}, sorted(rowkeys)

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
    check("decoded names, no raw JASPColumn_*", "JASPColumn" not in dump, dump[:300])

check("analysis references both datasets (dataSetIds in run response)", sorted(r2.get("dataSetIds", [])) == [1, 2], str(r2.get("dataSetIds")))

print("\n" + ("ALL CHECKS PASSED" if not fails else f"{len(fails)} FAILURES: {fails}"))
sys.exit(0 if not fails else 1)
