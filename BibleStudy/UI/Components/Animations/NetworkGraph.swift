import SwiftUI

// MARK: - Network Graph
// A composite view that manages multiple nodes and their connecting lines
// Creates the "lines & connections" visual motif

struct NetworkGraph: View {
    let nodes: [NetworkNode]
    let connections: [NetworkConnection]
    var animateOnAppear: Bool = true
    var staggerDelay: Double = 0.1

    @State private var visibleNodes: Set<String> = []
    @State private var visibleConnections: Set<String> = []

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw connections first (behind nodes)
                ForEach(connections) { connection in
                    if let startNode = nodes.first(where: { $0.id == connection.fromId }),
                       let endNode = nodes.first(where: { $0.id == connection.toId }) {
                        let startPoint = absolutePoint(startNode.position, in: geometry.size)
                        let endPoint = absolutePoint(endNode.position, in: geometry.size)

                        if connection.curved {
                            CurvedConnectionLine(
                                start: startPoint,
                                end: endPoint,
                                color: connection.color,
                                lineWidth: connection.lineWidth,
                                isActive: connection.isActive && visibleConnections.contains(connection.id),
                                curvature: connection.curvature
                            )
                            .opacity(visibleConnections.contains(connection.id) || respectsReducedMotion ? 1 : 0)
                        } else if connection.isFlowing {
                            FlowingConnectionLine(
                                start: startPoint,
                                end: endPoint,
                                color: connection.color,
                                lineWidth: connection.lineWidth,
                                flowSpeed: connection.flowSpeed
                            )
                            .opacity(visibleConnections.contains(connection.id) || respectsReducedMotion ? 1 : 0)
                        } else {
                            ConnectionLine(
                                start: startPoint,
                                end: endPoint,
                                color: connection.color,
                                lineWidth: connection.lineWidth,
                                isActive: connection.isActive && visibleConnections.contains(connection.id),
                                dashPattern: connection.dashed ? [5, 5] : nil
                            )
                            .opacity(visibleConnections.contains(connection.id) || respectsReducedMotion ? 1 : 0)
                        }
                    }
                }

                // Draw nodes on top
                ForEach(nodes) { node in
                    let point = absolutePoint(node.position, in: geometry.size)

                    StatefulConnectionNode(size: node.size, state: node.state)
                        .position(point)
                        .opacity(visibleNodes.contains(node.id) || respectsReducedMotion ? 1 : 0)
                        .scaleEffect(visibleNodes.contains(node.id) || respectsReducedMotion ? 1 : 0.5)
                }
            }
        }
        .onAppear {
            if animateOnAppear && !respectsReducedMotion {
                animateAppearance()
            } else {
                // Show everything immediately
                visibleNodes = Set(nodes.map { $0.id })
                visibleConnections = Set(connections.map { $0.id })
            }
        }
    }

    private func absolutePoint(_ relativePoint: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: relativePoint.x * size.width,
            y: relativePoint.y * size.height
        )
    }

    private func animateAppearance() {
        // Animate nodes appearing with stagger
        for (index, node) in nodes.enumerated() {
            let delay = Double(index) * staggerDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(Theme.Animation.settle) {
                    _ = visibleNodes.insert(node.id)
                }
            }
        }

        // Animate connections after nodes
        let connectionStartDelay = Double(nodes.count) * staggerDelay
        for (index, connection) in connections.enumerated() {
            let delay = connectionStartDelay + Double(index) * staggerDelay * 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(Theme.Animation.settle) {
                    _ = visibleConnections.insert(connection.id)
                }
            }
        }
    }
}

// MARK: - Network Node Model
struct NetworkNode: Identifiable {
    let id: String
    let position: CGPoint // Relative position (0-1 range)
    var size: CGFloat = 12
    var state: NodeState = .idle

    init(id: String, x: CGFloat, y: CGFloat, size: CGFloat = 12, state: NodeState = .idle) {
        self.id = id
        self.position = CGPoint(x: x, y: y)
        self.size = size
        self.state = state
    }
}

// MARK: - Network Connection Model
struct NetworkConnection: Identifiable {
    let id: String
    let fromId: String
    let toId: String
    var color: Color = Color("AccentBronze")
    var lineWidth: CGFloat = 2
    var isActive: Bool = false
    var isFlowing: Bool = false
    var flowSpeed: Double = 2.0
    var curved: Bool = false
    var curvature: CGFloat = 0.2
    var dashed: Bool = false

