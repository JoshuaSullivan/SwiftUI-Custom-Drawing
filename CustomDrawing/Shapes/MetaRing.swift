import SwiftUI

/// Defines how child views are oriented when placed around the ring.
public enum MetaRingOrientation {
    /// All child views maintain their original upright orientation.
    case fixed
    /// Each child view is rotated to point outward from the center of the ring.
    case radial
}

/// A layout that arranges child views evenly around a circle.
///
/// The origin point is the top of the circle (-90 degrees), so the first view
/// is always placed at the 12 o'clock position.
public struct MetaRingLayout: Layout {
    /// The ratio of the ring's thickness to its diameter, controlling child view sizing.
    public let thicknessRatio: CGFloat
    /// How child views are oriented around the ring.
    public let orientation: MetaRingOrientation

    public init(thicknessRatio: CGFloat = 0.3, orientation: MetaRingOrientation = .radial) {
        self.thicknessRatio = thicknessRatio
        self.orientation = orientation
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let side = min(proposal.width ?? .infinity, proposal.height ?? .infinity)
        return CGSize(width: side, height: side)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let count = subviews.count
        guard count > 0 else { return }

        let radius = min(bounds.width, bounds.height) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let placementRadius = radius * (1 - thicknessRatio)
        let childSize = radius * thicknessRatio * 2
        let childProposal = ProposedViewSize(width: childSize, height: childSize)
        let angleStep = (2 * .pi) / Double(count)

        for (index, subview) in subviews.enumerated() {
            let angle = angleStep * Double(index) - .pi / 2
            let point = CGPoint(
                x: center.x + placementRadius * cos(angle),
                y: center.y + placementRadius * sin(angle)
            )
            switch orientation {
            case .fixed:
                subview.place(at: point, anchor: .center, proposal: childProposal)
            case .radial:
                subview.place(
                    at: point,
                    anchor: .center,
                    proposal: childProposal
                )
            }
        }
    }

    // Apply rotation via a layout value key for radial orientation.
    public static var layoutProperties: LayoutProperties {
        var props = LayoutProperties()
        props.stackOrientation = nil
        return props
    }
}

/// A view that repeats a single view or arranges an array of views in a ring.
///
/// The first view is always placed at the top (12 o'clock position).
public struct MetaRing: View {
    private let thicknessRatio: CGFloat
    private let orientation: MetaRingOrientation
    private let content: [AnyView]

    /// Creates a MetaRing that repeats a pre-built view.
    ///
    /// Use this initializer when you already have a view instance and want to
    /// repeat it around the ring, e.g. `MetaRing(myCircle, repeatCount: 6)`.
    /// - Parameters:
    ///   - view: The view to repeat.
    ///   - thicknessRatio: The ratio of child view size to the ring diameter. Defaults to 0.3.
    ///   - repeatCount: The number of copies to place around the ring. Defaults to 8.
    ///   - orientation: How child views are oriented. Defaults to `.radial`.
    public init(
        _ view: any View,
        thicknessRatio: CGFloat = 0.3,
        repeatCount: Int = 8,
        orientation: MetaRingOrientation = .radial
    ) {
        self.thicknessRatio = thicknessRatio
        self.orientation = orientation
        self.content = Array(repeating: AnyView(view), count: max(1, repeatCount))
    }

    /// Creates a MetaRing by composing a view inline using SwiftUI's `@ViewBuilder` syntax.
    ///
    /// Use this initializer when you want to build the repeated view inline with
    /// SwiftUI's declarative DSL, including modifiers, conditionals, and composition,
    /// e.g. `MetaRing(repeatCount: 8) { Circle().fill(.blue) }`.
    /// - Parameters:
    ///   - thicknessRatio: The ratio of child view size to the ring diameter. Defaults to 0.3.
    ///   - repeatCount: The number of copies to place around the ring. Defaults to 8.
    ///   - orientation: How child views are oriented. Defaults to `.radial`.
    ///   - content: A closure returning the view to repeat.
    public init<Content: View>(
        thicknessRatio: CGFloat = 0.3,
        repeatCount: Int = 8,
        orientation: MetaRingOrientation = .radial,
        @ViewBuilder content: () -> Content
    ) {
        self.thicknessRatio = thicknessRatio
        self.orientation = orientation
        let view = content()
        self.content = Array(repeating: AnyView(view), count: max(1, repeatCount))
    }

    /// Creates a MetaRing from an array of heterogeneous views.
    ///
    /// Use this initializer when you want to arrange different view types around
    /// the ring, e.g. `MetaRing(views: [Circle(), Rectangle(), Image(...)] as [any View])`.
    /// - Parameters:
    ///   - views: The views to arrange around the ring.
    ///   - thicknessRatio: The ratio of child view size to the ring diameter. Defaults to 0.3.
    ///   - orientation: How child views are oriented. Defaults to `.radial`.
    public init(
        views: [any View],
        thicknessRatio: CGFloat = 0.3,
        orientation: MetaRingOrientation = .radial
    ) {
        self.thicknessRatio = thicknessRatio
        self.orientation = orientation
        self.content = views.map { AnyView($0) }
    }

    public var body: some View {
        MetaRingLayout(thicknessRatio: thicknessRatio, orientation: orientation) {
            let count = content.count
            let angleStep = count > 0 ? 360.0 / Double(count) : 0
            ForEach(Array(content.enumerated()), id: \.offset) { index, view in
                if orientation == .radial {
                    view.rotationEffect(.degrees(angleStep * Double(index)))
                } else {
                    view
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MetaRing(thicknessRatio: 0.2, repeatCount: 12, orientation: .radial) {
            Rectangle()
                .fill(.blue)
        }
        .frame(width: 200, height: 200)

        MetaRing(thicknessRatio: 0.15, repeatCount: 6, orientation: .fixed) {
            StarRing(points: 5, innerRadiusRatio: 0.4)
                .fill(.orange)
        }
        .frame(width: 200, height: 200)

        MetaRing(
            views: [
                Circle().fill(.red),
                Rectangle().fill(.orange),
                Circle().fill(.yellow),
                Rectangle().fill(.green),
                Circle().fill(.blue),
            ] as [any View],
            thicknessRatio: 0.2
        )
        .frame(width: 200, height: 200)
    }
    .padding()
}
