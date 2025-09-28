//
//  JISMeshCore.swift
//  JapaneseMesh
//
//  Created by 大場史温 on 2025/09/23.
//

import Foundation
import CoreLocation
import MapKit

// MARK: MeshLevel (JIS X 0410)
public enum JISMeshLevel: Int, CaseIterable {
    case level1 = 1, level2, level3, level4, level5, level6
}

// MARK: BoundingBox
public struct BoundingBox {
    public let south, west, north, east: Double
    public let center: CLLocationCoordinate2D
    
    public var topLeft: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: north, longitude: west) }
    public var topRight: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: north, longitude: east) }
    public var bottomLeft: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: south, longitude: west) }
    public var bottomRight: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: south, longitude: east) }
    
    public init(south: Double, west: Double, north: Double, east: Double, center: CLLocationCoordinate2D) {
        self.south = south
        self.west = west
        self.north = north
        self.east = east
        self.center = center
    }
}

/// Reference:
/// - https://www.stat.go.jp/data/mesh/pdf/gaiyo1.pdf
public struct JISMeshCore {
    private static func appendQuad(code: inout String, latRem: inout Double, lonRem: inout Double, cellLat: inout Double, cellLon: inout Double) {
        var digit: Int = 0
        let halfCellLat: Double = cellLat / 2.0
        let halfCellLon: Double = cellLon / 2.0
        
        let isNorth: Bool = latRem >= halfCellLat
        let isEast: Bool = lonRem >= halfCellLon
        
        if (!isEast && !isNorth) {
            digit = 1
        } else if (isEast && !isNorth) {
            digit = 2
            lonRem -= halfCellLon
        } else if (!isEast && isNorth) {
            digit = 3
            latRem -= halfCellLat
        } else {
            digit = 4
            latRem -= halfCellLat
            lonRem -= halfCellLon
        }
        
        code = String(Int(code)! * 10 + digit)
        cellLat /= 2.0
        cellLon /= 2.0
    }
    
    // MARK: toMeshCode
    public static func toMeshCode(latitude: Double, longitude: Double, level: JISMeshLevel) -> String {
        // precondition((-90...90).contains(latitude) && (-180...180).contains(longitude), "invalid coordinate")
        
        /// level1
        let p_lat = Int(floor(latitude * 1.5))
        let p_lon = Int(floor(longitude - 100.0))
        var code = String(format: "%02d%02d", p_lat, p_lon)
        if level == .level1 { return code }
        
        /// 1次メッシュ内の相対的な緯度経度を計算
        var lat_rem = latitude - Double(p_lat) / 1.5
        var lon_rem = longitude - floor(longitude)
        
        /// level2
        let s_lat = floor(lat_rem / (1.0 / 12.0))
        let s_lon = floor(lon_rem / (1.0 / 8.0))
        code += String(format: "%1d%1d", s_lat, s_lon)
        if level == .level2 { return code }
        
        /// 2次メッシュ内の相対的な緯度経度を計算
        lat_rem -= Double(s_lat) * (1.0 / 12.0)
        lon_rem -= Double(s_lon) * (1.0 / 8.0)
        
        /// level3
        let t_lat = floor(lat_rem / (1.0 / 120.0))
        let t_lon = floor(lon_rem / (1.0 / 80.0))
        code += String(format: "%1d%1d", t_lat, t_lon)
        if level == .level3 { return code }
        
        /// 3次メッシュ内の相対的な緯度経度を計算
        var lat_rem_3 = lat_rem - Double(t_lat) * (1.0 / 120.0)
        var lon_rem_3 = lon_rem - Double(t_lon) * (1.0 / 80.0)
        
        var cellLat = 1.0 / 120.0
        var cellLon = 1.0 / 80.0
        
        
        /// level4
        appendQuad(code: &code, latRem: &lat_rem_3, lonRem: &lon_rem_3, cellLat: &cellLat, cellLon: &cellLon)
        if level == .level4 { return code }
        
        
        /// level5
        appendQuad(code: &code, latRem: &lat_rem_3, lonRem: &lon_rem_3, cellLat: &cellLat, cellLon: &cellLon)
        if level == .level5 { return code }
        
        /// level6
        appendQuad(code: &code, latRem: &lat_rem_3, lonRem: &lon_rem_3, cellLat: &cellLat, cellLon: &cellLon)
        return code
    }
    
