"""MaizeMind - Interactive Argument Graph Viewer Component.
Renders nodes/edges as an interactive zoomable SVG graph.
Handles branch selection, zoom-to-node, and pan/zoom controls."""


"""Interactive argument graph with zoom, pan, and node selection.
Props:
  - graph_nodes: list of node dicts from the pipeline
  - graph_edges: list of edge dicts from the pipeline
  - on_node_select: callback when a node is clicked
  - on_branch_focus: callback when double-clicking to zoom into a branch"""
def:pub GraphViewer(
    graph_nodes: list = [],
    graph_edges: list = [],
    on_node_select: any = None,
    on_branch_focus: any = None
) -> JsxElement {

    # --- State ---
    has selected_node_id: str = "",
        zoom_level: float = 1.0,
        pan_x: float = 0.0,
        pan_y: float = 0.0,
        is_panning: bool = False,
        pan_start_x: float = 0.0,
        pan_start_y: float = 0.0,
        hovered_node_id: str = "",
        focused_branch_root: str = "";

    # --- Node colors by type ---
    def get_node_color(node_type: str) -> str {
        if node_type == "thesis" { return "#8b5cf6"; }
        if node_type == "claim" { return "#3b82f6"; }
        if node_type == "evidence" { return "#10b981"; }
        if node_type == "assumption" { return "#f59e0b"; }
        if node_type == "counterarg" { return "#ef4444"; }
        return "#6b7280";
    }

    def get_status_color(status: str) -> str {
        if status == "ok" { return "#10b981"; }
        if status == "needs_work" { return "#f59e0b"; }
        if status == "missing" { return "#ef4444"; }
        return "#d1d5db";
    }

    def get_edge_color(edge_type: str) -> str {
        if edge_type == "supports" { return "#10b981"; }
        if edge_type == "contradicts" { return "#ef4444"; }
        if edge_type == "depends_on" { return "#f59e0b"; }
        if edge_type == "addresses" { return "#8b5cf6"; }
        return "#9ca3af";
    }

    def get_edge_dash(edge_type: str) -> str {
        if edge_type == "contradicts" { return "8,4"; }
        if edge_type == "depends_on" { return "6,3"; }
        return "none";
    }

    # BFS tree layout: returns {node_id: {x, y}} for all nodes
    def get_positions() -> dict[str, dict[str, float]] {
        pos_map: dict[str, dict[str, float]] = {};
        if not graph_nodes { return pos_map; }

        children_map: dict[str, list[str]] = {};
        has_parent: list[str] = [];
        for e in graph_edges {
            p_id = e.get("to_id", "");
            c_id = e.get("from_id", "");
            if e.get("type", "") in ["supports", "depends_on"] {
                if p_id not in children_map {
                    children_map[p_id] = [];
                }
                children_map[p_id].append(c_id);
                has_parent.append(c_id);
            }
        }

        all_ids = [n["id"] for n in graph_nodes if n.get("id")];
        roots = [nid for nid in all_ids if nid not in has_parent];
        if not roots {
            roots = [all_ids[0]];
        }

        level_map: dict[str, int] = {};
        queue: list[str] = [];
        for r in roots {
            queue.append(r);
            level_map[r] = 0;
        }
        qi = 0;
        while qi < len(queue) {
            cur = queue[qi];
            qi += 1;
            for child in children_map.get(cur, []) {
                if child not in level_map {
                    level_map[child] = level_map[cur] + 1;
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

        w = 1000.0;
        lh = 160.0;
        for lvl in sorted(levels) {
            ns = levels[lvl];
            cnt = len(ns);
            sp = w / (cnt + 1);
            for (i, nid) in enumerate(ns) {
                pos_map[nid] = {
                    "x": sp * (i + 1),
                    "y": 60.0 + lvl * lh
                };
            }
        }

        return pos_map;
    }

    # --- Event handlers ---
    def handle_node_click(node_id: str) -> None {
        selected_node_id = node_id;
        if on_node_select { on_node_select(node_id); }
    }

    def handle_zoom_to_node(node_id: str) -> None {
        positions = get_positions();
        if node_id in positions {
            p = positions[node_id];
            zoom_level = 2.0;
            pan_x = -(p["x"] * 2.0 - 500.0);
            pan_y = -(p["y"] * 2.0 - 300.0);
        }
        selected_node_id = node_id;
        focused_branch_root = node_id;
        if on_branch_focus { on_branch_focus(node_id); }
    }

    def handle_zoom_out() -> None {
        zoom_level = 1.0;
        pan_x = 0.0;
        pan_y = 0.0;
        focused_branch_root = "";
    }

    def handle_wheel(e: any) -> None {
        e.preventDefault();
        delta = -e.deltaY * 0.001;
        new_zoom = zoom_level + delta;
        if new_zoom < 0.3 { new_zoom = 0.3; }
        if new_zoom > 4.0 { new_zoom = 4.0; }
        zoom_level = new_zoom;
    }

    def handle_mouse_down(e: any) -> None {
        if e.button == 0 {
            is_panning = True;
            pan_start_x = e.clientX - pan_x;
            pan_start_y = e.clientY - pan_y;
        }
    }

    def handle_mouse_move(e: any) -> None {
        if is_panning {
            pan_x = e.clientX - pan_start_x;
            pan_y = e.clientY - pan_start_y;
        }
    }

    def handle_mouse_up(e: any) -> None {
        is_panning = False;
    }

    # --- Render ---
    positions = get_positions();
    svg_w = 1000;
    svg_h = max(600, len(graph_nodes) * 80);

    return
        <div className="gv-container">

            <div className="gv-zoom-controls">
                <button
                    className="gv-zoom-btn"
                    onClick={lambda e: any -> None { zoom_level = min(4.0, zoom_level + 0.3); }}>
                    +
                </button>
                <button
                    className="gv-zoom-btn"
                    onClick={lambda e: any -> None { zoom_level = max(0.3, zoom_level - 0.3); }}>
                    -
                </button>
                <button
                    className="gv-zoom-btn gv-zoom-btn-fit"
                    onClick={lambda e: any -> None { handle_zoom_out(); }}>
                    Fit
                </button>
            </div>

            { focused_branch_root and
                <div
                    className="gv-branch-back-btn"
                    onClick={lambda e: any -> None { handle_zoom_out(); }}>
                    ← Back to full map
                </div>
            }

            <svg
                width="100%"
                height="100%"
                viewBox={f"0 0 {svg_w} {svg_h}"}
                onWheel={handle_wheel}
                onMouseDown={handle_mouse_down}
                onMouseMove={handle_mouse_move}
                onMouseUp={handle_mouse_up}
                onMouseLeave={handle_mouse_up}
                style={{"cursor": "grab" if not is_panning else "grabbing"}}>

                <g transform={f"translate({pan_x},{pan_y}) scale({zoom_level})"}>

                    { [
                        <g key={f"edge-{i}"}>
                            { (lambda e: any, ps: any -> JsxElement {
                                from_p = ps.get(e.get("from_id", ""), {});
                                to_p = ps.get(e.get("to_id", ""), {});
                                if not from_p or not to_p {
                                    return <g></g>;
                                }
                                fx = from_p.get("x", 0);
                                fy = from_p.get("y", 0);
                                tx = to_p.get("x", 0);
                                ty = to_p.get("y", 0);
                                mid_y = (fy + ty) / 2;
                                ec = get_edge_color(e.get("type", ""));
                                ed = get_edge_dash(e.get("type", ""));
                                w = max(1.5, e.get("weight", 0.5) * 4);
                                return <g>
                                    <path
                                        d={f"M {fx} {fy} C {fx} {mid_y}, {tx} {mid_y}, {tx} {ty}"}
                                        stroke={ec}
                                        strokeWidth={w}
                                        fill="none"
                                        strokeDasharray={ed if ed != "none" else ""}
                                        opacity="0.6"
                                        markerEnd="url(#arrowhead)" />
                                    <text
                                        x={(fx + tx) / 2 + 8}
                                        y={mid_y - 4}
                                        fontSize="10"
                                        fill={ec}
                                        opacity="0.8">
                                        {e.get("type", "")}
                                    </text>
                                </g>;
                            })(edge, positions) }
                        </g>
                        for (i, edge) in enumerate(graph_edges)
                    ] }

                    { [
                        <g key={f"node-{i}"}
                           onClick={lambda e: any -> None {
                               handle_node_click(node.get("id", ""));
                           }}
                           onDoubleClick={lambda e: any -> None {
                               handle_zoom_to_node(node.get("id", ""));
                           }}
                           onMouseEnter={lambda e: any -> None {
                               hovered_node_id = node.get("id", "");
                           }}
                           onMouseLeave={lambda e: any -> None {
                               hovered_node_id = "";
                           }}
                           className="gv-node"
                           transform={
                               f"translate({positions.get(node.get('id', ''), {}).get('x', 0) - 90},"
                               f"{positions.get(node.get('id', ''), {}).get('y', 0) - 30})"
                           }>
                            <rect
                                className="gv-node-rect"
                                width="180" height="60"
                                rx="12" ry="12"
                                fill="white"
                                stroke={
                                    "#6366f1" if node.get("id") == selected_node_id
                                    else get_status_color(node.get("status", ""))
                                }
                                strokeWidth={
                                    "3" if node.get("id") == selected_node_id else "2"
                                }
                                style={{
                                    "filter": "drop-shadow(0 2px 4px rgba(0,0,0,0.08))"
                                             if node.get("id") != hovered_node_id
                                             else "drop-shadow(0 4px 8px rgba(0,0,0,0.15))"
                                }} />

                            <rect
                                width="180" height="20"
                                rx="12" ry="12"
                                fill={get_node_color(node.get("type", ""))} />
                            <rect
                                y="10" width="180" height="10"
                                fill={get_node_color(node.get("type", ""))} />

                            <text x="10" y="14" fontSize="10" fill="white"
                                  fontWeight="600" fontFamily="system-ui">
                                {node.get("type", "").upper()}
                            </text>

                            <text x="155" y="14" fontSize="9" fill="white"
                                  fontWeight="500" textAnchor="end" fontFamily="system-ui">
                                {f"{int(node.get('nodeScore', 50))}"}
                            </text>
                            <text x="10" y="38" fontSize="11" fill="#1e293b"
                                  fontFamily="system-ui">
                                { node.get("text", "")[:28] }
                            </text>
                            <text x="10" y="52" fontSize="11" fill="#1e293b"
                                  fontFamily="system-ui">
                                { node.get("text", "")[28:56] + ("..." if len(node.get("text", "")) > 56 else "") }
                            </text>

                            { node.get("issues", []) and
                                <g>
                                    <circle cx="170" cy="50" r="8" fill="#ef4444" />
                                    <text x="170" y="54" fontSize="10" fill="white"
                                          textAnchor="middle" fontWeight="700">
                                        !
                                    </text>
                                </g>
                            }
                        </g>
                        for (i, node) in enumerate(graph_nodes)
                    ] }

                    <defs>
                        <marker id="arrowhead" markerWidth="8" markerHeight="6"
                                refX="8" refY="3" orient="auto">
                            <path d="M 0 0 L 8 3 L 0 6 Z" fill="#9ca3af" />
                        </marker>
                    </defs>

                </g>
            </svg>

            <div className="gv-legend">
                <span><span className="gv-legend-dot-thesis">●</span> Thesis</span>
                <span><span className="gv-legend-dot-claim">●</span> Claim</span>
                <span><span className="gv-legend-dot-evidence">●</span> Evidence</span>
                <span><span className="gv-legend-dot-assumption">●</span> Assumption</span>
                <span><span className="gv-legend-dot-counter">●</span> Counter</span>
            </div>

            <div className="gv-hint">
                Click: select · Double-click: zoom to branch · Scroll: zoom · Drag: pan
            </div>
        </div>;
}
