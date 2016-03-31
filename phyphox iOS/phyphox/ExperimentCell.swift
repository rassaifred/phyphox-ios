//
//  ExperimentCell.swift
//  phyphox
//
//  Created by Jonas Gessner on 04.12.15.
//  Copyright © 2015 RWTH Aachen. All rights reserved.
//

import UIKit

class ExperimentCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var iconView: UIView?
    
    private let separator = UIView()
    private let sideSeparator = UIView()
    
    var showSeparator = true {
        didSet {
            separator.hidden = !showSeparator
        }
    }
    
    var showSideSeparator = true {
        didSet {
            sideSeparator.hidden = !showSideSeparator
        }
    }
    
    override var highlighted: Bool {
        didSet {
            UIView.animateWithDuration(0.1) {
                self.contentView.backgroundColor = UIColor(white: (self.highlighted ? 0.85 : 0.975), alpha: 1.0)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        subtitleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        
        titleLabel.textColor = kHighlightColor
        
        separator.backgroundColor = UIColor.blackColor()
        separator.alpha = 0.1
        
        sideSeparator.backgroundColor = UIColor.blackColor()
        sideSeparator.alpha = 0.1
        
        
        contentView.backgroundColor = UIColor(white: 0.975, alpha: 1.0)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        contentView.addSubview(separator)
        contentView.addSubview(sideSeparator)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var experiment: Experiment? {
        didSet {
            if experiment !=-= oldValue {
                titleLabel.text = experiment?.localizedTitle
                subtitleLabel.text = experiment?.localizedDescription
                
                if iconView != nil {
                    iconView?.removeFromSuperview()
                }
                
                if experiment != nil {
                    iconView = experiment!.icon.generateResizableRepresentativeView()
                    contentView.addSubview(iconView!)
                }
                
                setNeedsLayout()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let s1 = CGSizeMake(bounds.size.height-8.0, bounds.size.height-8.0)
        
        iconView?.frame = CGRectMake(4.0, 4.0, s1.width, s1.height)
        
        let x = (iconView != nil ? CGRectGetMaxX(iconView!.frame) : 0.0)
        
        let maxLabelSize = CGSizeMake(contentView.bounds.size.width-x-8.0, contentView.bounds.height)
        
        var s2 = titleLabel.sizeThatFits(maxLabelSize)
        s2.width = min(maxLabelSize.width, s2.width)
        
        titleLabel.frame = CGRectMake(x+4.0, 4.0, s2.width, s2.height)
        
        var s3 = subtitleLabel.sizeThatFits(maxLabelSize)
        s3.width = min(maxLabelSize.width, s3.width)
        
        subtitleLabel.frame = CGRectMake(x+4.0, contentView.bounds.size.height-s3.height-4.0, s3.width, s3.height)
        
        
        
        let separatorHeight = 1.0/UIScreen.mainScreen().scale
        
        separator.frame = CGRectMake(0.0, contentView.bounds.size.height-separatorHeight, contentView.bounds.size.width, separatorHeight)
        
        sideSeparator.frame = CGRectMake(contentView.bounds.size.width-separatorHeight, 0.0, separatorHeight, contentView.bounds.size.height)
    }
}