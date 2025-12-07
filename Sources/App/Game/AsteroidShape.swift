import Foundation
import Engine

class AsteroidShape {
    private let _gridCols: Int
    private let _gridRows: Int
    private var _grid: [Int]
    // private let _cellSize: Double
    private let _fontSize: Double

    var gridCols: Int { _gridCols }
    var gridRows: Int { _gridRows }

    init(gridCols: Int, gridRows: Int) {
        _gridCols = gridCols
        _gridRows = gridRows
        _grid = Array(repeating: 0, count: gridCols * gridRows)
        _fontSize = 24.0
    }

    var cellSize: Vector2 {
        return Vector2(_fontSize * 0.6, _fontSize)
    }

    var shapeBounds: Rect {
        var bounds = Rect(position: .zero, size: .zero)
        bounds.min = cellPosition(row: 0, col: 0) - cellSize * 0.5
        bounds.max = cellPosition(row: _gridRows - 1, col: _gridCols - 1) + cellSize * 0.5
        return bounds
    }

    var containingRadius: Double {
        shapeBounds.size.magnitude() * 0.5
    }

    func cellPosition(row: Int, col: Int) -> Vector2 {
        return Vector2(
            (Double(col) - Double(_gridCols - 1) / 2.0) * cellSize.x, 
            (Double(row) - Double(_gridRows - 1) / 2.0) * cellSize.y
        )
    }

    func index(row: Int, col: Int) -> Int {
        return row * _gridCols + col
    }

    func cellIsEmpty(row: Int, col: Int) -> Bool {
        if row < 0 || row >= _gridRows || col < 0 || col >= _gridCols {
            return true
        }
        return _grid[index(row: row, col: col)] == 0
    }

    func generateRandomShape() {
        let shapeRadius = Math.lerp(shapeBounds.size.x, shapeBounds.size.y, by: 0.5) * 0.5
        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                let cellPosition = cellPosition(row: row, col: col)
                let relativeDistanceFromCenter = cellPosition.magnitude() / shapeRadius

                let randomChance = 1.0 - pow(Math.lerp(0.0, 1.0, by: relativeDistanceFromCenter), 4.0)
                if Double.random(in: 0.0...1.0) < randomChance {
                    _grid[index(row: row, col: col)] = 1
                }
                else {
                    _grid[index(row: row, col: col)] = 0
                }
            }
        }

        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                var allNeighborsEmpty = true
                allNeighborsEmpty = allNeighborsEmpty && cellIsEmpty(row: row - 1, col: col)
                allNeighborsEmpty = allNeighborsEmpty && cellIsEmpty(row: row + 1, col: col)
                allNeighborsEmpty = allNeighborsEmpty && cellIsEmpty(row: row, col: col - 1)
                allNeighborsEmpty = allNeighborsEmpty && cellIsEmpty(row: row, col: col + 1)
                if allNeighborsEmpty {
                    _grid[index(row: row, col: col)] = 0
                }
            }
        }
    }

    func renderData() -> RenderData {
        var text = ""
        for row in 0..<_gridRows {
            for col in 0..<_gridCols {
                if _grid[index(row: row, col: col)] == 1 {
                    text += "#"
                }
                else {
                    text += " "
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
                if cellIsEmpty(row: row, col: col) {
                    continue
                }
                let cellPosition = asteroidTransform.transformPosition(cellPosition(row: row, col: col))
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
                if cellIsEmpty(row: row, col: col) {
                    continue
                }
                let cellPosition = asteroidTransform.transformPosition(cellPosition(row: row, col: col))
                let cellRadius = cellSize.x * asteroidTransform.scale.x * 0.5
                let delta = center - cellPosition
                if delta.magnitude() < radius + cellRadius {
                    return (position: cellPosition + delta.direction() * cellRadius, normal: delta.direction())
                }
            }
        }
        return nil
    }
}
