//
//  creditsView.swift
//  phyphox
//
//  Created by Sebastian Kuhlen on 11.05.17.
//  Copyright © 2017 RWTH Aachen. All rights reserved.
//

import Foundation

final class CreditsView: UIView {
    
    var onCloseCallback: (() -> Void)?
    var onLicenceCallback: (() -> Void)?
    
    let scrollView: UIScrollView
    let dialogView: UIView
    let rwthLogo: UIImageView
    let creditsRWTH: UILabel
    let namesBackground: UIView
    let creditsNames: UILabel
    let creditsGPL: UILabel
    let closeButton: UIButton
    let licenceButton: UIButton
    
    let maxWidth: CGFloat = 450.0
    let logoWidth: CGFloat = 200.0
    let margin: CGFloat = 20.0
    let fontSize = UIFont.systemFontSize
    
    override init(frame: CGRect) {
        
        dialogView = UIView()
        dialogView.backgroundColor = kRWTHBackgroundColor
        dialogView.layer.cornerRadius = 8.0
        dialogView.clipsToBounds = true
        dialogView.layer.borderColor = UIColor(white: 0.5, alpha: 1.0).cgColor
        dialogView.layer.borderWidth = 0.5
        
        scrollView = UIScrollView()
        
        rwthLogo = UIImageView(image: UIImage(named: "rwth"))
        
        creditsRWTH = UILabel()
        creditsRWTH.numberOfLines = 0
        creditsRWTH.text = localize("creditsRWTH")
        creditsRWTH.font = UIFont.systemFont(ofSize: fontSize)
        creditsRWTH.textColor = kRWTHTextColor
        
        namesBackground = UIView()
        namesBackground.backgroundColor = kRWTHBlue
        
        creditsNames = UILabel()
        creditsNames.numberOfLines = 0
        
        creditsGPL = UILabel()
        creditsGPL.numberOfLines = 0
        creditsGPL.text = localize("gpl")
        creditsGPL.font = UIFont.systemFont(ofSize: fontSize)
        creditsGPL.textColor = kRWTHTextColor
        
        closeButton = UIButton()
        closeButton.setTitle(localize("close"), for: UIControlState())
        closeButton.backgroundColor = kRWTHBackgroundColor
        closeButton.setTitleColor(kRWTHTextColor, for: UIControlState.normal)
        closeButton.setTitleColor(kRWTHBlue, for: UIControlState.highlighted)
        closeButton.layer.borderColor = UIColor(white: 0.5, alpha: 1.0).cgColor
        closeButton.layer.borderWidth = 0.5
        
        licenceButton = UIButton()
        licenceButton.setTitle("Open Source Licences", for: UIControlState())
        licenceButton.backgroundColor = kRWTHBackgroundColor
        licenceButton.setTitleColor(kRWTHTextColor, for: UIControlState.normal)
        licenceButton.setTitleColor(kRWTHBlue, for: UIControlState.highlighted)
        licenceButton.layer.borderColor = UIColor(white: 0.5, alpha: 1.0).cgColor
        licenceButton.layer.borderWidth = 0.5
        
        super.init(frame: CGRect.zero)
        
        creditsNames.attributedText = formatNames(raw: localize("creditsNames"))
        
        self.backgroundColor = kDarkenedColor
        
        closeButton.addTarget(self, action: #selector(CreditsView.closeButtonPressed), for: .touchUpInside)
        licenceButton.addTarget(self, action: #selector(CreditsView.licenceButtonPressed), for: .touchUpInside)
        
        scrollView.addSubview(rwthLogo)
        scrollView.addSubview(creditsRWTH)
        namesBackground.addSubview(creditsNames)
        scrollView.addSubview(namesBackground)
        scrollView.addSubview(creditsGPL)
        dialogView.addSubview(scrollView)
        dialogView.addSubview(licenceButton)
        dialogView.addSubview(closeButton)
        addSubview(dialogView)
        
        self.autoresizingMask = [.flexibleBottomMargin, .flexibleHeight, .flexibleWidth, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    @objc func closeButtonPressed() {
        onCloseCallback?()
    }
    
    @objc func licenceButtonPressed() {
        onLicenceCallback?()
    }
    
    func formatNames(raw: String) -> NSAttributedString {
        let str = NSMutableAttributedString(string: raw, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: fontSize), NSAttributedStringKey.foregroundColor: kRWTHBackgroundColor])
        var searchIndex = raw.startIndex
        while true {
            let searchString = String(raw[searchIndex...])
            let endOfLine = searchString.range(of: "\n")?.lowerBound ?? searchString.endIndex
            let end = raw.index(searchIndex, offsetBy: raw.distance(from: searchString.startIndex, to: endOfLine))
            let searchLine = String(raw[searchIndex..<end])
            if searchLine.range(of: ":") != nil {
                //This line is a headline
                if end < raw.endIndex {
                    searchIndex = raw.index(end, offsetBy: 1)
                    continue
                } else {
                    break
                }
            }
            
            let range = NSMakeRange(raw.distance(from: raw.startIndex, to: searchIndex), raw.distance(from: searchIndex, to: end))

            str.setAttributes([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: fontSize), NSAttributedStringKey.foregroundColor: kRWTHBackgroundColor], range: range)

            if end < raw.endIndex {
                searchIndex = raw.index(end, offsetBy: 1)
            } else {
                break
            }
        }
        return str
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = min(frame.width - 2*margin, maxWidth)
        let targetArea = CGSize(width: width - 2*margin, height: 100000)
        
        var closeButtonSize = closeButton.sizeThatFits(CGSize(width: width, height: 100000))
        closeButtonSize.height += margin
        
        var licenceButtonSize = licenceButton.sizeThatFits(CGSize(width: width, height: 100000))
        licenceButtonSize.height += margin
        
        var actualArea = CGSize(width: width, height: margin)
        
        let logoSize = CGSize(width: logoWidth, height: logoWidth/rwthLogo.image!.size.width * rwthLogo.image!.size.height)
        rwthLogo.frame = CGRect(x: width - logoSize.width - margin, y: actualArea.height, width: logoSize.width, height: logoSize.height)
        actualArea.height += logoSize.height + margin
        
        let rwthSize = creditsRWTH.sizeThatFits(targetArea)
        creditsRWTH.frame = CGRect(x: margin, y: actualArea.height, width: rwthSize.width, height: rwthSize.height)
        actualArea.height += rwthSize.height + margin
        
        let namesSize = creditsNames.sizeThatFits(CGSize(width: targetArea.width * 0.75, height: 100000))
        let namesBackgroundSize = CGSize(width: namesSize.width + 2*margin, height: namesSize.height + 2*margin)
        creditsNames.frame = CGRect(x: margin, y: margin, width: namesSize.width, height: namesSize.height)
        namesBackground.frame = CGRect(x: margin, y: actualArea.height, width: namesBackgroundSize.width, height: namesBackgroundSize.height)
        actualArea.height += namesBackgroundSize.height + margin
        
        let gplSize = creditsGPL.sizeThatFits(targetArea)
        creditsGPL.frame = CGRect(x: margin, y: actualArea.height, width: gplSize.width, height: gplSize.height)
        actualArea.height += gplSize.height + margin
        
        let height = min(frame.height - 2*margin - closeButtonSize.height - licenceButtonSize.height, actualArea.height)
        scrollView.contentSize = actualArea
        dialogView.frame = CGRect(x: (frame.width - width)/2.0, y: (frame.height - height - closeButtonSize.height - licenceButtonSize.height)/2.0, width: width, height: height + closeButtonSize.height + licenceButtonSize.height)
        scrollView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        licenceButton.frame = CGRect(x: scrollView.frame.minX, y: scrollView.frame.maxY + 0.5, width: max(closeButtonSize.width, width), height: closeButtonSize.height)
        closeButton.frame = CGRect(x: scrollView.frame.minX, y: licenceButton.frame.maxY - 0.5, width: max(closeButtonSize.width, width), height: closeButtonSize.height)
        
    }
}
