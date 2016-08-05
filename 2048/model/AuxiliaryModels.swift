//
//  AuxiliaryModels.swift
//  2048
//
//  Created by apple on 16/7/13.
//  Copyright © 2016年 Keyon. All rights reserved.
//

import Foundation


enum MoveDirection {
    case Up,Down,Left,Right
}
struct MoveCommand {
    let direction : MoveDirection
    let completion:(Bool) -> ()
}

enum MoveOrder {
    case SingleMoveOrder(source: Int, destination: Int, value: Int, wasMerge: Bool)
    case DoubleMoveOrder(firstSource:Int,SecondSource:Int,destination: Int, value: Int)
}

enum TileObject {
    case Empty
    case Tile(Int)
}

enum ActionToken {
    case NoAction(source:Int,value:Int)
    case Move(source:Int,value:Int)
    case SingleCombine(source:Int,value:Int)
    case DoubleCombine(source:Int,second:Int,value:Int)
    
    
    func getValue() -> Int {
        switch self {
        case let .NoAction(_,v): return v
        case let .Move(_,v): return v
        case let .SingleCombine(_,v): return v
        case let .DoubleCombine(_,_,v): return v
        }
    }
    
    
    func getSource() -> Int {
        switch self {
        case let .NoAction(s,_): return s
        case let .Move(s,_): return s
        case let .SingleCombine(s,_): return s
        case let .DoubleCombine(s,_,_): return s
        }
    }
}


struct SquareGameboard<T> {
    let dimension:Int
    var boardArray:[T]
    
    init(dimension d:Int,initiaValue:T) {
        dimension = d
        boardArray = [T](count:d*d,repeatedValue:initiaValue)
    }
    
    subscript(row:Int,col:Int) -> T {
        get {
            return boardArray[row * dimension + col]
        }
        set {
            boardArray[row*dimension + col] = newValue
        }
    }
    
    mutating func setAll(item:T) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                self[i,j] = item
            }
        }
    }
}
