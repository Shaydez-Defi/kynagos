#!/usr/bin/env python3
# =============================================================================
# humanize_check.py
#
# Purpose:
#   Flag AI-sounding tells in a report, disclosure DM, or PoC before it goes out.
#   Kynagos mind/VOICE.md. It finds patterns; a human rewrite fixes them.
#
# Usage:
#   humanize_check.py FILE [FILE ...] [--strict]
#
# Example:
#   python3 ./tools/humanize_check.py reports/vault-high.md test/Exploit.t.sol
#
# Exit codes:
#   0  clean (or only notes)
#   1  tells found (any in --strict mode, or any "fix" level otherwise)
#   2  usage / unreadable file
# =============================================================================
"""Lint reports, DMs and PoCs for machine-written tells. See mind/VOICE.md."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# (pattern, level, advice). level: fix = must rewrite, note = look again.
PHRASES = [
    (r"\bdelv(e|es|ed|ing)\b", "fix", "say 'look at' or cut it"),
    (r"\btapestry\b|\blandscape of\b|\brealm of\b", "fix", "filler metaphor"),
    (r"\bcomprehensive\b|\brobust\b|\bseamless(ly)?\b|\bholistic\b", "fix", "empty adjective; give the fact"),
    (r"\bleverag(e|es|ed|ing)\b", "fix", "say 'use'"),
    (r"\butiliz(e|es|ed|ing)\b", "fix", "say 'use'"),
    (r"\bcrucial\b|\bparamount\b|\bpivotal\b|\bvital\b", "note", "show why it matters instead"),
    (r"it(?:'s| is) (?:important|worth) (?:to note|noting)", "fix", "just say the thing"),
    (r"\bin conclusion\b|\bto summari[sz]e\b|\bin summary\b|\boverall,", "fix", "drop the wrap-up line"),
    (r"\bfurthermore\b|\bmoreover\b|\badditionally\b", "note", "use 'also' or start a new sentence"),
    (r"\breal talk\b|\bhere'?s the (?:thing|catch|kicker)\b|\blet'?s (?:break it down|dive in)\b", "fix", "Kensho 11.5 tell"),
    (r"\bit'?s not just\b.{0,60}\bit'?s\b", "fix", "'not just X, it's Y' construction"),
    (r"\bthis isn'?t about\b", "fix", "'this isn't about X' construction"),
    (r"\bthe (?:truth|reality) is\b|\bthink about it\b|\bthe bigger picture\b", "fix", "Kensho 11.5 tell"),
    (r"\bunderscores?\b|\braises the question\b|\bserves as a testament\b", "fix", "Kensho 11.5 tell"),
    (r"\bi hope this (?:message|email) finds you\b", "fix", "open with the bug, not a greeting formula"),
    (r"\bplease do not hesitate\b|\bfeel free to reach out\b", "fix", "say 'happy to share more'"),
    (r"\bgame[- ]?changer\b|\bcutting[- ]edge\b|\bstate[- ]of[- ]the[- ]art\b", "fix", "marketing word"),
    (r"\bcritical vulnerability\b(?!.*\bseverity\b)", "note", "let the severity line carry the rating"),
    (r"\bas an ai\b|\bas a language model\b|\bi cannot\b.{0,20}\bbrowse\b", "fix", "model disclaimer left in"),
    (r"\bcertainly!|\babsolutely!|\bgreat question\b", "fix", "chatbot opener"),
    (r"\b(?:ensure|ensuring) that\b", "note", "often padding; try cutting 'that'"),
    (r"\bnavigat(e|ing) the\b", "note", "filler verb"),
    (r"\bin today'?s\b", "fix", "filler opener"),
]

EMOJI = re.compile(
    "[\U0001F300-\U0001FAFF\U00002700-\U000027BF\U0001F000-\U0001F2FF\u2600-\u26FF\u2B50\u2705\u274C\u26A0]"
)
EM_DASH = re.compile("\u2014")
BOLD = re.compile(r"\*\*[^*]+\*\*")
CODE_EXT = {".sol", ".rs", ".ts", ".js", ".py", ".go", ".move", ".vy", ".cairo"}
COMMENT = re.compile(r"^\s*(//|#|\*|/\*)")
BANNER = re.compile(r"(console\.log|console2\.log|emit log|println!|print)\s*\(.*(={4,}|-{4,}|\*{4,}|[\U0001F300-\U0001FAFF\u2705\u274C])")
STEP_COMMENT = re.compile(r"^\s*//\s*Step\s*\d+\s*:", re.I)


def check_file(path: Path) -> list[tuple[int, str, str, str]]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    hits: list[tuple[int, str, str, str]] = []
    is_code = path.suffix.lower() in CODE_EXT

    for no, line in enumerate(lines, 1):
        low = line.lower()
        prose = (not is_code) or COMMENT.match(line)
        if prose:
            for pat, level, advice in PHRASES:
                if re.search(pat, low):
                    hits.append((no, level, line.strip()[:90], advice))
        if EMOJI.search(line):
            hits.append((no, "fix", line.strip()[:90], "no emoji in reports, DMs or PoCs"))
        if EM_DASH.search(line) and not is_code:
            hits.append((no, "note", line.strip()[:90], "em dash; prefer a comma, colon or full stop"))
        if is_code and BANNER.search(line):
            hits.append((no, "fix", line.strip()[:90], "decorative log banner; log the numbers that prove impact"))

    if not is_code:
        bold = len(BOLD.findall(text))
        words = max(1, len(text.split()))
        if bold > 6 and bold / words > 0.02:
            hits.append((0, "note", f"{bold} bold spans", "bold only the severity and the one-line impact"))
        headers = sum(1 for l in lines if l.startswith("#"))
        if words < 400 and headers > 8:
            hits.append((0, "note", f"{headers} headings in {words} words", "too many sections for a short report"))
    else:
        code_lines = [l for l in lines if l.strip()]
        comments = [l for l in code_lines if COMMENT.match(l)]
        if len(code_lines) > 20 and len(comments) / len(code_lines) > 0.45:
            hits.append((0, "note", f"{len(comments)}/{len(code_lines)} lines are comments",
                         "over-commented; keep comments that say why, not what"))
        steps = sum(1 for l in lines if STEP_COMMENT.match(l))
        if steps > 6:
            hits.append((0, "note", f"{steps} '// Step N:' comments", "narrating every line reads machine-made"))
    return hits


def main() -> int:
    p = argparse.ArgumentParser(description="Flag AI-sounding tells in reports, DMs and PoCs (mind/VOICE.md).")
    p.add_argument("files", nargs="+", help="report .md, DM .txt, or PoC source files")
    p.add_argument("--strict", action="store_true", help="fail on notes too")
    if len(sys.argv) == 1:
        p.print_usage(sys.stderr)
        print("error: at least one FILE is required", file=sys.stderr)
        return 2
    args = p.parse_args()

    failed = False
    for f in args.files:
        path = Path(f)
        try:
            hits = check_file(path)
        except (OSError, UnicodeDecodeError) as e:
            print(f"error: cannot read {f}: {e}", file=sys.stderr)
            return 2
        if not hits:
            print(f"{f}: clean")
            continue
        print(f"{f}:")
        for no, level, snippet, advice in hits:
            loc = f"L{no}" if no else "file"
            print(f"  {level.upper():4} {loc:>6}  {advice}\n             > {snippet}")
            if level == "fix" or args.strict:
                failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
