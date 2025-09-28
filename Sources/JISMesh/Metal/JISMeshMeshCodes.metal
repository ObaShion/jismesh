//
//  JISMeshMeshCodes.metal
//  JapaneseMesh
//
//  Created by 大場史温 on 2025/08/27.
//

#include <metal_stdlib>
using namespace metal;

// <input> buffer(0)
typedef struct {
    float2 regionMin;
    float2 stepSize;
    uint2 gridSize;
    int level;
} JISMeshMeshCodesParameter;

// <output> buffer(1)
typedef struct {
    long code;
} JISMeshMeshCodesReturn;


/// Reference:
///     - https://www.stat.go.jp/data/mesh/pdf/gaiyo1.pdf
///     (表６ 分割地域メッシュの地域メッシュ・コードの付け方を参考)
void append_quad(thread long &code, thread float &lat_rem, thread float &lon_rem, thread float &cell_lat, thread float &cell_lon) {
    int digit;
    float half_cell_lat = cell_lat / 2.0f;
    float half_cell_lon = cell_lon / 2.0f;

    bool is_north = lat_rem >= half_cell_lat;
    bool is_east = lon_rem >= half_cell_lon;

    if (!is_east && !is_north) { /// 南西
        digit = 1;
    } else if (is_east && !is_north) { /// 南東
        digit = 2;
        lon_rem -= half_cell_lon;
    } else if (!is_east && is_north) { /// 北西
        digit = 3;
        lat_rem -= half_cell_lat;
    } else { /// 北東
        digit = 4;
        lat_rem -= half_cell_lat;
        lon_rem -= half_cell_lon;
    }

    code = code * 10 + digit;
    cell_lat /= 2.0f;
    cell_lon /= 2.0f;
}

/// Reference:
///     - https://www.stat.go.jp/data/mesh/pdf/gaiyo1.pdf
long to_mesh_code(float lat, float lon, int level) {
    /// level1
    int p_lat = int(floor(lat * 1.5));
    int p_lon = int(floor(lon - 100.0));
    long code = p_lat * 100 + p_lon;
    if (level == 1) {
        return code;
    }
    
    /// 1次メッシュ内の相対的な緯度経度を計算
    float lat_rem = lat - (float)p_lat / 1.5f;
    float lon_rem = lon - floor(lon);
    
    /// level2
    int s_lat = floor(lat_rem / (1.0f / 12.0f));
    int s_lon = floor(lon_rem / (1.0f / 8.0f));
    code = code * 100 + s_lat * 10 + s_lon;
    if (level == 2) {
        return code;
    }
    
    /// 2次メッシュ内の相対的な緯度経度を計算
    lat_rem -= (float)s_lat * (1.0f / 12.0f);
    lon_rem -= (float)s_lon * (1.0f / 8.0f);
    
    /// level3
    int t_lat = floor(lat_rem / (1.0f / 120.0f));
    int t_lon = floor(lon_rem / (1.0f / 80.0f));
    code = code * 100 + t_lat * 10 + t_lon;
    if (level == 3) {
        return code;
    }
    
    /// 3次メッシュ内の相対的な緯度経度を計算
    float lat_rem_3 = lat_rem - (float)t_lat * (1.0f / 120.0f);
    float lon_rem_3 = lon_rem - (float)t_lon * (1.0f / 80.0f);
    
    /// 3次メッシュの幅
    float cell_lat = 1.0f / 120.0f;
    float cell_lon = 1.0f / 80.0f;
    
    /// level4
    append_quad(code, lat_rem_3, lon_rem_3, cell_lat, cell_lon);
    if (level == 4) {
        return code;
    }
    
    /// level5
    append_quad(code, lat_rem_3, lon_rem_3, cell_lat, cell_lon);
    if (level == 5) {
        return code;
    }
    
    /// level6
    append_quad(code, lat_rem_3, lon_rem_3, cell_lat, cell_lon);
    return code;
}


// MARK: computeMeshCode
/// Reference:
///     - https://www.stat.go.jp/data/mesh/pdf/gaiyo1.pdf
/// - Parameters:
///     - <input> buffer 0 : LatLon
///     - <output> buffer 1 : MeshCode
kernel void JISMeshMeshCodes(
                            device const JISMeshMeshCodesParameter &input [[buffer(0)]],
                            device JISMeshMeshCodesReturn *output [[buffer(1)]],
                            uint2 id [[thread_position_in_grid]]
                            ) {
    
    if (id.x >= input.gridSize.x || id.y >= input.gridSize.y) {
        return;
    }
    
    float target_lat = input.regionMin.x + (id.y + 0.5f) * input.stepSize.x;
    float target_lon = input.regionMin.y + (id.x + 0.5f) * input.stepSize.y;
    float level = input.level;

    long code = to_mesh_code(target_lat, target_lon, level);
    
    uint index = id.y * input.gridSize.x + id.x;
    output[index].code = code;
}
