"""Branch context system for the argument graph.
Stores per-node LLM working history so switching branches doesn't lose context."""


"Stores one revision event for a node"
obj RevisionEntry {
    has timestamp: str,
        action: str,
        before_text: str,
        after_text: str,
        llm_reasoning: str;
}


"Per-node context that travels with the node"
obj NodeContext {
    has node_id: str,
        revision_history: list[RevisionEntry] = [],
        branch_summary: str = "",
        working_notes: str = "";
}


"Manages all branch contexts for the session"
obj BranchContextStore {
    has contexts: dict[str, NodeContext] = {};

    def get_context(node_id: str) -> NodeContext {
        if node_id not in self.contexts {
            self.contexts[node_id] = NodeContext(node_id=node_id);
        }
        return self.contexts[node_id];
    }

    """Walk from node up to root, collect all context in the subtree.
    Returns a string the LLM can use to understand the branch state."""
    def gather_branch_context(
        node_id: str,
        nodes: list,
        edges: list
    ) -> str {
        parent_map: dict[str, str] = {};
        children_map: dict[str, list[str]] = {};
        for e in edges {
            if e["type"] in ["supports", "depends_on"] {
                parent_map[e["from_id"]] = e["to_id"];
                if e["to_id"] not in children_map {
                    children_map[e["to_id"]] = [];
                }
                children_map[e["to_id"]].append(e["from_id"]);
            }
        }

        branch_root = node_id;
        visited: list[str] = [];
        current = node_id;
        while current in parent_map and current not in visited {
            visited.append(current);
            current = parent_map[current];
            branch_root = current;
        }

        subtree_ids: list[str] = [];
        queue: list[str] = [branch_root];
        while queue {
            nid = queue.pop(0);
            subtree_ids.append(nid);
            if nid in children_map {
                for child in children_map[nid] {
                    queue.append(child);
                }
            }
        }

        node_map: dict[str, str] = {};
        for n in nodes {
            node_map[n["id"]] = f"[{n['type']}] {n['text']}";
        }

        context_parts: list[str] = ["=== Branch Context ==="];
        context_parts.append(f"Branch root: {branch_root}");
        context_parts.append(f"Selected node: {node_id}");
        context_parts.append(f"Nodes in branch: {len(subtree_ids)}");
        context_parts.append("");

        for sid in subtree_ids {
            label = node_map.get(sid, sid);
            context_parts.append(f"  {sid}: {label}");
            ctx = self.get_context(sid);
            if ctx.working_notes {
                context_parts.append(f"    [LLM notes]: {ctx.working_notes}");
            }
            if ctx.revision_history {
                last_rev = ctx.revision_history[-1];
                context_parts.append(f"    [Last revision]: {last_rev.action}");
            }
        }

        return "\n".join(context_parts);
    }

    def save_working_notes(node_id: str, notes: str) -> None {
        ctx = self.get_context(node_id);
        ctx.working_notes = notes;
    }

    def record_revision(
        node_id: str,
        action: str,
        before_text: str,
        after_text: str,
        llm_reasoning: str
    ) -> None {
        ctx = self.get_context(node_id);
        import from datetime { datetime }
        ctx.revision_history.append(
            RevisionEntry(
                timestamp=datetime.now().isoformat(),
                action=action,
                before_text=before_text,
                after_text=after_text,
                llm_reasoning=llm_reasoning
            )
        );
    }
}