    init(
        from: String,
        to: String,
        color: Color = Color("AccentBronze"),
        lineWidth: CGFloat = 2,
        isActive: Bool = false,
        isFlowing: Bool = false,
        flowSpeed: Double = 2.0,
        curved: Bool = false,
        curvature: CGFloat = 0.2,
        dashed: Bool = false
    ) {
        self.id = "\(from)-\(to)"
        self.fromId = from
        self.toId = to
        self.color = color
        self.lineWidth = lineWidth
        self.isActive = isActive
        self.isFlowing = isFlowing
        self.flowSpeed = flowSpeed
        self.curved = curved
        self.curvature = curvature
        self.dashed = dashed
    }
}

// MARK: - Preset Network Patterns

extension NetworkGraph {
    // Simple linear network (for timelines, sequences)
    static func linear(nodeCount: Int, activeIndex: Int? = nil) -> NetworkGraph {
        let spacing = 1.0 / CGFloat(nodeCount + 1)
        let nodes = (0..<nodeCount).map { i in
            NetworkNode(
                id: "node-\(i)",
                x: spacing * CGFloat(i + 1),
                y: 0.5,
                state: i == activeIndex ? .active : .idle
            )
        }

        let connections = (0..<nodeCount - 1).map { i in
            NetworkConnection(
                from: "node-\(i)",
                to: "node-\(i + 1)",
                isActive: activeIndex != nil && i < activeIndex!
            )
        }

        return NetworkGraph(nodes: nodes, connections: connections)
    }

    // Star pattern (central node with radiating connections)
    static func star(rayCount: Int, centerActive: Bool = true) -> NetworkGraph {
        var nodes = [NetworkNode(id: "center", x: 0.5, y: 0.5, size: 16, state: centerActive ? .active : .idle)]

        let angleStep = (2 * .pi) / CGFloat(rayCount)
        let radius: CGFloat = 0.35

        for i in 0..<rayCount {
            let angle = angleStep * CGFloat(i) - .pi / 2
            let x = 0.5 + cos(angle) * radius
            let y = 0.5 + sin(angle) * radius
            nodes.append(NetworkNode(id: "ray-\(i)", x: x, y: y, size: 10))
        }

        let connections = (0..<rayCount).map { i in
            NetworkConnection(from: "center", to: "ray-\(i)", isActive: centerActive)
        }

        return NetworkGraph(nodes: nodes, connections: connections)
    }

    // Mesh pattern (interconnected nodes)
    static func mesh(rows: Int, cols: Int) -> NetworkGraph {
        var nodes: [NetworkNode] = []
        var connections: [NetworkConnection] = []

        let xSpacing = 1.0 / CGFloat(cols + 1)
        let ySpacing = 1.0 / CGFloat(rows + 1)

        // Create nodes
        for row in 0..<rows {
            for col in 0..<cols {
                let id = "node-\(row)-\(col)"
                nodes.append(NetworkNode(
                    id: id,
                    x: xSpacing * CGFloat(col + 1),
                    y: ySpacing * CGFloat(row + 1),
                    size: 10
                ))
            }
        }

        // Create horizontal connections
        for row in 0..<rows {
            for col in 0..<cols - 1 {
                connections.append(NetworkConnection(
                    from: "node-\(row)-\(col)",
                    to: "node-\(row)-\(col + 1)"
                ))
            }
        }

        // Create vertical connections
        for row in 0..<rows - 1 {
            for col in 0..<cols {
                connections.append(NetworkConnection(
                    from: "node-\(row)-\(col)",
                    to: "node-\(row + 1)-\(col)"
                ))
            }
        }

        return NetworkGraph(nodes: nodes, connections: connections)
    }
}

// MARK: - Preview
#Preview("Network Graph Patterns") {
    ScrollView {
        VStack(spacing: Theme.Spacing.xxl) {
            Text("Linear").font(Typography.Command.headline)
            NetworkGraph.linear(nodeCount: 5, activeIndex: 2)
                .frame(height: 60)
                .padding(.horizontal)

            Text("Star").font(Typography.Command.headline)
            NetworkGraph.star(rayCount: 6, centerActive: true)
                .frame(height: 200)

            Text("Mesh").font(Typography.Command.headline)
            NetworkGraph.mesh(rows: 3, cols: 4)
                .frame(height: 200)

            Text("Custom").font(Typography.Command.headline)
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "a", x: 0.2, y: 0.3, state: .pulsing),
                    NetworkNode(id: "b", x: 0.5, y: 0.2, state: .active),
                    NetworkNode(id: "c", x: 0.8, y: 0.4, state: .idle),
                    NetworkNode(id: "d", x: 0.5, y: 0.7, state: .success),
                ],
                connections: [
                    NetworkConnection(from: "a", to: "b", isFlowing: true),
                    NetworkConnection(from: "b", to: "c", isActive: true, curved: true),
                    NetworkConnection(from: "b", to: "d", isActive: true),
                    NetworkConnection(from: "a", to: "d", dashed: true),
                ]
            )
            .frame(height: 200)
        }
        .padding()
    }
    .background(Color.appBackground)
}
