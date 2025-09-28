//
//  JISMeshMapKit.swift
//  JapaneseMesh
//
//  Created by 大場史温 on 2025/09/24.
//

import Foundation
import MapKit

public extension MKMapView {
    func addJISMesh(region: MKCoordinateRegion? = nil, level: JISMeshLevel) {
        let targetRegion = region ?? MKCoordinateRegion(center: self.centerCoordinate,
                                                        span: self.region.span)
        let polys = JISMeshCore.polygons(for: JISMesh.generateMeshCodes(region: targetRegion, level: level))
        self.addOverlays(polys)
    }
}
