//
//  ImageCollectionViewCell.swift
//  AffirmProject
//
//  Created by Nathan Pabrai on 6/11/18.
//  Copyright © 2018 Nathan Pabrai. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    static let identifier = "ImageCollectionViewCell"

	lazy var imageView = UIImageView()
    lazy var label = UILabel()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = frame
        label.frame = frame
        label.text = "Loading"
        addSubview(imageView)
        addSubview(label)
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    func setLoading() {
        label.isHidden = false
        imageView.image = nil
    }
    
    func setLoaded(withImage image:UIImage) {
        label.isHidden = true
        imageView.image = image
    }
	
	override func prepareForReuse() {
		super.prepareForReuse()
        setLoading()
	}
}
