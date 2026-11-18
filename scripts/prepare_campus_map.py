#!/usr/bin/env python3
"""Acquire candidate OSM data or convert the existing trace. Never mark imports verified."""
import argparse
import datetime
import json
import math
from pathlib import Path
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
BBOX = '36.160,-86.837,36.173,-86.819'
QUERY = f'''[out:json][timeout:45];(way[highway~"^(footway|path|pedestrian|steps)$"]({BBOX});way[building]({BBOX});node[entrance]({BBOX});node[highway=crossing]({BBOX}););out body;>;out skel qt;'''


def distance(a, b):
    lat1, lat2 = map(math.radians, (a['latitude'], b['latitude']))
    dl = math.radians(b['longitude'] - a['longitude'])
    h = math.sin((lat2-lat1)/2)**2 + math.cos(lat1)*math.cos(lat2)*math.sin(dl/2)**2
    return 12742000 * math.asin(math.sqrt(min(1, h)))


def node(identifier, lat, lon, name='', entrance=False, place=None):
    return dict(id=identifier, name=name or identifier, coordinate=dict(latitude=lat, longitude=lon),
                isEntrance=entrance, placeID=place, verification='candidate')


def edge(identifier, a, b, source, tags=None):
    tags = tags or {}
    stairs = 'yes' if tags.get('highway') == 'steps' else 'unknown'
    # Missing attributes remain unknown, even on a mapped pedestrian path.
    if tags.get('stairs') == 'no': stairs = 'no'
    accessible = {'yes': 'yes', 'no': 'no', 'designated': 'yes'}.get(tags.get('wheelchair'), 'unknown')
    slope = None
    try:
        if tags.get('incline', '').endswith('%'): slope = float(tags['incline'][:-1])
    except ValueError:
        pass
    return dict(id=identifier, **{'from': a['id']}, to=b['id'], geometry=[a['coordinate'], b['coordinate']],
                lengthMeters=distance(a['coordinate'], b['coordinate']), bidirectional=tags.get('oneway:foot') != 'yes',
                stairs=stairs, crossing='yes' if tags.get('footway') == 'crossing' else 'unknown',
                accessible=accessible, surface=tags.get('surface'), slopePercent=slope,
                restricted=tags.get('foot') in ('no', 'private') or tags.get('access') in ('no', 'private'),
                verification='candidate', source=source)


def make_graph(identifier, name, demo, sources, nodes, edges):
    return dict(schemaVersion=1, id=identifier, name=name, version='2026-11-16',
                isDemonstration=demo, sources=sources, nodes=nodes, edges=edges)


def trace_graph():
    trace = json.loads((ROOT/'Argus/Resources/Routes/boyd_to_library.geojson').read_text())
    coords = next(f for f in trace['features'] if f['id']=='route')['geometry']['coordinates']
    nodes = [node(f'trace-{i}', lat, lon, 'Boyd Hall' if i==0 else 'TSU Library' if i==len(coords)-1 else '',
                  i in (0,len(coords)-1), 'boyd' if i==0 else 'library' if i==len(coords)-1 else None)
             for i,(lon,lat) in enumerate(coords)]
    source = 'Existing approximate screenshot trace; entrances unverified'
    sources = [dict(name=source, url='local:boyd_to_library.geojson',
                    license='Source imagery attribution retained; trace for project demonstration, redistribution rights not established',
                    retrieved='Existing project data, 2026-11-16')]
    return make_graph('boyd-library-demo','Boyd Hall to library — demonstration trace',True,sources,nodes,
                      [edge(f'trace-edge-{i}',a,b,source) for i,(a,b) in enumerate(zip(nodes,nodes[1:]))])


def osm_graph(raw):
    elements = raw['elements']
    raw_nodes = {e['id']:e for e in elements if e['type']=='node'}
    paths = [e for e in elements if e['type']=='way' and e.get('tags',{}).get('highway') in ('footway','path','pedestrian','steps')]
    used = {n for way in paths for n in way['nodes']}
    used.update(e['id'] for e in raw_nodes.values() if 'entrance' in e.get('tags',{}) or e.get('tags',{}).get('highway')=='crossing')
    nodes = {}
    for key in sorted(used):
        e = raw_nodes.get(key)
        if e is None: raise ValueError(f'Missing source node {key}')
        tags = e.get('tags',{})
        nodes[key] = node(f'osm-node-{key}',e['lat'],e['lon'],tags.get('name',''),'entrance' in tags)
    edges = []
    for way in sorted(paths,key=lambda w:w['id']):
        for i,(a,b) in enumerate(zip(way['nodes'],way['nodes'][1:])):
            tags = dict(way.get('tags',{}))
            if tags.get('oneway:foot') == '-1':
                a,b = b,a
                tags['oneway:foot']='yes'
            edges.append(edge(f"osm-way-{way['id']}-{i}",nodes[a],nodes[b],f"https://www.openstreetmap.org/way/{way['id']}",tags))
    sources = [dict(name='© OpenStreetMap contributors',url='https://www.openstreetmap.org/copyright',
                    license='Open Database License (ODbL) 1.0',retrieved=raw.get('osm3s',{}).get('timestamp_osm_base','unknown'))]
    # Only exact shared OSM node IDs connect paths. Buildings remain in the raw source inventory.
    return make_graph('tsu-osm-candidate','TSU OpenStreetMap candidate paths',False,sources,list(nodes.values()),edges)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fetch',action='store_true')
    parser.add_argument('--osm',type=Path)
    parser.add_argument('--trace',action='store_true')
    parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    folder=ROOT/'data/campus'
    folder.mkdir(parents=True,exist_ok=True)
    if args.fetch:
        (folder/'tsu.overpassql').write_text(QUERY+'\n')
        request=urllib.request.Request('https://overpass-api.de/api/interpreter',
                    data=urllib.parse.urlencode({'data':QUERY}).encode(),headers={'User-Agent':'Argus-campus-research/1.0'})
        with urllib.request.urlopen(request,timeout=55) as response: raw=json.load(response)
        (folder/'osm-source.json').write_text(json.dumps(raw,indent=2)+'\n')
        args.osm=folder/'osm-source.json'
    if args.trace:
        graph=trace_graph()
        output=args.output or ROOT/'Argus/Resources/CampusData/boyd_library_graph.json'
    elif args.osm:
        graph=osm_graph(json.loads(args.osm.read_text()))
        output=args.output or folder/'tsu_candidate_graph.json'
    else:
        parser.error('Choose --trace, --osm FILE, or --fetch')
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(graph,indent=2)+'\n')
    export_geojson(graph, output.with_suffix('.geojson'))
    print(f'{output}: {len(graph["nodes"])} nodes, {len(graph["edges"])} edges. All imported features are candidate.')

def export_geojson(graph, output):
    metadata={k:v for k,v in graph.items() if k not in ('nodes','edges')}
    features=[]
    for node in graph['nodes']:
        props=dict(node); c=props.pop('coordinate')
        features.append(dict(type='Feature',id=node['id'],properties=props,geometry=dict(type='Point',coordinates=[c['longitude'],c['latitude']])))
    for edge in graph['edges']:
        props=dict(edge); geometry=props.pop('geometry')
        features.append(dict(type='Feature',id=edge['id'],properties=props,geometry=dict(type='LineString',coordinates=[[c['longitude'],c['latitude']] for c in geometry])))
    output.write_text(json.dumps(dict(type='FeatureCollection',campusGraph=metadata,features=features),indent=2)+'\n')

if __name__=='__main__': main()
