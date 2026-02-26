import Vision
import CoreImage

public enum EyeState {
    case open       // 顔検出済み、目が開いている
    case closed     // 顔検出済み、目が閉じている
    case noFace     // 顔が検出できない
}

public class EyeDetectionService {
    public var onEyeStateChanged: ((EyeState) -> Void)?
    /// カメラフレームをCGImageとして受け取るコールバック（UIへの映像投影用）
    public var onFrameImage: ((CGImage) -> Void)?

    private let cameraService = CameraService.shared
    private let ciContext = CIContext()
    private var isRunning = false
    private var frameSkipCounter = 0

    // Eye Aspect Ratio threshold for determining if eyes are closed
    // Lower value = more closed
    public var earThreshold: Float = 0.2

    public init() {}

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        cameraService.onFrameCaptured = { [weak self] pixelBuffer in
            self?.processFrame(pixelBuffer)
        }
        cameraService.startCapture()
    }

    public func stop() {
        isRunning = false
        onEyeStateChanged = nil
        onFrameImage = nil
        cameraService.stopCapture()
    }

    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard isRunning else { return }

        // カメラ映像をCGImageに変換（3フレームに1回、パフォーマンス節約）
        // CIGaussianBlur + CIPixellate で人間と認識できないレベルにぼかす
        frameSkipCounter += 1
        if frameSkipCounter % 3 == 0, let callback = onFrameImage {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let blurred = ciImage
                .applyingFilter("CIPixellate", parameters: [kCIInputScaleKey: 12])
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 25])
            // ブラーで広がった分をクロップ
            let cropped = blurred.cropped(to: ciImage.extent)
            if let cgImage = ciContext.createCGImage(cropped, from: ciImage.extent) {
                DispatchQueue.main.async {
                    callback(cgImage)
                }
            }
        }

        // Wrap in autoreleasepool to ensure all Vision framework ObjC objects
        // are released immediately, preventing corrupt pointers from lingering
        // in the RunLoop's autorelease pool (which caused EXC_BAD_ACCESS).
        autoreleasepool {
            let request = VNDetectFaceLandmarksRequest()
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform face detection: \(error)")
                notifyEyeState(.noFace)
                return
            }

            guard let observations = request.results as? [VNFaceObservation],
                  let face = observations.first,
                  let landmarks = face.landmarks else {
                notifyEyeState(.noFace)
                return
            }

            let eyesClosed = areEyesClosed(landmarks: landmarks)
            notifyEyeState(eyesClosed ? .closed : .open)
        }
    }

    private func areEyesClosed(landmarks: VNFaceLandmarks2D) -> Bool {
        // Check both eyes
        let leftEyeClosed = isEyeClosed(landmarks.leftEye)
        let rightEyeClosed = isEyeClosed(landmarks.rightEye)

        // Both eyes need to be closed
        return leftEyeClosed && rightEyeClosed
    }

    private func isEyeClosed(_ eye: VNFaceLandmarkRegion2D?) -> Bool {
        guard let eye = eye else { return true }

        let points = eye.normalizedPoints

        // Need at least 6 points for EAR calculation
        // Typical eye landmark has 6 points:
        // p0: left corner, p1: upper left, p2: upper right, p3: right corner, p4: lower right, p5: lower left
        guard points.count >= 6 else { return true }

        // Calculate Eye Aspect Ratio (EAR)
        // EAR = (|p1-p5| + |p2-p4|) / (2 * |p0-p3|)
        let p0 = points[0] // left corner
        let p1 = points[1] // upper left
        let p2 = points[2] // upper right
        let p3 = points[3] // right corner
        let p4 = points[4] // lower right
        let p5 = points[5] // lower left

        let verticalDist1 = distance(p1, p5)
        let verticalDist2 = distance(p2, p4)
        let horizontalDist = distance(p0, p3)

        guard horizontalDist > 0 else { return true }

        let ear = (verticalDist1 + verticalDist2) / (2.0 * horizontalDist)

        return ear < earThreshold
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> Float {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return Float(sqrt(dx * dx + dy * dy))
    }

    private func notifyEyeState(_ state: EyeState) {
        DispatchQueue.main.async { [weak self] in
            self?.onEyeStateChanged?(state)
        }
    }
}