    // MARK: toMeshBounds
    public static func toMeshBounds(code: String) -> BoundingBox {
        // precondition(code.count >= 4, "Code must have at least 4 digits")
        let latIndex1 = Int(code.prefix(2)) ?? 0
        let lonIndex1 = Int(code.dropFirst(2).prefix(2)) ?? 0
        var latSouth = Double(latIndex1) / 1.5
        var lonWest = 100 + Double(lonIndex1)
        var cellLat = 2.0 / 3.0
        var cellLon = 1.0
        
        /// level2
        if code.count >= 6 {
            let s_lat = Int(code.dropFirst(4).prefix(1)) ?? 0
            let s_lon = Int(code.dropFirst(5).prefix(1)) ?? 0
            latSouth += Double(s_lat) * (cellLat / 8.0)
            lonWest += Double(s_lon) * (cellLon / 8.0)
            cellLat /= 8.0
            cellLon /= 8.0
        }
        
        
        /// level3
        if code.count >= 8 {
            let t_lat = Int(code.dropFirst(6).prefix(1)) ?? 0
            let t_lon = Int(code.dropFirst(7).prefix(1)) ?? 0
            latSouth += Double(t_lat) * (cellLat / 10.0)
            lonWest += Double(t_lon) * (cellLon / 10.0)
            cellLat /= 10.0
            cellLon /= 10.0
        }
        
        /// level4~6
        if code.count > 8 {
            for i in 8..<(code.count) {
                let idx = code.index(code.startIndex, offsetBy: i)
                let digit = Int(String(code[idx])) ?? 1
                
                switch digit {
                case 1:
                    break
                case 2:
                    lonWest += cellLon / 2.0
                case 3:
                    latSouth += cellLat / 2.0
                case 4:
                    latSouth += cellLat / 2.0
                    lonWest += cellLon / 2.0
                default:
                    break
                }
                cellLat /= 2.0
                cellLon /= 2.0
            }
        }
        
        let latNorth = latSouth + cellLat
        let lonEast = lonWest + cellLon
        let center = CLLocationCoordinate2D(latitude: (latSouth + latNorth) / 2.0, longitude: (lonWest + lonEast) / 2.0)
        
        return BoundingBox(south: latSouth, west: lonWest, north: latNorth, east: lonEast, center: center)
    }
    
    // MARK: generateMeshCodes
    @MainActor
    public static func generateMeshCodes(region: MKCoordinateRegion, level: JISMeshLevel) -> [String] {
        return JISMeshMeshCodesMetal.shared.calculateMesh(region: region, level: level)
    }
    
    public static func polygons(for codes: [String]) -> [MKPolygon] {
        codes.map { code in
            let b = toMeshBounds(code: code)
            let coords = [
                CLLocationCoordinate2D(latitude: b.south, longitude: b.west),
                CLLocationCoordinate2D(latitude: b.south, longitude: b.east),
                CLLocationCoordinate2D(latitude: b.north, longitude: b.east),
                CLLocationCoordinate2D(latitude: b.north, longitude: b.west)
            ]
            return MKPolygon(coordinates: coords, count: coords.count)
        }
    }
    
    public static func stepSize(for level: JISMeshLevel) -> (Double, Double) {
        let baseLat = 2.0 / 3.0
        let baseLon = 1.0
        switch level {
        case .level1:
            return (baseLat, baseLon)
        case .level2:
            return (baseLat / 8.0, baseLon / 8.0)
        case .level3:
            return (baseLat / 8.0 / 10.0, baseLon / 8.0 / 10.0)
        case .level4:
            return (baseLat / 8.0 / 10.0 / 2.0, baseLon / 8.0 / 10.0 / 2.0)
        case .level5:
            return (baseLat / 8.0 / 10.0 / 4.0, baseLon / 8.0 / 10.0 / 4.0)
        case .level6:
            return (baseLat / 8.0 / 10.0 / 8.0, baseLon / 8.0 / 10.0 / 8.0)
        }
    }
    
    public static func codeLength(for level: JISMeshLevel) -> Int {
        switch level {
        case .level1: return 4
        case .level2: return 6
        case .level3: return 8
        case .level4: return 9
        case .level5: return 10
        case .level6: return 11
        }
    }
    
    public static func format(code: Int64, level: JISMeshLevel) -> String {
        let len = codeLength(for: level)
        let raw = String(code)
        if raw.count >= len { return raw }
        return String(repeating: "0", count: len - raw.count) + raw
    }
}
