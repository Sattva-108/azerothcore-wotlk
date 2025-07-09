import os, re, csv
from collections import defaultdict

# ----------------------- CONFIG -----------------------
# No zone restrictions – process all quests
ALLOWED_ZONES: set[str] = set()

# Expansion thresholds (same logic as previous script)
def wowhead_prefix(qid: int) -> str:
    if qid < 9000:
        return 'classic'
    elif qid < 11559:
        return 'tbc'
    else:
        return 'wotlk'

# -------------------- FILE PATHS ----------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT  = os.path.abspath(os.path.join(SCRIPT_DIR, os.pardir))

DB_DIR         = os.path.join(REPO_ROOT, 'db')
QUESTS_LUA     = os.path.join(DB_DIR, 'quests.lua')
UNITS_LUA      = os.path.join(DB_DIR, 'units.lua')
OBJECTS_LUA    = os.path.join(DB_DIR, 'objects.lua')
ZONES_LOC_LUA  = os.path.join(DB_DIR, 'enUS', 'zones.lua')
OUTPUT_TSV     = os.path.join(SCRIPT_DIR, 'quests_zones.tsv')

# Path to quest localization with English names
QUESTS_LOC_LUA = os.path.join(DB_DIR, 'enUS', 'quests.lua')

# Path to AzerothCore quest_template SQL file (for quest names)
QUEST_TEMPLATE_SQL = os.path.abspath(os.path.join(REPO_ROOT, os.pardir, 'data', 'sql', 'base', 'db_world', 'quest_template.sql'))

# ---------------- ADDITIONAL PATHS & CONSTANTS ------------------
# User-maintained CSV with manual columns (Same/Max/Guess)
CSV_4K_PATH   = os.path.join(SCRIPT_DIR, '4k-quests.csv')

# Quest XP lookup table (level → 10 difficulty values)
QUEST_XP_LUA  = os.path.join(DB_DIR, 'questxp.lua')

# TrinityCore/AzerothCore race bit masks (used for faction filtering)
RACE_HUMAN    = 1
RACE_ORC      = 2
RACE_DWARF    = 4
RACE_NELF     = 8
RACE_UNDEAD   = 16
RACE_TAUREN   = 32
RACE_GNOME    = 64
RACE_TROLL    = 128
RACE_BLOODELF = 512
RACE_DRAENEI  = 1024

HORDE_MASK    = RACE_ORC | RACE_UNDEAD | RACE_TAUREN | RACE_TROLL | RACE_BLOODELF  # 690
ALLIANCE_MASK = RACE_HUMAN | RACE_DWARF | RACE_NELF | RACE_GNOME | RACE_DRAENEI   # 1101

# ------------------ ZONE NAME MAP ---------------------
zone_id_to_name: dict[int, str] = {}
zone_re = re.compile(r'\[(\d+)\]\s*=\s*"([^"]+)"')
with open(ZONES_LOC_LUA, 'r', encoding='utf-8', errors='ignore') as f:
    for line in f:
        m = zone_re.search(line)
        if m:
            zid, name = int(m.group(1)), m.group(2)
            zone_id_to_name[zid] = name

# ------------------ ID → ZONES MAP --------------------
# Build lightweight mapping of npc/object id -> set(zone_ids)

def build_id_zone_map(file_path: str) -> dict[int, set[int]]:
    mapping: dict[int, set[int]] = defaultdict(set)
    id_line_re = re.compile(r'^\s*\[(\d+)\]\s*=')
    coords_re  = re.compile(r'\{\s*[0-9]+(?:\.[0-9]+)?,\s*[0-9]+(?:\.[0-9]+)?,\s*(\d+)')
    current_id = None

    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            m_idline = id_line_re.match(line)
            if m_idline:
                current_id = int(m_idline.group(1))
            if current_id is not None:
                for zid in coords_re.findall(line):
                    mapping[current_id].add(int(zid))
    return mapping

print('Building ID → zone map (this may take a few seconds)...')
unit_zone_map   = build_id_zone_map(UNITS_LUA)
object_zone_map = build_id_zone_map(OBJECTS_LUA)
print(f'Parsed {len(unit_zone_map)} NPC entries and {len(object_zone_map)} object entries')

# Helper function to get zone names for an id

def get_zones_for_id(entity_id: int, is_object: bool = False):
    zones = object_zone_map.get(entity_id) if is_object else unit_zone_map.get(entity_id)
    if not zones:
        return set()
    return { zone_id_to_name.get(zid, '') for zid in zones }

