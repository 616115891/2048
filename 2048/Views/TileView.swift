//
//  TileView.swift
//  2048
//
//  Created by apple on 16/7/13.
//  Copyright © 2016年 Keyon. All rights reserved.
//

import UIKit

class TileView: UIView {
    var value:Int = 0 {
        didSet {
            backgroundColor = delegate.tileColor(value)
            numberLabel.textColor = delegate.numberColor(value)
            numberLabel.text = "\(value)"
        }
    }
    
    unowned let delegate : AppearanceProviderProtocol
    let numberLabel : UILabel
    
    init(position:CGPoint,width:CGFloat,value:Int,radius:CGFloat,delegate d:AppearanceProviderProtocol) {
        delegate = d
        numberLabel = UILabel(frame: CGRectMake(0,0,width,width))
        numberLabel.textAlignment = NSTextAlignment.Center
        numberLabel.minimumScaleFactor = 0.5
        numberLabel.font = delegate.fontForNumbers()
        
        super.init(frame: CGRectMake(position.x, position.y, width, width))
        addSubview(numberLabel)
        layer.cornerRadius = radius
        
        self.value = value
        backgroundColor = delegate.tileColor(value)
        numberLabel.textColor = delegate.numberColor(value)
        numberLabel.text = "\(value)"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
