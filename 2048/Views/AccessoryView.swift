//
//  AccessoryView.swift
//  2048
//
//  Created by apple on 16/7/13.
//  Copyright © 2016年 Keyon. All rights reserved.
//

import UIKit

class AccessoryView: UIView {
    
    let defaultFrame = CGRectMake(0,0, 140, 40)
    
    private var label:UILabel
    
    init(backgroundColor bgColor:UIColor,fontColor:UIColor) {
        label = UILabel(frame: CGRectMake(0,0,140,40))
        label.textAlignment = NSTextAlignment.Center
        super.init(frame: defaultFrame)
        self.backgroundColor = bgColor
        label.textColor = fontColor
        layer.cornerRadius = 4
        self.addSubview(label)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scoreChange(newScore s:Int) {
        label.text = "SCORE: \(s)"
    }
    
}
