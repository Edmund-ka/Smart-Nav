#!/usr/bin/env python3
"""Run the iPhone's production graph loader and validator against JSON or GeoJSON files."""
from pathlib import Path
import subprocess
import sys
import tempfile
ROOT=Path(__file__).resolve().parents[1]
SOURCES=['MapGeometry.swift','CampusGraph.swift','GraphValidator.swift','GraphFileFormat.swift']
MAIN='''import Foundation
@main struct Validate {
 static func main() {
  var failed = false
  for path in CommandLine.arguments.dropFirst() {
   print("\\nDataset: " + path)
   do {
    let graph = try GraphFileFormat.decode(Data(contentsOf: URL(fileURLWithPath: path)))
    let result = GraphValidator.validate(graph)
    print("\\(graph.nodes.count) nodes · \\(graph.edges.count) edges")
    print(result.summary)
    failed = failed || !result.errors.isEmpty
   } catch { print("ERROR: \\(error)"); failed = true }
  }
  if failed { exit(1) }
 }
}
'''
with tempfile.TemporaryDirectory(prefix='argus-graph-validation-') as folder:
    folder=Path(folder)
    source=folder/'Validate.swift';source.write_text(MAIN)
    exe=folder/'validate'
    subprocess.run(['swiftc','-module-cache-path',str(folder/'cache'),*[str(ROOT/'Argus/Shared/CampusMap'/s) for s in SOURCES],str(source),'-o',str(exe)],check=True)
    result=subprocess.run([str(exe),*sys.argv[1:]])
    sys.exit(result.returncode)
