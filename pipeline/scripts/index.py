#!/usr/bin/env python3
"""Martialis Index: influence ranking over the person lineage graph.

Reads every database record as one JSON array (made by `make index` with yq) and writes
export/martialis-index.json. Standard library only. The method is explained on the Martialis
/ranking-methodology page; keep the two in step.

Algorithm: each student credits their teachers with a share GAMMA of themselves, split by
relationship confidence; credit flows on up the lineage (Katz centrality). That "reach" is then
multiplied by the effective number of branches carrying it (a Hill number of order 1) to the power
BRANCH_EXPONENT.

This was the result of differnt experiments, and while it can change in the future, it seems to be
reasonably well adjusted.

Usage:

  index.py compute RECORDS OUT   Run the algorithm, write the index to OUT
  index.py validate INDEX        Regression guards; non-zero exit on failure
  index.py report INDEX          Top-N and era tables
  index.py sensitivity RECORDS   Ranking stability across the parameter grid

Frederico Muñoz <fsm@martial.is>, Martialis Project

"""

import argparse
import bisect
import datetime
import json
import math
import random
import re
import sys
from collections import defaultdict

INDEX_VERSION = "2.0.0"
ALGORITHM = "katz-branch-corrected"

# The two free parameters; `sensitivity` shows the ranking across a grid of both.
# This aren't to be tuned to move someone in particular, but only after an integral review of the
# results (more art than anything).
GAMMA = 0.5
BRANCH_EXPONENT = 0.5

# Confidence level (conflevel: notation) -> probability that the relationship is real, anchored on
# Kent (1964), "Words of Estimative Probability": the vocabulary's definitions map to "certain",
# "probable" (75%), "chances about even" (50%) and "probably not" (30%).
# An unassessed edge counts as possible, a refuted claim is established as false, so it gives no edge at all.

CONFIDENCE_WEIGHT = {"doubtful": 0.3, "possible": 0.5, "probable": 0.75, "confirmed": 1.0}
DEFAULT_CONFIDENCE_WEIGHT = CONFIDENCE_WEIGHT["possible"]
# The same notations' martialis:gradeOrdinal, for "at least probable" tests.
CONFIDENCE_ORDINAL = {"refuted": -1, "doubtful": 0, "possible": 1, "probable": 2, "confirmed": 3}

def _notation(curie):
    """The local name of a CURIE (conflevel:probable -> probable), or None."""
    return curie.split(":", 1)[-1] if isinstance(curie, str) else None

NOW_YEAR = datetime.date.today().year

# Age past which a missing death date is a real documentation gap rather than someone still alive.
# Used only by the coverage indicator (which are indicated as dots in the webapp), never by the
# score. Below this we cannot distinguish "alive" from "not researched", since the schema has no
# liveness flag (yet) `death: {date: null}` means both), so we decline to penalise for something
# that is not really certain or known.
LIFESPAN_CAP = 110

# Tier cut points on the published (0-100, log-normalised) score. The score is relative to the _top
# person_, so a tier is a band relative to the top too. Below the last cut there is no tier at all
# This can be tweaked, but should be done with intention and related with a bump in INDEX_VERSION,
# not casually.
TIER_CUTS = [
    ("Foundational", 85.0),
    ("Major", 65.0),
    ("Notable", 40.0),
]

# Useful since othherwise older entries would crush everything in all views.
ERA_BUCKETS = [
    ("pre-1800", None, 1799),
    ("1800-1849", 1800, 1849),
    ("1850-1899", 1850, 1899),
    ("1900-1949", 1900, 1949),
    ("1950-present", 1950, None),
]



# LOADING
# ---------------------------------------------------------------------------

# Records are read in the LinkML model's own keys (model/martialis.yaml), the accessors below are
# the only places that know them.

def teacher_assertions(person):
    """The person's teacher assertions that name a teacher."""
    return [t for t in (person.get("hasTeacherAssertion") or []) if t.get("teacher")]


def confidence_level(assertion):
    """Confidence notation (probable, confirmed, ...) of ASSERTION, or None."""
    return _notation((assertion.get("hasConfidence") or {}).get("confidenceLevel"))


