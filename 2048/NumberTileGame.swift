//
//  NumberTileGame.swift
//  2048
//
//  Created by apple on 16/7/13.
//  Copyright © 2016年 Keyon. All rights reserved.
//

import UIKit

class NumberTileGame: UIViewController,GameModelProtocol {
    
    // How many tiles in both directions the gameboard contains
    var dimension: Int
    // The value of the winning tile
    var threshold: Int
    
    // Amount of space to place between the different component views (gameboard, score view, etc)
    let viewPadding: CGFloat = 10.0
    
    // Width of the gameboard
    let boardWidth: CGFloat = 230.0
    
    var board: GameboardView?
    var model : GameModel?
    var scoreView:AccessoryView?
    
    init(dimension d: Int, threshold t: Int) {
        dimension = d > 2 ? d : 2
        threshold = t > 8 ? t : 8
        super.init(nibName: nil, bundle: nil)
        model = GameModel(dimension: dimension, threshold: threshold, delegate: self)
        view.backgroundColor = UIColor.whiteColor()
        setuoSwipeControls()
        
    }
    
    func setuoSwipeControls() {
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(upCommand(_:)))
        upSwipe.numberOfTouchesRequired = 1
        upSwipe.direction = UISwipeGestureRecognizerDirection.Up
        view.addGestureRecognizer(upSwipe)
        
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(downCommand(_:)))
        downSwipe.numberOfTouchesRequired = 1
        downSwipe.direction = UISwipeGestureRecognizerDirection.Down
        view.addGestureRecognizer(downSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(leftCommand(_:)))
        leftSwipe.numberOfTouchesRequired = 1
        leftSwipe.direction = UISwipeGestureRecognizerDirection.Left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(rightCommand(_:)))
        rightSwipe.numberOfTouchesRequired = 1
        rightSwipe.direction = UISwipeGestureRecognizerDirection.Right
        view.addGestureRecognizer(rightSwipe)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
        // Do any additional setup after loading the view.
    }
    
    func setupGame() {
        let vcHeight = view.bounds.size.height
        let vcWidth = view.bounds.size.width
        
        func xPositionToCenterView(v:UIView) -> CGFloat {
            let viewWidth = v.bounds.size.width
            let totalX = 0.5 * (vcWidth - viewWidth)
            return totalX > 0 ? totalX : 0
        }
        
        func yPositionForViewAtPosition(order:Int,views:[UIView]) -> CGFloat {
            let totalHeight = views.map({ $0.bounds.size.height }).reduce(0, combine: { $0 + $1 })
            let viewsTop = 0.5*(vcHeight - totalHeight) > 0 ? 0.5*(vcHeight - totalHeight) : 0
            var acc:CGFloat = 0.0
            for i in 0..<order {
                acc = viewPadding + views[i].bounds.size.height
            }
            return viewsTop + acc
        }
        
        let scoreView = AccessoryView(backgroundColor: UIColor.blackColor(), fontColor: UIColor.whiteColor())
        scoreView.scoreChange(newScore: 0)
        
        let padding:CGFloat = dimension > 5 ? 3 : 6
        let tileWidth = boardWidth/CGFloat(dimension)
        let gameboard = GameboardView(dimension: dimension, tileWidth: tileWidth, tilePadding: padding, cornerRadius: 4, backgroundColor: UIColor.blackColor(), foregroundColor: UIColor.darkGrayColor())
        
        let views = [scoreView,gameboard]
        
        var f = scoreView.frame
        f.origin.x = xPositionToCenterView(scoreView)
        f.origin.y = yPositionForViewAtPosition(0, views: views)
        scoreView.frame = f
        
        f = gameboard.frame
        f.origin.x = xPositionToCenterView(gameboard)
        f.origin.y = yPositionForViewAtPosition(1, views: views)
        gameboard.frame = f
        
        view.addSubview(scoreView)
        self.scoreView = scoreView
        view.addSubview(gameboard)
        self.board = gameboard
        
        model?.insertTileAtRandomLocation(2)
        model?.insertTileAtRandomLocation(2)
        
    }
    
    func scoreChanged(score: Int) {
        if let m = model {
            scoreView?.scoreChange(newScore: m.score)
        }
        
    }
    
    func insertTile(location: (Int, Int), value: Int) {
        board?.insertTile(location, value: value)
    }
    
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
        board?.moveOneTile(from, to: to, value: value)
    }
    
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        board?.moveTwoTiles(from, to: to, value: value)
    }
    
    // Misc
    func followUp() {
        assert(model != nil)
        let m = model!
        let (userWon, _) = m.userHasWon()
        if userWon {
            // TODO: alert delegate we won
            let alertView = UIAlertView()
            alertView.title = "Victory"
            alertView.message = "You won!"
            alertView.addButtonWithTitle("Cancel")
            alertView.show()
            // TODO: At this point we should stall the game until the user taps 'New Game' (which hasn't been implemented yet)
            return
        }
        
        // Now, insert more tiles
        let randomVal = Int(arc4random_uniform(10))
        m.insertTileAtRandomLocation(randomVal == 1 ? 4 : 2)
        
        // At this point, the user may lose
        if m.userHasLost() {
            // TODO: alert delegate we lost
            NSLog("You lost...")
            let alertView = UIAlertView()
            alertView.title = "Defeat"
            alertView.message = "You lost..."
            alertView.addButtonWithTitle("Cancel")
            alertView.show()
        }
    }
    
    // Commands
    func upCommand(r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(MoveDirection.Up,
                    completion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
    }
    
    func downCommand(r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(MoveDirection.Down,
                    completion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
    }
    
    func leftCommand(r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(MoveDirection.Left,
                    completion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
    }
    
    func rightCommand(r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(MoveDirection.Right,
                    completion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
    }
    
}
