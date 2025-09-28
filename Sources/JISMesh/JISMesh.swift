// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import MapKit

public enum JISMesh {
    public static func stepSize(for level: JISMeshLevel) -> (Double, Double) {
        return JISMeshCore.stepSize(for: level)
    }
    
    public static func codeLength(for level: JISMeshLevel) -> Int {
        return JISMeshCore.codeLength(for: level)
    }
    
    public static func format(code: Int64, level: JISMeshLevel) -> String {
        return JISMeshCore.format(code: code, level: level)
    }
    
    public static func toMeshCode(latitude: Double, longitude: Double, level: JISMeshLevel) throws -> String {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw JISMeshAPIError.invalidCoordinate
        }
        return JISMeshCore.toMeshCode(latitude: latitude, longitude: longitude, level: level)
    }
    
    public static func toMeshBounds(code: String) throws -> BoundingBox {
        guard code.count >= 4, code.allSatisfy({ $0.isNumber }) else {
            throw JISMeshAPIError.invalidCode
        }
        return JISMeshCore.toMeshBounds(code: code)
    }
    
    @MainActor
    public static func generateMeshCodes(region: MKCoordinateRegion, level: JISMeshLevel) -> [String] {
        return JISMeshCore.generateMeshCodes(region: region, level: level)
    }
}
