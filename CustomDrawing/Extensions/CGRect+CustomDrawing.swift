import CoreFoundation

public extension CGRect {
    /// Returns a square CGRect centered within this CGRect.
    func centeredSquare() -> CGRect {
        let dim = min(self.width, self.height)
        let dx = (self.width - dim) / 2
        let dy = (self.height - dim) / 2
        return CGRect(x: self.minX + dx, y: self.minY + dy, width: dim, height: dim)
    }
    
    /// The center point of the CGRect.
    var center: CGPoint {
        CGPoint(x: self.midX, y: self.midY)
    }
}
