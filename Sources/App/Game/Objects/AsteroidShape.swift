import Foundation
import Engine

class AsteroidShape {
    enum CellType {
        case empty
        case rock
        case resource
    }

    private let _gridCols: Int
    private let _gridRows: Int
    private var _grid: [CellType]
    private let _fontSize: Double

    var gridCols: Int { _gridCols }
    var gridRows: Int { _gridRows }

    init(rows: Int, cols: Int) {
        _gridRows = rows
        _gridCols = cols
        _grid = Array(repeating: .empty, count: cols * rows)
        _fontSize = 24.0
    }

    var cellSize: Vector2 {
        return Vector2(_fontSize * 0.6, _fontSize)
    }

    var shapeBounds: Rect {
        var bounds = Rect(position: .zero, size: .zero)
        bounds.min = positionOffset(row: 0, col: 0) - cellSize * 0.5
        bounds.max = positionOffset(row: Double(_gridRows - 1), col: Double(_gridCols - 1)) + cellSize * 0.5
        return bounds
    }

    var containingRadius: Double {
        shapeBounds.size.magnitude() * 0.5
    }

    func positionOffset(row: Double, col: Double) -> Vector2 {
        return Vector2(
            (col - Double(_gridCols - 1) / 2.0) * cellSize.x, 
            (row - Double(_gridRows - 1) / 2.0) * cellSize.y
        )
    }

    func index(row: Int, col: Int) -> Int {
        return row * _gridCols + col
    }

    func contains(row: Int, col: Int) -> Bool {
        return row >= 0 && row < _gridRows && col >= 0 && col < _gridCols
    }

    func cellTypeAt(row: Int, col: Int) -> CellType {
        if !contains(row: row, col: col) {
            return .empty
        }
        return _grid[index(row: row, col: col)]
    }

    func setCellType(row: Int, col: Int, type: CellType) {
        assert(contains(row: row, col: col))
        _grid[index(row: row, col: col)] = type
    }

    static func randomShape(rows: Int, cols: Int, resourceChance: Double) -> AsteroidShape {
        let shape = AsteroidShape(rows: rows, cols: cols)
        let shapeRadius = Math.lerp(shape.shapeBounds.size.x, shape.shapeBounds.size.y, by: 0.5) * 0.5
        for row in 0..<shape.gridRows {
            for col in 0..<shape.gridCols {
                let cellPosition = shape.positionOffset(row: Double(row), col: Double(col))
                let relativeDistanceFromCenter = cellPosition.magnitude() / shapeRadius

                let filledChance = 1.0 - pow(Math.lerp(0.0, 1.0, by: relativeDistanceFromCenter), 3.0)
                if Double.random(in: 0.0...1.0) < filledChance {
                    let resourceChange = pow(Math.lerp(1.0, 0.0, by: relativeDistanceFromCenter), 3.0) * resourceChance
                    if Double.random(in: 0.0...1.0) < resourceChange {
                        shape.setCellType(row: row, col: col, type: .resource)
                    }
                    else {
                        shape.setCellType(row: row, col: col, type: .rock)
                    }
                }
                else {
                    shape.setCellType(row: row, col: col, type: .empty)
                }
            }
        }
        _ = shape.purgeDetachedCells()

        for row in 0..<shape.gridRows {
            for col in 0..<shape.gridCols {
                if shape.isLooseResource(row: row, col: col) {
                    shape.setCellType(row: row, col: col, type: .rock)
                }
            }
        }
        return shape.compactedShape().shape
    }

