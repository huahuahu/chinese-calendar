#!/usr/bin/env python3
"""Read-only SQLite audit for schema 1.3.0; optionally compare queries with a 1.2.0 store."""
import argparse
import json
import sqlite3
import statistics
import time
from pathlib import Path

RELATIONS = [
    ("ZCHINESELUNARDAY", "ZCHINESELUNARMONTH", "ZCHINESELUNARMONTH"),
    ("ZCHINESELUNARDAY", "ZCALENDARDAY", "ZCALENDARDAY"),
    ("ZCHINESELUNARMONTH", "ZCHINESELUNARYEAR", "ZCHINESELUNARYEAR"),
    ("ZORTHODOXBOUNDARY", "ZTRADITION", "ZORTHODOXTRADITION"),
    ("ZORTHODOXBOUNDARY", "ZDATE", "ZCHINESEDATEEXPRESSION"),
    ("ZORTHODOXPERIOD", "ZTRADITION", "ZORTHODOXTRADITION"),
    ("ZORTHODOXPERIOD", "ZDYNASTY", "ZDYNASTY"),
    ("ZORTHODOXPERIOD", "ZSTARTBOUNDARY", "ZORTHODOXBOUNDARY"),
    ("ZORTHODOXPERIOD", "ZENDBOUNDARY", "ZORTHODOXBOUNDARY"),
]
REMOVED = {
    "ZCHINESELUNARDAY": ["ZLUNARMONTHINDEX"],
    "ZCHINESELUNARMONTH": ["ZLUNARYEARNUMBER"],
    "ZORTHODOXBOUNDARY": ["ZTRADITIONID", "ZDATEEXPRESSIONID"],
    "ZORTHODOXPERIOD": ["ZTRADITIONID", "ZDYNASTYID", "ZSTARTBOUNDARYID", "ZENDBOUNDARYID"],
}
ID_MODELS = ["Dynasty", "ChineseDateExpression", "OrthodoxTradition", "OrthodoxBoundary",
             "OrthodoxPeriod", "Emperor", "EmperorReignSegment", "ReignEra"]


def connect(path):
    return sqlite3.connect(Path(path).resolve().as_uri() + "?mode=ro", uri=True)


def scalar(connection, sql):
    return connection.execute(sql).fetchone()[0]


def indexes(connection, table):
    return [{"unique": bool(row[2]), "columns": [r[2] for r in connection.execute(
        f'PRAGMA index_info("{row[1]}")')]} for row in connection.execute(f'PRAGMA index_list("{table}")')]


def audit(connection, legacy=False):
    assert scalar(connection, "PRAGMA integrity_check") == "ok"
    result = {"missingRelationships": {}, "idIndexes": {}}
    for source, column, target in RELATIONS:
        missing = scalar(connection, f"SELECT count(*) FROM {source} s LEFT JOIN {target} t "
                         f"ON s.{column}=t.Z_PK WHERE t.Z_PK IS NULL")
        result["missingRelationships"][f"{source}.{column}"] = missing
        assert missing == 0, (source, column, missing)
    for table, columns in REMOVED.items():
        stored = {row[1] for row in connection.execute(f"PRAGMA table_info({table})")}
        assert all((column in stored) == legacy for column in columns), (table, stored)
    for model in ID_MODELS:
        matches = [index for index in indexes(connection, "Z" + model.upper()) if index["columns"] == ["ZID"]]
        assert len(matches) == (2 if legacy else 1), (model, matches)
        assert any(index["unique"] for index in matches)
        result["idIndexes"][model] = matches
    for source, column, target in RELATIONS:
        old_key = {"ZCHINESELUNARMONTH": "ZLUNARMONTHINDEX", "ZCHINESELUNARYEAR": "ZLUNARYEARNUMBER",
                   "ZTRADITION": "ZTRADITIONID", "ZDATE": "ZDATEEXPRESSIONID", "ZDYNASTY": "ZDYNASTYID",
                   "ZSTARTBOUNDARY": "ZSTARTBOUNDARYID", "ZENDBOUNDARY": "ZENDBOUNDARYID"}.get(column)
        if legacy and old_key:
            target_key = old_key if column in ("ZCHINESELUNARMONTH", "ZCHINESELUNARYEAR") else "ZID"
            assert scalar(connection, f"SELECT count(*) FROM {source} s JOIN {target} t ON s.{column}=t.Z_PK "
                          f"WHERE s.{old_key} != t.{target_key}") == 0
    assert scalar(connection, "SELECT count(*) FROM ZORTHODOXPERIOD p JOIN ZORTHODOXBOUNDARY s ON "
                  "p.ZSTARTBOUNDARY=s.Z_PK JOIN ZORTHODOXBOUNDARY e ON p.ZENDBOUNDARY=e.Z_PK "
                  "WHERE p.ZTRADITION != s.ZTRADITION OR p.ZTRADITION != e.ZTRADITION") == 0
    assert scalar(connection, "SELECT count(*) FROM (SELECT 1 FROM ZCHINESELUNARDAY "
                  "GROUP BY ZCHINESELUNARMONTH,ZDAYNUMBERINMONTH HAVING count(*)>1)") == 0
    if not legacy:
        constraints = [index["columns"] for index in indexes(connection, "ZCHINESELUNARDAY") if index["unique"]]
        assert ["ZDAYINDEX"] in constraints
        assert ["ZCHINESELUNARMONTH", "ZDAYNUMBERINMONTH"] in constraints
    result["rowCounts"] = {table: scalar(connection, f"SELECT count(*) FROM {table}") for table in
                           ["ZCALENDARDAY", "ZCIVILDATE", "ZCHINESELUNARDAY", "ZCHINESELUNARMONTH", "ZCHINESELUNARYEAR"]}
    return result


