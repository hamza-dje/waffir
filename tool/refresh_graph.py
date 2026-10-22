"""Refresh the local app map with deterministic AST extraction. Run with Python 3.13."""
from pathlib import Path
import json
import hashlib
import time
from graphify.extract import extract
from graphify.detect import detect
from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
from graphify.analyze import god_nodes, surprising_connections
from graphify.report import generate
from graphify.export import to_json

root = Path('lib').resolve()
out = Path('graphify-out')
raw = extract(list(root.glob('*.dart')), cache_root=root)
out.joinpath('manifest.json').write_text(json.dumps({
    p.name: {'mtime': p.stat().st_mtime, 'seen': time.time(),
             'ast_hash': hashlib.md5(p.read_bytes()).hexdigest(), 'semantic_hash': None}
    for p in root.glob('*.dart')}, indent=2), encoding='utf-8')
out.joinpath('raw-extraction.json').write_text(json.dumps(raw, indent=2), encoding='utf-8')
graph = build_from_json(raw, root=str(root), directed=False)
assert graph.number_of_nodes() > 0
communities = cluster(graph)
labels = {key: ' / '.join(sorted({Path(graph.nodes[n].get('source_file') or 'app').stem for n in members}))
          for key, members in communities.items()}
to_json(graph, communities, str(out/'graph.json'), force=True, community_labels=labels)
report = generate(graph, communities, score_all(graph, communities), labels,
                  god_nodes(graph), surprising_connections(graph, communities),
                  detect(root), {'input_tokens': 0, 'output_tokens': 0}, str(root))
Path('.codex/graphify-out/GRAPH_REPORT.md').write_text(report, encoding='utf-8')
out.joinpath('GRAPH_HEALTH.txt').write_text(
    f'AST extraction only. {graph.number_of_nodes()} nodes; {graph.number_of_edges()} graph edges.\n'
    f'Raw edges: {len(raw["edges"])}. Same-endpoint relations may be merged by graphify; raw extraction is retained.\n'
    'No semantic agent calls or model tokens were used.\n', encoding='utf-8')
print(f'Refreshed app graph: {graph.number_of_nodes()} nodes, {graph.number_of_edges()} edges.')
