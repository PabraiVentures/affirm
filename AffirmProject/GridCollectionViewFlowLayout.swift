//
//  GridCollectionViewFlowLayout.swift
//  AffirmProject
//
//  Created by Nathan Pabrai on 6/11/18.
//  Copyright © 2018 Nathan Pabrai. All rights reserved.
//

import UIKit

class GridCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    
    override var itemSize: CGSize {
        set {
            
        }
        get {
            let numberOfColumns: CGFloat = 3
            let itemWidth = ((self.collectionView?.frame.size.width ?? 0) - (numberOfColumns - 1)*minimumInteritemSpacing) / numberOfColumns
            return CGSize(width: itemWidth, height: itemWidth)
        }
    }


    override init() {
        super.init()
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    func setupLayout() {
        minimumInteritemSpacing = 8
        minimumLineSpacing = 8
        scrollDirection = .vertical
    }

}
