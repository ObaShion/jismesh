import Testing
@testable import JISMesh
import MapKit

@Test func toMeshCode_validSamples() async throws {
    #expect(try JISMesh.toMeshCode(latitude: 35.0, longitude: 135.0, level: .level1).count == 4)
    #expect(try JISMesh.toMeshCode(latitude: 35.0, longitude: 135.0, level: .level3).count == 8)
}

@Test func toMeshCode_invalidInputs_throw() async throws {
    await #expect(throws: JISMeshAPIError.invalidCoordinate) {
        _ = try JISMesh.toMeshCode(latitude: 100.0, longitude: 0.0, level: .level1)
    }
}

@Test func toMeshBounds_invalidCode_throw() async throws {
    await #expect(throws: JISMeshAPIError.invalidCode) {
        _ = try JISMesh.toMeshBounds(code: "ABCD")
    }
}

@Test func bounds_shouldContainCenterPoint() async throws {
    let code = try JISMesh.toMeshCode(latitude: 35.6586, longitude: 139.7454, level: .level3)
    let b = try JISMesh.toMeshBounds(code: code)
    #expect(b.south < b.north)
    #expect(b.west < b.east)
    #expect(b.center.latitude > b.south && b.center.latitude < b.north)
    #expect(b.center.longitude > b.west && b.center.longitude < b.east)
}

@Test func swift_metal_consistency_sampleRegion() async throws {
    let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.0, longitude: 135.0), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    let codes = await MainActor.run { JISMesh.generateMeshCodes(region: region, level: .level3) }
    for c in codes.prefix(50) {
        _ = try JISMesh.toMeshBounds(code: c)
    }
    #expect(!codes.isEmpty)
}
