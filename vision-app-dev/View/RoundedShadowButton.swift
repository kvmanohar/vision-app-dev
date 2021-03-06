//
//  RoundedShadowButton.swift
//  vision-app-dev
//
//  Created by Manohar Kurapati on 18/12/2017.
//  Copyright © 2017 Manosoft. All rights reserved.
//

import UIKit

class RoundedShadowButton: UIButton {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = self.frame.height / 2
        
    }

}
