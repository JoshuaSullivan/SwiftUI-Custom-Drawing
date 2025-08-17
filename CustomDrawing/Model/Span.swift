import SwiftUI

/// Represents a span of angles in the ring, defined by a start and end angle.
public struct Span: Sendable {
    
    /// The start angle of the span.
    public let start: Angle
    
    /// The end angle of the span.
    public let end: Angle
    
    /// Initializes a `Span` with the specified start and end angles.
    /// - Parameters:
    ///     - start: The start angle of the span.
    ///     - end: The end angle of the span.
    ///
    public init(start: Angle, end: Angle) {
        self.start = start
        self.end = end
    }
}
