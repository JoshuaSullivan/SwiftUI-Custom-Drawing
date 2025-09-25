import SwiftUI

/// Represents a arc of angles in the ring, defined by a start and end angle.
public struct Arc: Sendable {
    
    /// The start angle of the arc.
    public let start: Angle
    
    /// The end angle of the arc.
    public let end: Angle
    
    /// Indicates whether the arc is drawn in a clockwise direction.
    public let clockwise: Bool
    
    /// Initializes a `Arc` with the specified start and end angles.
    /// - Parameters:
    ///     - start: The start angle of the arc.
    ///     - end: The end angle of the arc.
    ///
    public init(start: Angle, end: Angle, clockwise: Bool = false) {
        self.start = start
        self.end = end
        self.clockwise = clockwise
    }
    
    /// Returns a new `Arc` offset by the specified angle.
    /// - Parameter angle: The angle by which to offset the arc.
    /// - Returns: A new `Arc` with the start and end angles offset by the specified angle.
    ///
    public func offsetBy(_ angle: Angle) -> Arc {
        Arc(start: start + angle, end: end + angle, clockwise: clockwise)
    }
}

public extension Arc {
    /// An empty arc.
    static let empty = Arc(start: .degrees(0), end: .degrees(0))
    /// A full circle arc.
    static let fullCircle = Arc(start: .degrees(0), end: .degrees(360))
}