# ------------------ QUEST FILTERS ---------------------
qid_re = re.compile(r'^\s*\[(\d+)\]')

# regex helpers to grab id lists inside start/end definitions
def extract_ids(pattern: str, text: str):
    m = re.search(pattern, text)
    if not m:
        return []
    ids_raw = m.group(1)
    return [int(x) for x in re.findall(r'\d+', ids_raw)]

# ------------------ QUEST NAME MAP -------------------
print('Parsing quest names from quest_template.sql (may take a moment)...')
quest_id_to_name: dict[int, str] = {}
quest_id_to_race: dict[int, int] = {}
quest_id_to_xpdiff: dict[int, int] = {}

try:
    # Capture quest ID and the first quoted Title allowing escaped quotes (\')
    name_re = re.compile(r"\(\s*(\d+)[^']*'((?:[^'\\]|\\.)*)'", re.DOTALL)
    with open(QUEST_TEMPLATE_SQL, 'r', encoding='utf-8', errors='ignore') as fsql:
        for line in fsql:
            m = name_re.search(line)
            if m:
                qid = int(m.group(1))
                raw = m.group(2)
                # unescape \' → '
                qname = raw.replace("\\'", "'")
                quest_id_to_name[qid] = qname

                # Extract numeric columns before the first quoted title string
                try:
                    left_part = line.split(",'", 1)[0].lstrip('(')
                    nums = [n.strip() for n in left_part.split(',')]
                except ValueError:
                    nums = []

                # AllowableRaces is the last numeric before strings begin
                if nums:
                    try:
                        race_mask = int(nums[-1])
                    except ValueError:
                        race_mask = 0
                else:
                    race_mask = 0

                # RewardXPDifficulty resides at index 12 (0-based) in quest_template
                xp_diff_val = 0
                if len(nums) > 12:
                    try:
                        xp_diff_val = int(nums[12])
                    except ValueError:
                        xp_diff_val = 0

                quest_id_to_race[qid] = race_mask
                quest_id_to_xpdiff[qid] = xp_diff_val
    print(f'Collected {len(quest_id_to_name):,} quest names from SQL')
except FileNotFoundError:
    print(f'WARNING: quest_template.sql not found at {QUEST_TEMPLATE_SQL}. Quest names will be omitted.')

# Build quick lookup name→id (case-insensitive, first hit wins)
name_to_id: dict[str, int] = {}
for _qid, _name in quest_id_to_name.items():
    lc = _name.lower()
    if lc not in name_to_id:
        name_to_id[lc] = _qid

# ------------------ QUEST XP TABLE -------------------
xp_table: dict[int, list[int]] = {}
xp_re = re.compile(r'\[(\d+)\]\s*=\s*\{([^}]+)\}')
if os.path.isfile(QUEST_XP_LUA):
    with open(QUEST_XP_LUA, 'r', encoding='utf-8', errors='ignore') as fxp:
        txt = fxp.read()
        for lvl, arr in xp_re.findall(txt):
            lvl_i = int(lvl)
            nums = [int(x.strip()) for x in arr.split(',') if x.strip()]
            xp_table[lvl_i] = nums

def base_xp_for(level: int, diff: int) -> int:
    """Return base quest XP for given level and diff index (0-9)."""
    if level <= 0:
        return 0
    arr = xp_table.get(level)
    if not arr:
        return 0
    if diff < 0 or diff >= len(arr):
        return 0
    return arr[diff]

# ---------------- IMPORT USER CSV --------------------
print('Reading user CSV (4k-quests.csv)...')
selected_qids: set[int] = set()
qid_to_extra: dict[int, tuple[str, str, str]] = {}

if os.path.isfile(CSV_4K_PATH):
    with open(CSV_4K_PATH, 'r', encoding='utf-8', errors='ignore') as fcsv:
        reader = csv.DictReader(fcsv)
        for row in reader:
            qfield = (row.get('Quest Link') or '').strip()
            same   = (row.get('Same') or '').strip()
            maxv   = (row.get('Max') or '').strip()
            guess  = (row.get('Guess') or '').strip()

            qid = None
            m_id = re.search(r'quest=(\d+)', qfield)
            if m_id:
                qid = int(m_id.group(1))
            else:
                # Try by exact name (case-insensitive)
                key = qfield.lower().strip('"')
                qid = name_to_id.get(key)

            if qid:
                selected_qids.add(qid)
                qid_to_extra[qid] = (same, maxv, guess)
