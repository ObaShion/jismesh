# JISMesh

JIS X 0410規格に基づく日本のメッシュコードを扱うSwiftライブラリです。緯度経度からメッシュコードへの変換、メッシュコードから境界の取得、Metalを使用したGPU並列処理による大量のメッシュコード生成をサポートしています。

## 特徴

- **JIS X 0410準拠**: 日本の標準的なメッシュコード規格に完全準拠
- **6段階のメッシュレベル**: 1次メッシュ（約80km）から6次メッシュ（約100m）まで対応
- **Metal並列処理**: GPUを使用した高速なメッシュコード生成
- **MapKit統合**: MKCoordinateRegionとMKPolygonをサポート

## 対応プラットフォーム

- iOS 15.0+
- macOS 12.0+
- Mac Catalyst 15.0+

## インストール

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/JISMesh.git", from: "1.0.0")
]
```

## 基本的な使用方法

### 緯度経度からメッシュコードへの変換

```swift
import JISMesh

// 東京駅の座標から3次メッシュコードを取得
let meshCode = try JISMesh.toMeshCode(
    latitude: 35.6812, 
    longitude: 139.7671, 
    level: .level3
)
print(meshCode) // "53393599"
```

### メッシュコードから境界の取得

```swift
// メッシュコードから境界情報を取得
let bounds = try JISMesh.toMeshBounds(code: "53393599")
print("南西: (\(bounds.south), \(bounds.west))")
print("北東: (\(bounds.north), \(bounds.east))")
print("中心: (\(bounds.center.latitude), \(bounds.center.longitude))")
```

### 地域内のメッシュコード一括生成

```swift
import MapKit

// 指定した地域内のメッシュコードを一括生成
let region = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
)

let meshCodes = JISMesh.generateMeshCodes(region: region, level: .level3)
print("生成されたメッシュコード数: \(meshCodes.count)")
```

### MapKitとの統合

```swift
// メッシュコードからMKPolygonを生成
let polygons = JISMeshCore.polygons(for: meshCodes)

// MapViewに追加
mapView.addOverlays(polygons)
```

## API リファレンス

### JISMesh

#### `toMeshCode(latitude:longitude:level:)`
緯度経度からメッシュコードを生成します。

- **Parameters**:
  - `latitude`: 緯度 (-90.0 〜 90.0)
  - `longitude`: 経度 (-180.0 〜 180.0)
  - `level`: メッシュレベル
- **Returns**: メッシュコード文字列
- **Throws**: `JISMeshAPIError.invalidCoordinate` (座標が無効な場合)

#### `toMeshBounds(code:)`
メッシュコードから境界情報を取得します。

- **Parameters**:
  - `code`: メッシュコード文字列（4桁以上、数字のみ）
- **Returns**: `BoundingBox` 構造体
- **Throws**: `JISMeshAPIError.invalidCode` (コードが無効な場合)

#### `generateMeshCodes(region:level:)`
指定した地域内のメッシュコードを一括生成します。

- **Parameters**:
  - `region`: `MKCoordinateRegion`
  - `level`: メッシュレベル
- **Returns**: メッシュコード文字列の配列

### JISMeshCore

#### `stepSize(for:)`
指定したメッシュレベルのステップサイズを取得します。

#### `codeLength(for:)`
指定したメッシュレベルのコード長を取得します。

#### `format(code:level:)`
数値を指定したメッシュレベルの形式にフォーマットします。

#### `polygons(for:)`
メッシュコードの配列から`MKPolygon`の配列を生成します。

## エラーハンドリング

```swift
do {
    let meshCode = try JISMesh.toMeshCode(latitude: 35.0, longitude: 135.0, level: .level1)
    print("メッシュコード: \(meshCode)")
} catch JISMeshAPIError.invalidCoordinate {
    print("無効な座標です")
} catch JISMeshAPIError.invalidCode {
    print("無効なメッシュコードです")
} catch {
    print("その他のエラー: \(error)")
}
```

## ライセンス

MIT License

## 参考資料

- [JIS X 0410: 地域メッシュコード](https://www.stat.go.jp/data/mesh/pdf/gaiyo1.pdf)
- [総務省統計局: 地域メッシュ統計](https://www.stat.go.jp/data/mesh/)

