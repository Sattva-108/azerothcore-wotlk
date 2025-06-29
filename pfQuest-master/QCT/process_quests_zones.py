import os, re, csv
from collections import defaultdict

# ----------------------- CONFIG -----------------------
ALLOWED_ZONES = {
    'Durotar',
    'The Barrens',
    'Orgrimmar',
}

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
OUTPUT_CSV     = os.path.join(SCRIPT_DIR, 'quests_zones.csv')

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

with open(QUESTS_LUA, 'r', encoding='utf-8', errors='ignore') as fin, \
     open(OUTPUT_CSV, 'w', newline='', encoding='utf-8') as fout:

    writer = csv.writer(fout)
    writer.writerow(['ID', 'Wowhead Link', 'Completion Time'])

    kept = 0
    for line in fin:
        if ('["start"]' not in line) or ('["end"]' not in line) or ('["obj"]' not in line):
            continue
        m = qid_re.match(line)
        if not m:
            continue
        qid = int(m.group(1))

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

        # intersect with allowed zones
        if not zone_names.intersection(ALLOWED_ZONES):
            continue

        link = f'https://www.wowhead.com/{wowhead_prefix(qid)}/quest={qid}'
        writer.writerow([qid, link, ''])
        kept += 1

print(f'Generated {kept} quests limited to zones: {", ".join(sorted(ALLOWED_ZONES))}. Output -> {OUTPUT_CSV}') 