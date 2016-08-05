//
//  GameModel.swift
//  2048
//
//  Created by apple on 16/7/13.
//  Copyright © 2016年 Keyon. All rights reserved.
//

import UIKit

protocol GameModelProtocol:class {
    func scoreChanged(score:Int)
    func insertTile(location:(Int,Int),value:Int)
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int)
}


class GameModel: NSObject {
    unowned let delegate:GameModelProtocol
    var dimension : Int
    var threshold : Int
    var score:Int = 0 {
        didSet {
            delegate.scoreChanged(score)
        }
    }
    
    var timer:NSTimer
    
    var gameboard:SquareGameboard<TileObject>
    
    var queue:[MoveCommand]
    
    let maxCommands = 100
    let queueDelay = 0.3
    
    init(dimension d:Int,threshold s:Int,delegate:GameModelProtocol) {
        dimension = d
        threshold = s
        self.delegate = delegate
        timer = NSTimer()
        queue = [MoveCommand]()
        gameboard = SquareGameboard(dimension: d, initiaValue: .Empty)
        super.init()
    }
    
    /// Reset the game state.
    func reset() {
        score = 0
        gameboard.setAll(.Empty)
        queue.removeAll(keepCapacity: true)
        timer.invalidate()
    }
    
    func tileBelowHasSameValue(location: (Int, Int), _ value: Int) -> Bool {
        let (x, y) = location
        guard y != dimension - 1 else {
            return false
        }
        if case let .Tile(v) = gameboard[x, y+1] {
            return v == value
        }
        return false
    }
    
    func tileToRightHasSameValue(location: (Int, Int), _ value: Int) -> Bool {
        let (x, y) = location
        guard x != dimension - 1 else {
            return false
        }
        if case let .Tile(v) = gameboard[x+1, y] {
            return v == value
        }
        return false
    }
    
