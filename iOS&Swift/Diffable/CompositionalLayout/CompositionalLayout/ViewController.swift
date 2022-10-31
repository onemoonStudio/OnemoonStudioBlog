//
//  ViewController.swift
//  CompositionalLayout
//
//  Created by HyeonTae Kim on 2022/10/30.
//

import UIKit

class ViewController: UIViewController {
    
    private enum Section: Int, CaseIterable {
        case iconicCharacter
        case categories
    }
    
    private typealias Datasource = UICollectionViewDiffableDataSource<Section, AnyHashable>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AnyHashable>
    
    private lazy var mainCollectionView = UICollectionView(frame: .zero, collectionViewLayout: compositionalLayout)
    private lazy var compositionalLayout: UICollectionViewCompositionalLayout = {
        UICollectionViewCompositionalLayout { [unowned self] sectionIndex, env in
            switch Section(rawValue: sectionIndex) {
                // SectionProvider
            case .iconicCharacter:
                return baseCarouselLayout()
            case .categories:
                return baseCarouselLayout()
            case .none:
                return nil
            }
        }
    }()
    private lazy var dataSource: Datasource = {
        Datasource(collectionView: mainCollectionView) { collectionView, indexPath, itemIdentifier in
            switch Section(rawValue: indexPath.section) {
            case .iconicCharacter, .categories:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BaseCarouselCell", for: indexPath) as? BaseCarouselCell
                let model = itemIdentifier as! Int
                cell?.setModel(model)
                return cell
            case .none:
                return nil
            }
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setMainCollectionView()
        setSnapshot()
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: "BaseCarouselHeaderView",
                                                                             for: indexPath)
            return headerView
        }
    }
    
    private func setMainCollectionView() {
        view.addSubview(mainCollectionView)
        mainCollectionView.translatesAutoresizingMaskIntoConstraints = false
        mainCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        mainCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        mainCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        mainCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        mainCollectionView.layer.borderColor = UIColor.black.cgColor
        mainCollectionView.layer.borderWidth = 1.0
        
        mainCollectionView.register(BaseCarouselCell.self, forCellWithReuseIdentifier: "BaseCarouselCell")
        mainCollectionView.register(BaseCarouselHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "BaseCarouselHeaderView")
        
    }

    private func baseCarouselLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
//        let groupWidth: NSCollectionLayoutDimension = .absolute(250)
        let groupWidth: NSCollectionLayoutDimension = .fractionalWidth(0.6)
        let groupSize = NSCollectionLayoutSize(widthDimension: groupWidth, heightDimension: .absolute(150))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 50, leading: 20, bottom: 40, trailing: 20)
        section.interGroupSpacing = 8
        section.orthogonalScrollingBehavior = .groupPaging
        
        let supplementaryItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
        let supplementaryItemLayoutAnchor = NSCollectionLayoutAnchor(edges: [.top], absoluteOffset: CGPoint(x: 0, y: 10))
        let supplementaryItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: supplementaryItemSize,
                                                                            elementKind: UICollectionView.elementKindSectionHeader,
                                                                            containerAnchor: supplementaryItemLayoutAnchor)
        section.boundarySupplementaryItems = [supplementaryItem]
        return section
    }
    
    private func setSnapshot() {
        var snapShot = Snapshot()
        snapShot.appendSections(Section.allCases)
        snapShot.appendItems([0, 1], toSection: .iconicCharacter)
        snapShot.appendItems([2, 3, 4], toSection: .categories)
        dataSource.apply(snapShot, animatingDifferences: true)
    }
}