    func purgeDetachedCells() -> [(cellType: CellType, offset: Vector2)] {
        func dfs(row: Int, col: Int, groupId: Int, groupIdGrid: inout [Int]) -> Int {
            if cellTypeAt(row: row, col: col) == .empty {
                return 0
            }
            if groupIdGrid[index(row: row, col: col)] != -1 {
                return 0
            }
            groupIdGrid[index(row: row, col: col)] = groupId
            var count = 1
            count += dfs(row: row - 1, col: col, groupId: groupId, groupIdGrid: &groupIdGrid)
            count += dfs(row: row + 1, col: col, groupId: groupId, groupIdGrid: &groupIdGrid)
            count += dfs(row: row, col: col - 1, groupId: groupId, groupIdGrid: &groupIdGrid)
            count += dfs(row: row, col: col + 1, groupId: groupId, groupIdGrid: &groupIdGrid)
            return count
        }

        var groupIdGrid = Array(repeating: -1, count: _gridRows * _gridCols)
        var nextGroupId = 0
        var mostCellsGroupId = -1
        var mostCellsGroupCount = 0

        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                if cellTypeAt(row: row, col: col) != .empty && groupIdGrid[index(row: row, col: col)] == -1 {
                    let groupId = nextGroupId
                    nextGroupId += 1
                    let count = dfs(row: row, col: col, groupId: groupId, groupIdGrid: &groupIdGrid)
                    if count > mostCellsGroupCount {
                        mostCellsGroupCount = count
                        mostCellsGroupId = groupId
                    }
                }
            }
        }

        var detachedCells = [(cellType: CellType, offset: Vector2)]()
        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                if groupIdGrid[index(row: row, col: col)] != mostCellsGroupId {
                    detachedCells.append((cellType: cellTypeAt(row: row, col: col), offset: positionOffset(row: Double(row), col: Double(col))))
                    setCellType(row: row, col: col, type: .empty)
                }
            }
        }
        return detachedCells
    }

    func rowEmpty(row: Int) -> Bool {
        for col in 0..<_gridCols {
            if cellTypeAt(row: row, col: col) != .empty {
                return false
            }
        }
        return true
    }

    func colEmpty(col: Int) -> Bool {
        for row in 0..<_gridRows {
            if cellTypeAt(row: row, col: col) != .empty {
                return false
            }
        }
        return true
    }

    func compactedShape() -> (shape: AsteroidShape, centerOffset: Vector2) {
        let startRow: Int? = (0..<_gridRows).first(where: { !rowEmpty(row: $0) })
        let endRow: Int? = (0..<_gridRows).last(where: { !rowEmpty(row: $0) })
        let startCol: Int? = (0..<_gridCols).first(where: { !colEmpty(col: $0) })
        let endCol: Int? = (0..<_gridCols).last(where: { !colEmpty(col: $0) })
        guard let startRow, let endRow, let startCol, let endCol else {
            return (shape: AsteroidShape(rows: 0, cols: 0), centerOffset: .zero)
        }
        let newShape = AsteroidShape(rows: endRow - startRow + 1, cols: endCol - startCol + 1)
        for row in 0..<newShape.gridRows {
            for col in 0..<newShape.gridCols {
                newShape.setCellType(row: row, col: col, type: cellTypeAt(row: startRow + row, col: startCol + col))
            }
        }
        let centerOffset = positionOffset(
            row: Double(startRow) + Double(newShape.gridRows - 1) / 2.0, 
            col: Double(startCol) + Double(newShape.gridCols - 1) / 2.0
        )
        return (shape: newShape, centerOffset: centerOffset)
    }

    func splitAlong(axisOrigin: Vector2, axisDirection: Vector2) -> [(shape: AsteroidShape, centerOffset: Vector2)] {
        let newShapes = [
            AsteroidShape(rows: _gridRows, cols: _gridCols), 
            AsteroidShape(rows: _gridRows, cols: _gridCols)
        ]
        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                let cross = Vector2.cross(positionOffset(row: Double(row), col: Double(col)) - axisOrigin, axisDirection)
                newShapes[cross >= 0.0 ? 0 : 1].setCellType(row: row, col: col, type: cellTypeAt(row: row, col: col))
            }
        }
        return newShapes.map { $0.compactedShape() }
    }

    func isLooseResource(row: Int, col: Int) -> Bool {
        if cellTypeAt(row: row, col: col) != .resource {
            return false
        }
        let a = cellTypeAt(row: row, col: col + 1) == .empty
        let b = cellTypeAt(row: row + 1, col: col) == .empty
        let c = cellTypeAt(row: row, col: col - 1) == .empty
        let d = cellTypeAt(row: row - 1, col: col) == .empty
        return (a && b) || (b && c) || (c && d) || (d && a)
    }

    func takeLooseResources() -> [Vector2] {
        func dfs(row: Int, col: Int, resources: inout [Vector2]) {
            if !isLooseResource(row: row, col: col) {
                return
            }
            resources.append(positionOffset(row: Double(row), col: Double(col)))
            setCellType(row: row, col: col, type: .empty)
            dfs(row: row + 1, col: col, resources: &resources)
            dfs(row: row - 1, col: col, resources: &resources)
            dfs(row: row, col: col + 1, resources: &resources)
            dfs(row: row, col: col - 1, resources: &resources)
        }

        var resources = [Vector2]()
        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                if isLooseResource(row: row, col: col) {
                    dfs(row: row, col: col, resources: &resources)
                }
            }
        }
        return resources
    }

    func takeCellsOfType(type: CellType) -> [Vector2] {
        var cells = [Vector2]()
        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                if cellTypeAt(row: row, col: col) == type {
                    cells.append(positionOffset(row: Double(row), col: Double(col)))
                    setCellType(row: row, col: col, type: .empty)
                }
            }
        }
        return cells
    }

    func renderData() -> RenderData {
        var text = ""
        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                switch _grid[index(row: row, col: col)] {
                case .empty:
                    text += " "
                case .rock:
                    text += "#"
                case .resource:
                    text += "o"
                }
            }
            if row < _gridRows - 1 {
                text += "\n"
            }
        }
        return .text(text: text, fontSize: _fontSize)
    }

    func lineSegmentIntersection(_ lineSegment: (Vector2, Vector2), asteroidTransform: Transform2D) -> Double? {
        let shapeCenter = asteroidTransform.transformPosition(shapeBounds.center)
        if Vector2.lineSegmentCircleIntersection(lineSegment, center: shapeCenter, radius: containingRadius * asteroidTransform.scale.x) == nil {
            return nil
        }
        var minEnter: Double? = nil
        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                if cellTypeAt(row: row, col: col) == .empty {
                    continue
                }
                let cellPosition = asteroidTransform.transformPosition(positionOffset(row: Double(row), col: Double(col)))
                let cellRadius = cellSize.x * asteroidTransform.scale.x * 0.5
                let cellIntersection = Vector2.lineSegmentCircleIntersection(lineSegment, center: cellPosition, radius: cellRadius)
                if let (enter, _) = cellIntersection {
                    if minEnter == nil || enter < minEnter! {
                        minEnter = enter
                    }
                }
            }
        }
        return minEnter
    }

    func circleIntersection(center: Vector2, radius: Double, asteroidTransform: Transform2D) -> (position: Vector2, normal: Vector2)? {
        let shapeCenter = asteroidTransform.transformPosition(shapeBounds.center)
        if (center - shapeCenter).magnitude() > radius + containingRadius * asteroidTransform.scale.x {
            return nil
        }
        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                if cellTypeAt(row: row, col: col) == .empty {
                    continue
                }
                let cellPosition = asteroidTransform.transformPosition(positionOffset(row: Double(row), col: Double(col)))
                let cellRadius = cellSize.maxValue() * asteroidTransform.scale.x * 0.5
                let delta = center - cellPosition
                if delta.magnitude() < radius + cellRadius {
                    let direction = delta.direction() ?? .zero
                    return (position: cellPosition + direction * cellRadius, normal: direction)
                }
            }
        }
        return nil
    }
}
