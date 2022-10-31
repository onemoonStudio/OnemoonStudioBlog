//
//  BaseCarouselCell.swift
//  CompositionalLayout
//
//  Created by HyeonTae Kim on 2022/10/30.
//

import UIKit

class BaseCarouselCell: UICollectionViewCell {
    private let imageView = UIView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setSubviewsLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("")
    }
    
    func setModel(_ model: Int) {
        switch model {
        case 0:
            imageView.backgroundColor = .yellow
            titleLabel.text = "iconic1!"
        case 1:
            imageView.backgroundColor = .blue
            titleLabel.text = "iconic2!"
        case 2:
            imageView.backgroundColor = .red
            titleLabel.text = "Action"
        case 3:
            imageView.backgroundColor = .brown
            titleLabel.text = "Adventure"
        case 4:
            imageView.backgroundColor = .gray
            titleLabel.text = "Strategy"
        default:
            return
        }
    }
    
    private func setSubviewsLayout() {
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.layer.cornerRadius = 8
        
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
}
