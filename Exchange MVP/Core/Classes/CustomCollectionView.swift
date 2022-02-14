//
//  CustomCollectionView.swift
//  Exchange MVP
//
//  Created by Oleg Shum on 09.02.2022.
//

import UIKit

final class CustomCollectionView: UICollectionView {
        
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 20, height: 150)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        super.init(frame: .zero, collectionViewLayout: layout)
        
        register(CustomCell.self, forCellWithReuseIdentifier: CustomCell.reuseId)
        isPagingEnabled = true
        translatesAutoresizingMaskIntoConstraints = false
        showsHorizontalScrollIndicator = false
    }
     
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