else:
    print(f'WARNING: {CSV_4K_PATH} not found. No user data will be migrated.')

print(f'User CSV provided {len(selected_qids):,} quest rows to migrate.')

OUTPUT_MIGRATED_TSV = os.path.join(SCRIPT_DIR, '4k-quests-sorted.tsv')

# ---------------- PROCESS PFQUEST DATA ----------------
with open(QUESTS_LUA, 'r', encoding='utf-8', errors='ignore') as fin, \
     open(OUTPUT_MIGRATED_TSV, 'w', newline='', encoding='utf-8') as fout:

    # TSV keeps formulas intact when pasted into Google Sheets
    writer = csv.writer(fout, delimiter='\t', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(['Quest Link', 'Same', 'Max', 'Guess'])

    kept = 0
    rows = []

    # quick inverse lookup once
    name_to_zid = {v: k for k, v in zone_id_to_name.items()}

    for line in fin:
        if ('["start"]' not in line) or ('["end"]' not in line) or ('["obj"]' not in line):
            continue
        if '["event"]' in line:
            continue
        m = qid_re.match(line)
        if not m:
            continue
        qid = int(m.group(1))

        # Only migrate quests present in user CSV
        if selected_qids and qid not in selected_qids:
            continue

        # Faction filtering – keep neutral (0) or any Horde quest, drop Alliance-only
        rmask = quest_id_to_race.get(qid, 0)
        if rmask and (rmask & HORDE_MASK) == 0:
            continue  # Alliance specific, skip

        # collect entity ids
        start_units  = extract_ids(r'\["start"\].*?\["U"\]\s*=\s*\{([^}]*)\}', line)
        start_objs   = extract_ids(r'\["start"\].*?\["O"\]\s*=\s*\{([^}]*)\}', line)
        end_units    = extract_ids(r'\["end"\].*?\["U"\]\s*=\s*\{([^}]*)\}', line)
        end_objs     = extract_ids(r'\["end"\].*?\["O"\]\s*=\s*\{([^}]*)\}', line)

        zone_names = set()
        for uid in start_units:
            zone_names.update(get_zones_for_id(uid, is_object=False))
        for oid in start_objs:
            zone_names.update(get_zones_for_id(oid, is_object=True))
        for uid in end_units:
            zone_names.update(get_zones_for_id(uid, is_object=False))
        for oid in end_objs:
            zone_names.update(get_zones_for_id(oid, is_object=True))

        # (Optional) If user still provided allowed zones, honor them; if set empty, skip filtering
        if ALLOWED_ZONES and not zone_names.intersection(ALLOWED_ZONES):
            continue

        # Extract quest level and class flag
        m_lvl = re.search(r'\["lvl"\]\s*=\s*(-?\d+)', line)
        lvl = int(m_lvl.group(1)) if m_lvl else 0
        is_class = '["class"]' in line

        # Skip class quests entirely
        if is_class:
            continue

        # Determine a primary zone id for grouping
        if zone_names:
            zone_ids_present = [name_to_zid.get(z) for z in zone_names if z in name_to_zid]
            primary_zid = min(zone_ids_present) if zone_ids_present else 99999
        else:
            primary_zid = 99999

        link = f'https://www.wowhead.com/{wowhead_prefix(qid)}/quest={qid}'

        qname = quest_id_to_name.get(qid, f'Quest {qid}')
        disp = qname.replace('"', '""')
        formula = f'=HYPERLINK("{link}", "{disp}")'

        extra_cols = qid_to_extra.get(qid, ('', '', ''))

        # -------------- XP FILTER ------------------
        xp_diff_val = quest_id_to_xpdiff.get(qid, 0)
        base_xp = base_xp_for(lvl, xp_diff_val)
        if base_xp <= 0:
            continue  # Skip non-XP quests

        rows.append((primary_zid, lvl, qid, formula, *extra_cols))
        kept += 1

    # Sort: by primary zone id, then quest level, then quest id
    rows.sort(key=lambda t: (t[0], t[1], t[2]))
    for _zid, _lvl, _qid, _formula, _same, _maxv, _guess in rows:
        writer.writerow([_formula, _same, _maxv, _guess])

print(f'Generated {kept} quests. Output -> {OUTPUT_MIGRATED_TSV}') 