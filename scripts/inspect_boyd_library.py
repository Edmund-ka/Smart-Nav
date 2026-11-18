#!/usr/bin/env python3
"""Read-only candidate topology audit and local survey map; never creates graph connections."""
import collections
import csv
import heapq
import html
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/semester-one'

def distance(a, b):
    p, q = math.radians(a['latitude']), math.radians(b['latitude'])
    return 6371000 * 2 * math.asin(min(1, math.sqrt(math.sin((p-q)/2)**2 + math.cos(p)*math.cos(q)*math.sin(math.radians(a['longitude']-b['longitude'])/2)**2)))

def main():
    graph = json.loads((ROOT/'data/campus/tsu_candidate_graph.json').read_text())
    demo = json.loads((ROOT/'Argus/Resources/CampusData/boyd_library_graph.json').read_text())
    walk = json.loads((ROOT/'Argus/Resources/Recordings/BoydWalkSample.json').read_text())
    nodes = {n['id']: n for n in graph['nodes']}
    adjacent = collections.defaultdict(set)
    directed = collections.defaultdict(list)
    for e in graph['edges']:
        adjacent[e['from']].add(e['to']); adjacent[e['to']].add(e['from'])
        if e['restricted'] or e['accessible'] == 'no':
            continue
        cost=e['lengthMeters']*(1.2 if e['crossing']=='yes' else 1)*(1.3 if e.get('surface') in ['gravel','unpaved','cobblestone','ground'] else 1)*(1.4 if abs(e.get('slopePercent') or 0)>5 else 1)
        directed[e['from']].append((e['to'],cost,e))
        if e['bidirectional']: directed[e['to']].append((e['from'],cost,e))
    components=[]; unseen=set(nodes)
    while unseen:
        seed=min(unseen); stack=[seed]; found=set()
        while stack:
            n=stack.pop()
            if n in found: continue
            found.add(n); stack.extend(adjacent[n]-found)
        unseen-=found; components.append(found)
    components.sort(key=lambda c: (-len(c),min(c)))
    membership={n:i+1 for i,c in enumerate(components) for n in c}
    ends=[demo['nodes'][0],demo['nodes'][-1]]
    nearby=[]
    lines=['# Boyd Hall–library candidate graph inspection','', 'Generated from the preserved local OSM import. Components are weak/undirected connectivity, not proof of a legal pedestrian route. IDs C1… are sorted by descending node count. No graph data is modified.','',f"{len(nodes)} nodes; {len(graph['edges'])} edges; {len(components)} weak components; {sum(not adjacent[n] for n in nodes)} isolated nodes.",'','| Component | Nodes | Edges |','| --- | ---: | ---: |']
    for i,c in enumerate(components,1):
        lines.append(f"| C{i} | {len(c)} | {sum(e['from'] in c for e in graph['edges'])} |")
    lines += ['', '## Candidate endpoint associations', '', 'The Boyd/library anchors come from the approximate demonstration trace, not surveyed doors. Nearest nodes below are inspection targets only; no entrance connector is implied.', '', '| Anchor | Candidate node | Distance (m) | Component | Degree |', '| --- | --- | ---: | --- | ---: |']
    for end in ends:
        nearest=sorted(nodes, key=lambda n: distance(end['coordinate'],nodes[n]['coordinate']))[:5]
        nearby.append(nearest[0])
        for n in nearest: lines.append(f"| {end['name']} | {n} | {distance(end['coordinate'],nodes[n]['coordinate']):.2f} | C{membership[n]} | {len(adjacent[n])} |")
    # Traverse only existing permitted directed edges; nearest endpoint associations are NOT added edges.
    start,end=nearby; queue=[(0,start)]; costs={start:0}; previous={}
    while queue:
        cost,n=heapq.heappop(queue)
        if cost!=costs[n]: continue
        if n==end: break
        for other,w,e in directed[n]:
            if cost+w<costs.get(other,float('inf')):
                costs[other]=cost+w; previous[other]=(n,e); heapq.heappush(queue,(cost+w,other))
    path=[]
    if end in costs:
        n=end
        while n!=start:
            n,e=previous[n]; path.append(e)
        path.reverse()
    lines += ['', '## Existing candidate path', '', f"Nearest-node path: {len(path)} edges, {sum(e['lengthMeters'] for e in path):.1f} m; weighted cost {costs.get(end, float('inf')):.1f}. This excludes the unverified anchor-to-node gaps and does not establish door access." if path else 'No permitted directed route exists between the nearest candidate nodes. Do not bridge this failure automatically.', '', '| Edge | From | To | Stairs | Access | Source |', '| --- | --- | --- | --- | --- | --- |']
    for e in path: lines.append(f"| {e['id']} | {e['from']} | {e['to']} | {e['stairs']} | {e['accessible']} | {e['source']} |")
    # Small, explicit corridor rather than every pair of nodes across campus.
    coords=[n['coordinate'] for n in demo['nodes']]
    bounds=(min(p['longitude'] for p in coords)-.0005,max(p['longitude'] for p in coords)+.0005,min(p['latitude'] for p in coords)-.0004,max(p['latitude'] for p in coords)+.0004)
    def inside(p): return bounds[0]<=p['longitude']<=bounds[1] and bounds[2]<=p['latitude']<=bounds[3]
    local=[n for n in nodes if inside(nodes[n]['coordinate'])]
    gaps=[]
    for i,a in enumerate(local):
        for b in local[i+1:]:
            d=distance(nodes[a]['coordinate'],nodes[b]['coordinate'])
            if membership[a]!=membership[b] and d<=10: gaps.append((d,a,b))
    gaps.sort()
    lines+=['','## Nearby disconnected candidates','',f"Within the illustrated corridor: {len(local)} nodes across components {sorted(set(membership[n] for n in local))}; {len(gaps)} cross-component node pairs within 10 m. Proximity can represent a wall, stairs, separate levels, disconnected door records, or missing map topology; it does not establish a missing physical connection.",'','| Separation (m) | Node A / component | Node B / component |','| ---: | --- | --- |']
    for d,a,b in gaps: lines.append(f'| {d:.2f} | {a} / C{membership[a]} | {b} / C{membership[b]} |')
    lines+=['','## Missing evidence','', '- No Boyd/library `placeID` association exists in the candidate graph unless listed below. A named building footprint is not a verified entrance.',f"- Named entrance records: {[(n['id'],n.get('name'),n.get('placeID')) for n in nodes.values() if n.get('placeID')] or 'none'}.", '- Survey both endpoint-to-path connections, every route junction, steps/ramp alternatives and destination door before constructing an approved route.', '- Record shared physical junction identity, direction, level, restriction, surface, width, slope, curb cuts and photographs. Retain source IDs and observer/date metadata.', '- Check apparent gaps on foot and against independent evidence. Only add an edge after documenting the actual walkable segment; never join by distance alone.', '', 'Map: `BOYD_LIBRARY_SURVEY.svg`. Full source attribution: © OpenStreetMap contributors, ODbL 1.0; see `data/campus/README.md`. The overlay recording is observational, not surveyed truth.']
    (OUT/'CAMPUS_GRAPH_REVIEW.md').write_text('\n'.join(lines)+'\n')
    # Standalone SVG in local coordinates, no remote tiles or live location transmission.
    width,height=1000,1000
    scale=min(880/((bounds[1]-bounds[0])*math.cos(math.radians(36.165))),580/(bounds[3]-bounds[2]))
    def xy(p): return (60+(p['longitude']-bounds[0])*math.cos(math.radians(36.165))*scale,100+(bounds[3]-p['latitude'])*scale)
    def points(ps): return ' '.join(f'{x:.1f},{y:.1f}' for x,y in map(xy,ps))
    svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}"><rect width="100%" height="100%" fill="#faf9f6"/>','<g font-family="Arial" fill="#17243b"><text x="40" y="35" font-size="24">Boyd Hall–library: field survey working map</text><text x="40" y="62" font-size="14">Unverified geometry • North ↑ • existing candidate paths only • no inferred connectors</text>']
    colors=['#809bb5','#c56f25','#8d62ae','#378c75']
    for e in graph['edges']:
        if any(inside(p) for p in e['geometry']):
            svg.append(f'<polyline points="{points(e["geometry"])}" fill="none" stroke="{colors[(membership[e["from"]]-1)%4]}" stroke-width="2"><title>{html.escape(e["id"])} C{membership[e["from"]]}</title></polyline>')
    for e in path: svg.append(f'<polyline points="{points(e["geometry"])}" fill="none" stroke="#207c38" stroke-width="5" opacity=".7"/>')
    svg.append(f'<polyline points="{points(coords)}" fill="none" stroke="#df4270" stroke-width="3" stroke-dasharray="8 5"/>')
    svg.append(f'<polyline points="{points(walk["readings"])}" fill="none" stroke="#006cbb" stroke-width="1.5" opacity=".65"/>')
    for n in local:
        if len(adjacent[n])<=1:
            x,y=xy(nodes[n]['coordinate']);svg.append(f'<circle cx="{x}" cy="{y}" r="3" fill="#d17622"><title>{n} C{membership[n]} degree {len(adjacent[n])}</title></circle>')
    for n in ends:
        x,y=xy(n['coordinate']);svg.append(f'<circle cx="{x}" cy="{y}" r="6" fill="#df4270"/><text x="{x-150}" y="{y-22}" font-size="15">{n["name"]} approximate anchor</text>')
    for index, mark in enumerate(walk['marks'], 1):
        fix=min(walk['readings'],key=lambda f:abs(f['time']-mark['time'])); x,y=xy(fix)
        dx,dy=[(12,25),(12,0),(-25,-12),(-15,0),(8,12)][index-1]
        svg.append(f'<circle cx="{x}" cy="{y}" r="5" fill="#006cbb"/><text x="{x+dx}" y="{y+dy}" font-size="13" font-weight="bold">{index}</text>')
        svg.append(f'<text x="650" y="{100+index*22}" font-size="13">{index}. {mark["label"]} at {mark["time"]-walk["started"]:.1f}s</text>')
    bar=50/111194.9*scale
    svg+= [f'<path d="M60 690 h{bar:.1f}" stroke="#17243b" stroke-width="3"/><text x="60" y="712" font-size="13">50 m (approximate)</text>', '<text x="40" y="745" font-size="14">Pink dashed: demo reference · Blue: recorded fixes · Green: candidate nearest-node path</text>', '<text x="40" y="770" font-size="12">Orange dots: degree 0/1 nodes · © OpenStreetMap contributors, ODbL 1.0 · Observations are not verification</text></g></svg>']
    (OUT/'BOYD_LIBRARY_SURVEY.svg').write_text('\n'.join(svg))
    print(f'Wrote graph review and map: {len(components)} components, {len(gaps)} nearby pairs, {len(path)} path edges')

if __name__=='__main__': main()
