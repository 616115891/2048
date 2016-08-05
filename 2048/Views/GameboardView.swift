//
//  GameboardView.swift
//  2048
//
//  Created by apple on 16/7/13.
//  Copyright © 2016年 Keyon. All rights reserved.
//

import UIKit

class GameboardView: UIView {
    
    var dimension:Int
    var tileWidth:CGFloat
    var cornerRadius:CGFloat
    var tilePadding:CGFloat
    
    let provider = AppearanceProvider()
    
    var tiles:Dictionary<NSIndexPath,TileView>
    
    let tilePopStartScale: CGFloat = 0.1
    let tilePopMaxScale: CGFloat = 1.1
    let tilePopDelay: NSTimeInterval = 0.05
    let tileExpandTime: NSTimeInterval = 0.18
    let tileContractTime: NSTimeInterval = 0.08
    
    let tileMergeStartScale: CGFloat = 1.0
    let tileMergeExpandTime: NSTimeInterval = 0.08
    let tileMergeContractTime: NSTimeInterval = 0.08
    
    let perSquareSlideDuration: NSTimeInterval = 0.08
    
    init(dimension d: Int, tileWidth width: CGFloat, tilePadding padding: CGFloat, cornerRadius radius: CGFloat, backgroundColor: UIColor, foregroundColor: UIColor) {
        assert(d > 0)
        dimension = d
        tileWidth = width
        cornerRadius = radius
        tilePadding = padding
        let sideLength = width * CGFloat(d) + padding * CGFloat(d + 1)
        tiles = Dictionary()
        super.init(frame: CGRectMake(0, 0, sideLength, sideLength))
        
        layer.cornerRadius = radius
        
        setupBackground(backgroundColor: backgroundColor, tileColor: foregroundColor)
        
    }
    