def compare_queries(old, new):
    months = [r[0] for r in new.execute("SELECT ZLUNARMONTHINDEX FROM ZCHINESELUNARMONTH ORDER BY ZLUNARMONTHINDEX")][::30]
    years = [r[0] for r in new.execute("SELECT ZLUNARYEARNUMBER FROM ZCHINESELUNARYEAR ORDER BY ZLUNARYEARNUMBER")][::3]
    queries = {
        "daysInMonth": (months,
            "SELECT ZDAYINDEX,ZDAYNUMBERINMONTH FROM ZCHINESELUNARDAY WHERE ZLUNARMONTHINDEX=? ORDER BY ZDAYNUMBERINMONTH",
            "SELECT d.ZDAYINDEX,d.ZDAYNUMBERINMONTH FROM ZCHINESELUNARDAY d JOIN ZCHINESELUNARMONTH m ON d.ZCHINESELUNARMONTH=m.Z_PK WHERE m.ZLUNARMONTHINDEX=? ORDER BY d.ZDAYNUMBERINMONTH"),
        "monthsInYear": (years,
            "SELECT ZLUNARMONTHINDEX FROM ZCHINESELUNARMONTH WHERE ZLUNARYEARNUMBER=? ORDER BY ZLUNARMONTHINDEX",
            "SELECT m.ZLUNARMONTHINDEX FROM ZCHINESELUNARMONTH m JOIN ZCHINESELUNARYEAR y ON m.ZCHINESELUNARYEAR=y.Z_PK WHERE y.ZLUNARYEARNUMBER=? ORDER BY m.ZLUNARMONTHINDEX"),
    }
    report = {}
    for name, (parameters, old_sql, new_sql) in queries.items():
        times = [[], []]
        for parameter in parameters:
            results = []
            for index, (connection, sql) in enumerate([(old, old_sql), (new, new_sql)]):
                start = time.perf_counter_ns()
                results.append(connection.execute(sql, [parameter]).fetchall())
                times[index].append((time.perf_counter_ns() - start) / 1_000_000)
            assert results[0] == results[1], (name, parameter)
        report[name] = {"samples": len(parameters), "oldMedianMs": statistics.median(times[0]),
                        "newMedianMs": statistics.median(times[1]), "oldP95Ms": sorted(times[0])[int(len(parameters)*.95)],
                        "newP95Ms": sorted(times[1])[int(len(parameters)*.95)],
                        "newPlan": [r[3] for r in new.execute("EXPLAIN QUERY PLAN " + new_sql, [parameters[0]])]}
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("store")
    parser.add_argument("--compare-to")
    args = parser.parse_args()
    with connect(args.store) as connection:
        output = {"store": args.store, "audit": audit(connection)}
        if args.compare_to:
            with connect(args.compare_to) as previous:
                output["previousAudit"] = audit(previous, legacy=True)
                output["queryComparison"] = compare_queries(previous, connection)
    print(json.dumps(output, indent=2, ensure_ascii=False))
