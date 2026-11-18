"""Importer tests use synthetic OSM-shaped fixtures, never invented campus observations."""
import importlib.util
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('prepare',Path(__file__).parents[1]/'scripts/prepare_campus_map.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class MapImportTests(unittest.TestCase):
    def test_provenance_unknowns_and_no_proximity_connections(self):
        raw={'elements':[{'type':'node','id':i,'lat':36+i*0.00001,'lon':-86} for i in range(1,5)]+
             [{'type':'way','id':10,'nodes':[1,2],'tags':{'highway':'footway'}},
              {'type':'way','id':11,'nodes':[3,4],'tags':{'highway':'steps','oneway:foot':'-1'}},
              {'type':'way','id':12,'nodes':[1,3,4,1],'tags':{'building':'yes'}}]}
        graph=m.osm_graph(raw)
        self.assertEqual(len(graph['edges']),2)
        self.assertTrue(all(e['verification']=='candidate' for e in graph['edges']))
        self.assertEqual(graph['edges'][0]['accessible'],'unknown')
        self.assertEqual(graph['edges'][0]['stairs'],'unknown')
        self.assertEqual(graph['edges'][1]['stairs'],'yes')
        self.assertEqual(graph['edges'][1]['from'],'osm-node-4')
        self.assertFalse(graph['edges'][1]['bidirectional'])
    def test_missing_source_node_fails(self):
        with self.assertRaises(ValueError):
            m.osm_graph({'elements':[{'type':'way','id':1,'nodes':[1,2],'tags':{'highway':'path'}}]})

if __name__=='__main__':unittest.main()