    /// Reset the gameboard.
    func reset() {
        for (_, tile) in tiles {
            tile.removeFromSuperview()
        }
        tiles.removeAll(keepCapacity: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Return whether a given position is valid. Used for bounds checking.
    func positionIsValid(pos: (Int, Int)) -> Bool {
        let (x, y) = pos
        return (x >= 0 && x < dimension && y >= 0 && y < dimension)
    }
    
    func setupBackground(backgroundColor bgColor:UIColor,tileColor: UIColor) {
        backgroundColor = bgColor
        var xCursor = tilePadding
        var yCursor: CGFloat
        let bgRadius = (cornerRadius >= 2) ? cornerRadius - 2 : 0
        for _ in 0..<dimension {
            yCursor = tilePadding
            for _ in 0..<dimension {
                // Draw each tile
                let background = UIView(frame: CGRectMake(xCursor, yCursor, tileWidth, tileWidth))
                background.layer.cornerRadius = bgRadius
                background.backgroundColor = tileColor
                addSubview(background)
                yCursor += tilePadding + tileWidth
            }
            xCursor += tilePadding + tileWidth
        }
    }
    
    func insertTile(pos: (Int, Int), value: Int) {
        let (row,col) = pos
        let x = tilePadding + CGFloat(col) * (tileWidth + tilePadding)
        let y = tilePadding + CGFloat(row) * (tileWidth + tilePadding)
        let r = (cornerRadius >= 2) ? cornerRadius - 2 : 0
        let tile = TileView(position: CGPointMake(x, y), width: tileWidth, value: value, radius: r, delegate: provider)
        tile.layer.setAffineTransform(CGAffineTransformMakeScale(tilePopStartScale, tilePopStartScale))
        
        addSubview(tile)
        bringSubviewToFront(tile)
        
        tiles[NSIndexPath(forRow: row, inSection: col)] = tile
        
        
        UIView.animateWithDuration(tileExpandTime, delay: tilePopDelay, options: UIViewAnimationOptions.TransitionNone, animations: { 
            tile.layer.setAffineTransform(CGAffineTransformMakeScale(self.tilePopMaxScale, self.tilePopMaxScale))
            }) { (finished) in
                UIView.animateWithDuration(self.tileContractTime, animations: { 
                    tile.layer.setAffineTransform(CGAffineTransformIdentity)
                })
        }
        
    }
    
    func moveOneTile(from:(Int,Int),to:(Int,Int),value:Int) {
        let (fromRow,fromCol) = from
        let (toRow,toCol) = to
        let fromKey = NSIndexPath(forRow: fromRow, inSection: fromCol)
        let toKey = NSIndexPath(forRow: toRow, inSection: toCol)
        
        guard let tile = tiles[fromKey] else {
            assert(false, "placeholder error")
        }
        
        let endTile = tiles[toKey]
        
        var finalFrame = tile.frame
        finalFrame.origin.x = tilePadding + CGFloat(toCol)*(tileWidth + tilePadding)
        finalFrame.origin.y = tilePadding + CGFloat(toRow)*(tileWidth + tilePadding)
        
        tiles.removeValueForKey(fromKey)
        tiles[toKey] = tile
        
        let shouldPop = endTile != nil
        UIView.animateWithDuration(perSquareSlideDuration, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { 
            tile.frame = finalFrame
            }) { (finished) in
                tile.value = value
                endTile?.removeFromSuperview()
                if !shouldPop || !finished {
                    return
                }
                tile.layer.setAffineTransform(CGAffineTransformMakeScale(self.tileMergeStartScale, self.tileMergeStartScale))
                // Pop tile
                UIView.animateWithDuration(self.tileMergeExpandTime,
                                           animations: {
                                            tile.layer.setAffineTransform(CGAffineTransformMakeScale(self.tilePopMaxScale, self.tilePopMaxScale))
                    },
                                           completion: { finished in
                                            // Contract tile to original size
                                            UIView.animateWithDuration(self.tileMergeContractTime) {
                                                tile.layer.setAffineTransform(CGAffineTransformIdentity)
                                            }
                })
        }
    }
    
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        assert(positionIsValid(from.0) && positionIsValid(from.1) && positionIsValid(to))
        let (fromRowA, fromColA) = from.0
        let (fromRowB, fromColB) = from.1
        let (toRow, toCol) = to
        let fromKeyA = NSIndexPath(forRow: fromRowA, inSection: fromColA)
        let fromKeyB = NSIndexPath(forRow: fromRowB, inSection: fromColB)
        let toKey = NSIndexPath(forRow: toRow, inSection: toCol)
        
        guard let tileA = tiles[fromKeyA] else {
            assert(false, "placeholder error")
        }
        guard let tileB = tiles[fromKeyB] else {
            assert(false, "placeholder error")
        }
        
        // Make the frame
        var finalFrame = tileA.frame
        finalFrame.origin.x = tilePadding + CGFloat(toCol)*(tileWidth + tilePadding)
        finalFrame.origin.y = tilePadding + CGFloat(toRow)*(tileWidth + tilePadding)
        
        // Update the state
        let oldTile = tiles[toKey]  // TODO: make sure this doesn't cause issues
        oldTile?.removeFromSuperview()
        tiles.removeValueForKey(fromKeyA)
        tiles.removeValueForKey(fromKeyB)
        tiles[toKey] = tileA
        
        UIView.animateWithDuration(perSquareSlideDuration,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.BeginFromCurrentState,
                                   animations: {
                                    // Slide tiles
                                    tileA.frame = finalFrame
                                    tileB.frame = finalFrame
            },
                                   completion: { finished in
                                    tileA.value = value
                                    tileB.removeFromSuperview()
                                    if !finished {
                                        return
                                    }
                                    tileA.layer.setAffineTransform(CGAffineTransformMakeScale(self.tileMergeStartScale, self.tileMergeStartScale))
                                    // Pop tile
                                    UIView.animateWithDuration(self.tileMergeExpandTime,
                                        animations: {
                                            tileA.layer.setAffineTransform(CGAffineTransformMakeScale(self.tilePopMaxScale, self.tilePopMaxScale))
                                        },
                                        completion: { finished in
                                            // Contract tile to original size
                                            UIView.animateWithDuration(self.tileMergeContractTime) {
                                                tileA.layer.setAffineTransform(CGAffineTransformIdentity)
                                            }
                                    })
        })
    }

}