    func userHasLost() -> Bool {
        guard gameboardEmptySpots().isEmpty else {
            // Player can't lose before filling up the board
            return false
        }
        
        // Run through all the tiles and check for possible moves
        for i in 0..<dimension {
            for j in 0..<dimension {
                switch gameboard[i, j] {
                case .Empty:
                    assert(false, "Gameboard reported itself as full, but we still found an empty tile. This is a logic error.")
                case let .Tile(v):
                    if tileBelowHasSameValue((i, j), v) || tileToRightHasSameValue((i, j), v) {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    func userHasWon() -> (Bool, (Int, Int)?) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                // Look for a tile with the winning score or greater
                if case let .Tile(v) = gameboard[i, j] where v >= threshold {
                    return (true, (i, j))
                }
            }
        }
        return (false, nil)
    }
    
    func queueMove(direction:MoveDirection,completion:(Bool)->()) {
        guard queue.count<=maxCommands else {
            return
        }
        queue.append(MoveCommand(direction: direction, completion: completion))
        timerFired()
    }
    
    
    func timerFired() {
        if queue.count == 0 {
            return
        }
        var changed = false
        while queue.count > 0 {
            let command = queue[0]
            queue.removeAtIndex(0)
            changed = performMove(command.direction)
            command.completion(changed)
            if changed {
                break
            }
        }
        
    }
    
    func insertTile(postion:(Int,Int),value:Int) {
        let (x,y) = postion
        if case .Empty = gameboard[x,y] {
            gameboard[x,y] = TileObject.Tile(value)
            delegate.insertTile(postion, value: value)
        }
    }
    
    func insertTileAtRandomLocation(value:Int) {
        let openSpots = gameboardEmptySpots()
        if openSpots.isEmpty {
            return
        }
        let idx = Int(arc4random_uniform(UInt32(openSpots.count - 1)))
        let (x,y) = openSpots[idx]
        insertTile((x,y), value: value)
    }
    
    func gameboardEmptySpots() -> [(Int,Int)] {
        var buffer:[(Int,Int)] = []
        for i in 0..<dimension {
            for j in 0..<dimension {
                if case .Empty = gameboard[i,j] {
                    buffer += [(i,j)]
                }
            }
        }
        return buffer
    }
    
    func performMove(direction:MoveDirection) -> Bool {
        
        let coordiateGenerator : (Int) ->[(Int,Int)] = { (iteration: Int) -> [(Int,Int)] in
            var buffer = Array<(Int,Int)>(count:self.dimension,repeatedValue:(0,0))
            for i in 0..<self.dimension {
                switch direction {
                case .Up: buffer[i] = (i,iteration)
                case .Down:buffer[i] = (self.dimension - i - 1,iteration)
                case .Left:buffer[i] = (iteration,i)
                case .Right:buffer[i] = (iteration,self.dimension - i - 1)
                }
            }
            return buffer
        }
        
        
        var atLeastOneMove = false
        for i in 0..<dimension {
            let coords = coordiateGenerator(i)
            
            let tiles = coords.map({ (c:(Int,Int)) -> TileObject in
                let (x,y) = c
                return self.gameboard[x,y]
            })
            
            let orders = merge(tiles)
            atLeastOneMove = orders.count > 0 ? true : atLeastOneMove
            
            for object in orders {
                switch object {
                case let MoveOrder.SingleMoveOrder(s, d, v,wasMerge):
                    let (sx,sy) = coords[s]
                    let (dx,dy) = coords[d]
                    if wasMerge {
                        score += v
                    }
                    gameboard[sx,sy] = TileObject.Empty
                    gameboard[dx,dy] = TileObject.Tile(v)
                    delegate.moveOneTile(coords[s], to: coords[d], value: v)
                case let MoveOrder.DoubleMoveOrder(s1, s2, d, v):
                    let (s1x,s1y) = coords[s1]
                    let (s2x,s2y) = coords[s2]
                    let (dx,dy) = coords[d]
                    score += v
                    gameboard[s1x,s1y] = TileObject.Empty
                    gameboard[s2x,s2y] = TileObject.Empty
                    gameboard[dx,dy] = TileObject.Tile(v)
                    delegate.moveTwoTiles((coords[s1],coords[s2]), to: coords[d], value: v)
                }
            }
            
        }
        return atLeastOneMove
    }
    
    func condese(group:[TileObject]) -> [ActionToken] {
        var tokenBuffer = [ActionToken]()
        for (idx,tile) in group.enumerate() {
            switch tile {
            case let .Tile(value) where tokenBuffer.count == idx:
                tokenBuffer.append(ActionToken.NoAction(source: idx, value: value))
            case let .Tile(value):
                tokenBuffer.append(ActionToken.Move(source: idx, value: value))
            default:
                break
            }
            
        }
        return tokenBuffer
    }
    
    func collapse(group:[ActionToken]) -> [ActionToken] {
        var tokenBuffer = [ActionToken]()
        var skipNext = false
        for (idx,token) in group.enumerate() {
            if skipNext {
                skipNext = false
                continue
            }
            switch token {
            case .SingleCombine:
                assert(false, "Cannot have single combine token in input")
            case .DoubleCombine:
                assert(false, "Cannot have double combine token in input")
            case let .NoAction(s,v) where (idx < group.count-1) && v == group[idx+1].getValue() && GameModel.quiescentTileStillQuiescent(idx, outputLength: tokenBuffer.count, originalPosition: s):
                let next = group[idx + 1]
                let nv = v + group[idx+1].getValue()
                skipNext = true
                tokenBuffer.append(ActionToken.SingleCombine(source: next.getSource(), value: nv))
            case let t where (idx < group.count - 1 && t.getValue() == group[idx+1].getValue()):
                let next = group[idx+1]
                let nv = t.getValue() + group[idx+1].getValue()
                skipNext = true
                tokenBuffer.append(ActionToken.DoubleCombine(source: t.getSource(), second: next.getSource(), value: nv))
            case let .NoAction(s,v) where !GameModel.quiescentTileStillQuiescent(idx, outputLength: tokenBuffer.count, originalPosition: s):
                tokenBuffer.append(ActionToken.Move(source: s, value: v))
            case let .NoAction(s,v):
                tokenBuffer.append(ActionToken.NoAction(source: s, value: v))
            case let .Move(s, v):
                // Propagate a move
                tokenBuffer.append(ActionToken.Move(source: s, value: v))
            default:
                break
            }
        }
        return tokenBuffer
    }
    
    func convert(group:[ActionToken]) -> [MoveOrder] {
        var moveBuffer = [MoveOrder]()
        for (idx,t) in group.enumerate() {
            switch t {
            case let .Move(s,v):
                moveBuffer.append(MoveOrder.SingleMoveOrder(source: s, destination: idx, value: v, wasMerge: false))
            case let .SingleCombine(s,v):
                moveBuffer.append(MoveOrder.SingleMoveOrder(source: s, destination: idx, value: v, wasMerge: true))
            case let .DoubleCombine(s1, s2, v):
                moveBuffer.append(MoveOrder.DoubleMoveOrder(firstSource: s1, SecondSource: s2, destination: idx, value: v))
            default:
                break
            }
        }
        return moveBuffer
    }
    
    class func quiescentTileStillQuiescent(inputPosition: Int, outputLength: Int, originalPosition: Int) -> Bool {
        // Return whether or not a 'NoAction' token still represents an unmoved tile
        return (inputPosition == outputLength) && (originalPosition == inputPosition)
    }
    
    func merge(group:[TileObject]) -> [MoveOrder] {
        return convert(collapse(condese(group)))
    }
    
}
