//
//  JISMEeshError.swift
//  JapaneseMesh
//
//  Created by 大場史温 on 2025/09/24.
//

import Foundation

public enum MetalError: Error {
    case noDevice
    case commandQueueFailed
    case libraryNotFound
    case functionNotFound
}

public enum JISMeshAPIError: Error, Equatable {
    case invalidCoordinate
    case invalidCode
}
