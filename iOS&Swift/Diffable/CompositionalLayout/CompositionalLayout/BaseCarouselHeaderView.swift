//
//  BaseCarouselHeaderView.swift
//  CompositionalLayout
//
//  Created by HyeonTae Kim on 2022/10/30.
//

import UIKit

class BaseCarouselHeaderView: UICollectionReusableView {
    
    private let separator = UIView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setSubviewsLayout()
        separator.backgroundColor = .gray
        titleLabel.text = "Section Header"
        self.backgroundColor = .lightGray
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setSubviewsLayout() {
        self.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        separator.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        separator.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        self.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: self.separator.bottomAnchor, constant: 4).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4).isActive = true
    }
}