def birth_date(person):
    return (person.get("birthEvent") or {}).get("birthDate")


def death_date(person):
    return (person.get("deathEvent") or {}).get("deathDate")


def load_records(path):
    """(persons, styles), each id -> record, from the JSON array at PATH."""
    with open(path, encoding="utf-8") as fh:
        records = json.load(fh)
    by_type = defaultdict(dict)
    for r in sorted((r for r in records if r and r.get("id")), key=lambda r: r["id"]):
        by_type[r.get("type")][r["id"]] = r
    if not by_type["Person"]:
        sys.exit(f"{path} holds no Person records")
    return by_type["Person"], by_type["Style"]


def write_json(obj, path):
    """Write OBJ to PATH as stable JSON, so an unchanged index is byte-identical."""
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, ensure_ascii=False, indent=1, sort_keys=True)
        fh.write("\n")


def load_index(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def display_name(name_map):
    if not name_map:
        return "?"
    for lang in ("en", "ja-Latn", "pt"):
        if lang in name_map:
            v = name_map[lang]
            return v[0] if isinstance(v, list) else v
    v = next(iter(name_map.values()))
    return v[0] if isinstance(v, list) else v


def birth_year(person):
    """The first year in the EDTF birth date: 1883, 1883~, [1793,1794] -> 1883, 1793."""
    m = re.search(r"\d{4}", str(birth_date(person) or ""))
    return int(m.group()) if m else None



# Graph construction
# ---------------------------------------------------------------------------

def build_edges(persons):
    """Return (edges, edge_style, dropped). EDGES maps (student, teacher) to the relationship's
    confidence weight, EDGE_STYLE maps the same key to the asserted style id or None, and DROPPED
    lists skipped edges with a reason, for the artifact metadata.

    """
    edges = {}
    edge_style = {}
    dropped = []
    for pid, p in persons.items():
        for t in teacher_assertions(p):
            tid = t["teacher"]
            if tid not in persons:
                dropped.append({"student": pid, "teacher": tid, "reason": "teacher_not_in_db"})
                continue
            if tid == pid:
                dropped.append({"student": pid, "teacher": tid, "reason": "self_loop"})
                continue
            if confidence_level(t) == "refuted":
                dropped.append({"student": pid, "teacher": tid, "reason": "refuted"})
                continue
            w = CONFIDENCE_WEIGHT.get(confidence_level(t), DEFAULT_CONFIDENCE_WEIGHT)
            key = (pid, tid)
            if edges.get(key, 0.0) < w:
                edges[key] = w
                edge_style[key] = t.get("assertedStyle")
    if persons and not edges:
        sys.exit(
            f"No lineage edges built from {len(persons)} persons. No "
            f"hasTeacherAssertion named a teacher -- the martialis-db model "
            f"has probably renamed a slot; check the accessors under Loading."
        )
    return edges, edge_style, dropped


def students_of(edges):
    """Teacher -> list of students, from EDGES."""
    down = defaultdict(list)
    for (s, t) in edges:
        down[t].append(s)
    return down


def cone(root, down):
    """Everyone downstream of ROOT (students, their students, ...)."""
    seen = set()
    stack = [root]
    while stack:
        for s in down.get(stack.pop(), []):
            if s not in seen and s != root:
                seen.add(s)
                stack.append(s)
    return seen


# Algorithm
# ---------------------------------------------------------------------------

def credit_shares(edges, gamma=GAMMA):
    """(student, teacher) -> share of the student credited to that teacher.

    A student passes GAMMA of themselves to their teachers, split in proportion to confidence. When
    the confidences add up to less than one certain relationship, the unclaimed part stays with the
    student, so a lone doubtful teacher gets 0.3 * GAMMA, not all of it.

    """
    total = defaultdict(float)
    for (s, _t), c in edges.items():
        total[s] += c
    return {(s, t): gamma * c / max(1.0, total[s]) for (s, t), c in edges.items()}


def compute_scores(persons, edges, gamma=GAMMA, branch_exponent=BRANCH_EXPONENT):
    """pid -> {reach, branch, dominance, raw}.

    Reach is the Katz series over the credit-share matrix A: reach(p) = sum over students s of
    A[s,p] * (1 + reach(s)), solved by fixed-point iteration. Every student's shares add up to at
    most GAMMA < 1, so it converges on any graph, cycles included (mutual teaching is real).

    Each term of that sum is the part of p's reach carried by one direct student. Branch is the
    effective number of those parts (Hill number of order 1, exp of their Shannon entropy);
    dominance is the largest part's fraction (Berger-Parker index).

    """
    kids = defaultdict(list)  # teacher -> [(student, share)]
    for (s, t), a in credit_shares(edges, gamma).items():
        kids[t].append((s, a))

    reach = {p: 0.0 for p in persons}
    while True:
        new = {p: sum(a * (1.0 + reach[s]) for s, a in kids.get(p, [])) for p in persons}
        done = max((abs(new[p] - reach[p]) for p in persons), default=0.0) < 1e-12
        reach = new
        if done:
            break

    result = {}
    for p in persons:
        parts = [a * (1.0 + reach[s]) for s, a in kids.get(p, [])]
        r = reach[p]
        if r > 0:
            branch = math.exp(-sum(x / r * math.log(x / r) for x in parts if x > 0))
            dominance = max(parts) / r
        else:
            branch = dominance = 0.0
        result[p] = {
            "reach": r,
            "branch": branch,
            "dominance": dominance,
            "raw": r * branch ** branch_exponent,
        }
    return result


def art_of(style_id, vparent):
    seen = set()
    while style_id in vparent and style_id not in seen:
        seen.add(style_id)
        style_id = vparent[style_id]
    return style_id


def variant_parents(styles):
    vparent = {}
    for sid, s in styles.items():
        for r in (s.get("hasStyleRelationAssertion") or []):
            if _notation(r.get("styleRelationType")) == "variant_of" and r.get("relatedStyle"):
                vparent.setdefault(sid, r["relatedStyle"])
    return vparent


def arts_reached(members, edge_style, vparent):
    """Distinct arts (variant_of rolled up) taught to anyone in MEMBERS."""
    return sorted({art_of(sid, vparent) for (s, _t), sid in edge_style.items()
                   if sid and s in members})


def plausibly_living(person):
    """True when we have no basis to expect a death date. A recorded death event, dated or not,
    means the person is dead. Otherwise the person may be alive unless their birth is too long ago;
    with no birth date we cannot tell, so this is deliberately charitable.

    """
    if person.get("deathEvent"):
        return False
    by = birth_year(person)
    return by is None or (NOW_YEAR - by) < LIFESPAN_CAP


def coverage_score(person):
    """0-5 documentation/completeness indicator. Not part of the score.

    Scored as earned/APPLICABLE points rescaled to 0-5, so a check that cannot apply to someone is
    skipped rather than counted against them: being alive is not a documentation gap. The
    methodology page's "Data coverage" table describes these checks; keep the two in step.

    """
    earned = 0
    applicable = 0

    # Citation count. NOTE: count only - `information_type` and `evidence_type` are deliberately not
    # inspected here yet; see the methodology page's "Data coverage" section.
    n_sources = len(person.get("hasEvidence") or [])
    earned += 2 if n_sources >= 3 else (1 if n_sources >= 1 else 0)
    applicable += 2

    if birth_date(person):
        earned += 1
    applicable += 1

    if not plausibly_living(person):
        applicable += 1
        if death_date(person):
            earned += 1

    # Every teacher claim counts, named or not, as in martialis-db's own PersonCompletenessShape; at
    # least one is needed for the point.
    confs = [CONFIDENCE_ORDINAL.get(confidence_level(t))
             for t in (person.get("hasTeacherAssertion") or [])]
    if confs and all(c is not None and c >= 2 for c in confs):
        earned += 1
    applicable += 1

    return round(5 * earned / applicable)


def tier_for(score):
    for name, cut in TIER_CUTS:
        if score >= cut:
            return name
    return None


def era_for(year):
    if year is None:
        return "undated"
    for name, lo, hi in ERA_BUCKETS:
        if (lo is None or year >= lo) and (hi is None or year <= hi):
            return name
    return "undated"


def kendall_tau(a, b, keys):
    keys = list(keys)
    c = d = 0
    for i in range(len(keys)):
        for j in range(i + 1, len(keys)):
            da = a[keys[i]] - a[keys[j]]
            db = b[keys[i]] - b[keys[j]]
            if da * db > 0:
                c += 1
            elif da * db < 0:
                d += 1
    return (c - d) / (c + d) if (c + d) else 0.0


# Premium breakdown: counterfactual contribution of each direct student
# ---------------------------------------------------------------------------

# This is relatively rare, but needs to be tackled from the start, otherwise adding "controversial"
# entries in the future would mean adding something then, which could be ill-perceived...

def compute_counterfactuals(persons, edges, base_scores, top_n=5):
    """For each teacher, and each of their direct student edges, remove that single sourced
    relationship and recompute the whole graph. Returns {teacher_id: [{student, delta_raw,
    share_pct}, ...]} sorted by impact, restricted to the top_n most load-bearing edges per teacher.
    This is the per-person breakdown: "how much of your score rests on this one documented
    relationship".

    """
    by_teacher = defaultdict(list)
    for (s, t) in edges:
        by_teacher[t].append(s)

    out = {}
    for t, students in by_teacher.items():
        base_raw = base_scores[t]["raw"]
        rows = []
        for s in students:
            ed2 = {k: v for k, v in edges.items() if k != (s, t)}
            sc2 = compute_scores(persons, ed2)
            delta = base_raw - sc2[t]["raw"]
            rows.append({
                "student": s,
                "delta_raw": round(delta, 6),
                "share_pct": round(100.0 * delta / base_raw, 2) if base_raw > 0 else 0.0,
            })
        rows.sort(key=lambda r: (-r["delta_raw"], display_name(persons[r["student"]].get("name"))))
        out[t] = rows[:top_n]
    return out



# Stability checks
# ---------------------------------------------------------------------------

# We need a way to make sure things are stable

def stability_check(persons, edges, trials=20, drop_frac=0.10, seed=7):
    rng = random.Random(seed)
    base = compute_scores(persons, edges)
    base_raw = {p: base[p]["raw"] for p in persons}
    base_top20 = set(sorted(persons, key=lambda p: -base_raw[p])[:20])

    all_keys = list(edges.keys())
    n_drop = max(1, int(drop_frac * len(all_keys)))
    overlaps = []
    for _ in range(trials):
        drop = set(rng.sample(all_keys, n_drop))
        ed2 = {k: v for k, v in edges.items() if k not in drop}
        sc2 = compute_scores(persons, ed2)
        raw2 = {p: sc2[p]["raw"] for p in persons}
        top20_2 = set(sorted(persons, key=lambda p: -raw2[p])[:20])
        overlaps.append(len(base_top20 & top20_2) / 20)
    return sum(overlaps) / len(overlaps)



# compute
# ---------------------------------------------------------------------------

def do_compute(args):
    persons, styles = load_records(args.records)
    edges, edge_style, dropped = build_edges(persons)
    down = students_of(edges)
    vparent = variant_parents(styles)

    scores = compute_scores(persons, edges)
    max_raw = max((v["raw"] for v in scores.values()), default=0.0)
    contributors = compute_counterfactuals(persons, edges, scores)

    entries = {}
    for p, d in scores.items():
        published = 100.0 * (math.log1p(d["raw"]) / math.log1p(max_raw)) if max_raw > 0 else 0.0
        person = persons[p]
        members = cone(p, down)
        top_contributors = [
            {
                "student": row["student"],
                "student_name": display_name(persons[row["student"]].get("name")),
                "delta_raw": row["delta_raw"],
                "share_pct": row["share_pct"],
            }
            for row in contributors.get(p, [])
        ]
        entries[p] = {
            "name": display_name(person.get("name")),
            "score": round(published, 2),
            "tier": tier_for(published),
            "raw": round(d["raw"], 6),
            "reach": round(d["reach"], 4),
            "branch": round(d["branch"], 4),
            "cone_size": len(members),
            "dominance": round(d["dominance"], 4),
            "coverage": coverage_score(person),
            # Surfaced so `validate` can guard the "a living person can
            # never reach 5/5" regression without needing the database.
            "plausibly_living": plausibly_living(person),
            "arts_reached": arts_reached(members, edge_style, vparent),
            "birth_year": birth_year(person),
            "era": era_for(birth_year(person)),
            "top_contributors": top_contributors,
        }

    stability = stability_check(persons, edges)

    # Standard competition ranking ("1224"): equal raw scores share a rank, so co-teachers of the
    # same students tie. A person with no recorded students has no rank: a rank would only say where
    # the records stop.
    raws = sorted((e["raw"] for e in entries.values()), reverse=True)
    for e in entries.values():
        e["rank"] = 1 + bisect.bisect_left([-r for r in raws], -e["raw"]) if e["raw"] > 0 else None

    # No timestamp or commit: the output must be byte-identical when nothing changed, so CI commits
    # it only on a real change. The database snapshot that carries this file records its own commit.
    artifact = {
        "meta": {
            "index_version": INDEX_VERSION,
            "algorithm": ALGORITHM,
            "gamma": GAMMA,
            "branch_exponent": BRANCH_EXPONENT,
            "node_count": len(persons),
            "edge_count": len(edges),
            "dropped_edges": dropped,
            "stability_top20_retention": round(stability, 4),
        },
        "entries": entries,
    }

    write_json(artifact, args.out)
    print(f"index: {len(entries)} entries -> {args.out} ("
          f"{len(dropped)} edges dropped, "
          f"stability {stability:.3f})")


# report
# ---------------------------------------------------------------------------

def do_report(args):
    art = load_index(args.index)
    entries = art["entries"]
    ranked = sorted(((p, e) for p, e in entries.items() if e["rank"]), key=lambda kv: kv[1]["rank"])
    print(f"Martialis Index v{art['meta']['index_version']}  "
          f"({art['meta']['node_count']} persons, {art['meta']['edge_count']} edges, "
          f"stability={art['meta']['stability_top20_retention']})")
    print(f"\nTop {args.top}:")
    for pid, e in ranked[:args.top]:
        print(f"  {e['rank']:3d}  {e['score']:6.2f}  {e['tier'] or '':12s}  "
              f"b.{e['birth_year'] or '????':<5}  {e['name']}")

    if args.era:
        by_era = defaultdict(list)
        for pid, e in entries.items():
            by_era[e["era"]].append((pid, e))
        order = [name for name, _, _ in ERA_BUCKETS] + ["undated"]
        for era in order:
            members = sorted(by_era.get(era, []), key=lambda kv: -kv[1]["score"])[:10]
            if not members:
                continue
            print(f"\n-- {era} --")
            for pid, e in members:
                print(f"  {e['score']:6.2f}  {e['name']}")


# ---------------------------------------------------------------------------
# sensitivity
# ---------------------------------------------------------------------------

def ranked(raw, n=None):
    """Person ids by descending RAW score, best first."""
    return sorted(raw, key=lambda p: -raw[p])[:n]


def do_sensitivity(args):
    persons, _ = load_records(args.records)
    edges, _, _ = build_edges(persons)
    name = lambda p: display_name(persons[p].get("name"))

    grid = [(g, e) for g in (0.35, 0.5, 0.7) for e in (0.0, 0.5, 1.0)]
    raw = {}
    for g, e in grid:
        sc = compute_scores(persons, edges, gamma=g, branch_exponent=e)
        raw[(g, e)] = {p: sc[p]["raw"] for p in persons}
    default = raw[(GAMMA, BRANCH_EXPONENT)]
    top20 = set(ranked(default, 20))

    print("Kendall tau between every pair of settings "
          "(g = gamma, e = branch exponent), and top-20 overlap with the default:\n")
    print("            " + "".join(f"g{g:.2f}e{e:.1f}".rjust(11) for g, e in grid) + "   top-20")
    for k1 in grid:
        row = "".join(f"{kendall_tau(raw[k1], raw[k2], persons):>11.2f}" for k2 in grid)
        print(f"g{k1[0]:.2f}e{k1[1]:.1f}  {row}   {len(top20 & set(ranked(raw[k1], 20))):>3}/20")

    print(f"\nDefault (gamma={GAMMA}, exponent={BRANCH_EXPONENT}) top 10:")
    for p in ranked(default, 10):
        print(f"  {default[p]:9.4f}  {name(p)}")

    # What the branch correction does: teachers whose whole reach runs through one student, ranked
    # without and with it.
    base = compute_scores(persons, edges, branch_exponent=0.0)
    r0 = {p: i for i, p in enumerate(ranked({p: base[p]["raw"] for p in persons}), 1)}
    r1 = {p: i for i, p in enumerate(ranked(default), 1)}
    print("\nSingle-line teachers in the top 50 without the branch correction "
          "(rank without -> with):")
    for p in sorted(r0, key=r0.get)[:50]:
        if base[p]["dominance"] >= 0.999:
            print(f"  {r0[p]:3d} -> {r1[p]:3d}  {name(p)}")


# validate
# ---------------------------------------------------------------------------

def do_validate(args):
    art = load_index(args.index)
    entries = art["entries"]
    failures = []

    ranked = sorted(((p, e) for p, e in entries.items() if e["rank"]), key=lambda kv: kv[1]["rank"])
    top20 = ranked[:20]

    for pid, e in top20:
        if e["dominance"] >= 0.999:
            failures.append(
                f"FAIL: {e['name']} owes all their reach to one student yet ranks "
                f"in the top 20 -- the branch correction has stopped working"
            )

    # Schema drift guards: a renamed slot in martialis-db silently empties a field rather than
    # raising, so check that the fields are still populated.
    for field in ("birth_year", "arts_reached", "top_contributors"):
        if not any(e.get(field) for e in entries.values()):
            failures.append(f"FAIL: no entry has {field}; did a martialis-db slot get renamed?")

    top1 = ranked[0][1]

    births = {pid: e["birth_year"] for pid, e in entries.items() if e["birth_year"]}
    scores = {pid: e["score"] for pid, e in entries.items() if pid in births}
    tau = kendall_tau(scores, births, births.keys())
    print(f"score vs birth-year Kendall tau = {tau:+.3f}  (reference ~ -0.23; "
          f"a sharp change signals a coverage shift, not necessarily a bug)")

    stability = art["meta"]["stability_top20_retention"]
    if stability is not None and stability < 0.85:
        failures.append(f"FAIL: stability top-20 retention {stability:.2f} < 0.85 threshold")

    seen_persons = set(entries.keys())
    if len(seen_persons) != art["meta"]["node_count"]:
        failures.append("FAIL: entry count does not match node_count in metadata")

    # Coverage regression guard: the metric once awarded an unconditional point for a death date, so
    # no living person could reach 5/5 (measured: their ceiling was 4). Freeze the fix - if the
    # death check ever becomes unconditional again, this fails.
    living = [e for e in entries.values() if e.get("plausibly_living")]
    if living:
        best = max(e["coverage"] for e in living)
        if best < 5:
            failures.append(
                f"FAIL: best coverage among {len(living)} plausibly-living entries "
                f"is {best}/5, not 5 -- the living-person coverage cap has regressed"
            )
    else:
        failures.append("FAIL: no entry carries plausibly_living; the coverage guard "
                        "cannot run (was the field dropped from compute?)")

    if failures:
        for f in failures:
            print(f)
        sys.exit(1)
    print(f"OK: {len(entries)} entries, top-1={top1['name']}, "
          f"stability={stability}, no single-line teacher in top 20, "
          f"living-coverage ceiling {max(e['coverage'] for e in living)}/5")


# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("compute", help="Run the algorithm and write the index")
    p.add_argument("records")
    p.add_argument("out")
    p.set_defaults(func=do_compute)

    p = sub.add_parser("validate", help="Regression guards on a computed index")
    p.add_argument("index")
    p.set_defaults(func=do_validate)

    p = sub.add_parser("report", help="Print top-N and era tables")
    p.add_argument("index")
    p.add_argument("--top", type=int, default=25)
    p.add_argument("--era", action="store_true")
    p.set_defaults(func=do_report)

    p = sub.add_parser("sensitivity", help="Parameter sensitivity grid")
    p.add_argument("records")
    p.set_defaults(func=do_sensitivity)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
