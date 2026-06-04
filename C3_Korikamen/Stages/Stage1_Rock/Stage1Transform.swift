//
//  Stage1Transform.swift
//  C3_Korikamen
//
//  돌무더기/관의 위치·배율(조정모드에서 맞춘 값)을 UserDefaults에 저장/복원.
//  - 조정모드 슬라이더로 맞춘 값이 앱 재시작·클린빌드 후에도 유지된다.
//  - 저장된 값이 없으면 Stage1Layout의 기본 상수를 쓴다(현재 0.737 / 0.755).
//  - 저장은 DEBUG 조정모드에서, 적용(load)은 릴리스 포함 항상 일어난다.
//

import CoreGraphics
import Foundation

struct Stage1Transform: Codable {
    var pilePosition: CGPoint
    var pileScale: CGFloat
    var coffinPosition: CGPoint
    var coffinScale: CGFloat

    /// 저장된 값이 없을 때의 기본(= Stage1Layout 상수).
    static var fallback: Stage1Transform {
        Stage1Transform(pilePosition: Stage1Layout.pilePosition,
                        pileScale: Stage1Layout.pileScale,
                        coffinPosition: Stage1Layout.coffinPosition,
                        coffinScale: Stage1Layout.coffinScale)
    }

    private static let key = "stage1.transform.v1"

    /// 저장된 변환을 읽는다(없거나 깨졌으면 기본값).
    static func load() -> Stage1Transform {
        guard let data = UserDefaults.standard.data(forKey: key),
              let t = try? JSONDecoder().decode(Stage1Transform.self, from: data) else {
            return fallback
        }
        return t
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    /// 저장값 제거 → 다음 load()는 기본값 반환.
    static func reset() { UserDefaults.standard.removeObject(forKey: key) }
}
