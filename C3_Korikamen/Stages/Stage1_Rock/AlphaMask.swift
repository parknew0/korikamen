//
//  AlphaMask.swift
//  C3_Korikamen
//
//  이미지(PNG)의 픽셀 투명도를 미리 뽑아 보관 → 터치 지점이 '실제 그림' 위인지 빠르게 판정.
//  (터치 알파 판정의 데이터 소스. 렌더링/판정 정책은 갖지 않는 순수 값 타입.)
//

import SpriteKit

/// PNG의 알파값을 미리 뽑아 보관 → 터치 지점이 '실제 그림' 위인지 빠르게 판정.
struct AlphaMask {
    let width: Int
    let height: Int
    let color: SKColor          // 불투명 픽셀들의 평균색(파편 색으로 사용 = '컬러 피커' 역할)
    private let data: [UInt8]    // 픽셀별 알파(0~255). row 0 = 이미지 위쪽.

    init?(_ image: UIImage) {
        guard let cg = image.cgImage else { return nil }
        let w = cg.width, h = cg.height
        guard w > 0, h > 0 else { return nil }
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(data: &rgba, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: space, bitmapInfo: info) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var a = [UInt8](repeating: 0, count: w * h)
        var rSum = 0.0, gSum = 0.0, bSum = 0.0, count = 0.0
        for i in 0..<(w * h) {
            let alpha = rgba[i * 4 + 3]
            a[i] = alpha
            if alpha > 40 {                          // 불투명 픽셀만 평균에 반영
                // premultiplied → 원색 복원
                let af = Double(alpha) / 255.0
                rSum += Double(rgba[i * 4 + 0]) / af
                gSum += Double(rgba[i * 4 + 1]) / af
                bSum += Double(rgba[i * 4 + 2]) / af
                count += 1
            }
        }
        self.width = w; self.height = h; self.data = a
        if count > 0 {
            self.color = SKColor(red: CGFloat(min(255, rSum / count) / 255.0),
                                 green: CGFloat(min(255, gSum / count) / 255.0),
                                 blue: CGFloat(min(255, bSum / count) / 255.0),
                                 alpha: 1)
        } else {
            self.color = SKColor(white: 0.6, alpha: 1)   // 폴백(회색)
        }
    }

    func alpha(_ x: Int, _ y: Int) -> UInt8? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        return data[y * width + x]
    }
}
