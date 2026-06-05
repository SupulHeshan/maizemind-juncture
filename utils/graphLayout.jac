"""BFS tree layout engine for the argument graph.
Assigns x/y positions level-by-level; roots at the top, children below."""


"Position info for a single node"
obj NodePosition {
    has node_id: str,
        x: float,
        y: float,
        level: int = 0;
}


"""Calculate tree layout positions for all nodes.
Returns a list of NodePosition objects, one per node."""
def calculate_layout(
    nodes: list[dict[str, str]],
    edges: list[dict[str, str]],
    canvas_width: float = 1200.0,
    level_height: float = 150.0
) -> list[NodePosition] {

    if not nodes {
        return [];
    }

    children_map: dict[str, list[str]] = {};
    has_parent: list[str] = [];

    for e in edges {
        parent_id = e.get("to_id", "");
        child_id = e.get("from_id", "");
        if e.get("type", "") in ["supports", "depends_on"] {
            if parent_id not in children_map {
                children_map[parent_id] = [];
            }
            children_map[parent_id].append(child_id);
            has_parent.append(child_id);
        }
    }

    all_ids = [n["id"] for n in nodes if n.get("id")];
    roots = [nid for nid in all_ids if nid not in has_parent];

    if not roots {
        thesis = [n["id"] for n in nodes if n.get("id") and n.get("type", "") == "thesis"];
        roots = thesis if thesis else [all_ids[0]];
    }

    level_map: dict[str, int] = {};
    queue: list[str] = [];
    for r in roots {
        queue.append(r);
        level_map[r] = 0;
    }

    qi = 0;
    while qi < len(queue) {
        current = queue[qi];
        qi += 1;
        current_level = level_map.get(current, 0);
        for child in children_map.get(current, []) {
            if child not in level_map {
                level_map[child] = current_level + 1;
                queue.append(child);
            }
        }
    }

    for nid in all_ids {
        if nid not in level_map {
            level_map[nid] = 0;
        }
    }

    levels: dict[int, list[str]] = {};
    for nid in all_ids {
        lvl = level_map[nid];
        if lvl not in levels {
            levels[lvl] = [];
        }
        levels[lvl].append(nid);
    }

    positions: list[NodePosition] = [];
    for lvl in levels {
        nodes_at_level = levels[lvl];
        count = len(nodes_at_level);
        spacing = canvas_width / (count + 1);
        for (i, nid) in enumerate(nodes_at_level) {
            positions.append(NodePosition(
                node_id=nid,
                x=spacing * (i + 1),
                y=80.0 + lvl * level_height,
                level=lvl
            ));
        }
    }

    return positions;
}
