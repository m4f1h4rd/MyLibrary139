//
//  LNParallaxHeaderFlowLayout.swift
//
//
//  Copyright © 2020 Lanars. All rights reserved.
//  https://lanars.com/
//

import UIKit

public class LNParallaxHeaderFlowLayout: UICollectionViewFlowLayout {
    
    static public let kind = String(describing: LNParallaxHeaderFlowLayout.self)

    /// Determine header behavior when resizing.
    public var isAlwaysOnTop = false
    
    /// Mini size of the header when header always on top
    public var minSize: CGSize = .zero
    
    /// Header size without scroll
    public var indicativeSize: CGSize? {
        didSet{
            invalidateLayout()
        }
    }
    
    // MARK: - Lifecycle
    
    override public func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath)
        
        guard
            var frame = attributes?.frame,
            let height = indicativeSize?.height
        else { return attributes }
        
        frame.origin.y += height
        attributes?.frame = frame
        
        return attributes
    }
    
    override public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        
        return attributes != nil && elementKind == LNParallaxHeaderFlowLayout.kind ?
            LNParallaxHeaderFlowLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath) :
            attributes
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard
            let size = indicativeSize,
            let width = indicativeSize?.width,
            let height = indicativeSize?.height,
            let layoutCollectionView = collectionView
        else { return nil }
        
        var adjustedRec = rect
        adjustedRec.origin.y -= height
        
        let attributes = super.layoutAttributesForElements(in: adjustedRec)
        var allItems: [UICollectionViewLayoutAttributes] = []
        
        attributes?
            .compactMap({ $0.copy() as? UICollectionViewLayoutAttributes })
            .forEach { allItems.append($0) }
        
        var headers: [Int: UICollectionViewLayoutAttributes] = [:]
        var lastCells: [Int: UICollectionViewLayoutAttributes] = [:]
        var isVisible = false
        
        allItems.forEach { attributes in
            var frame = attributes.frame
            frame.origin.y += height
            attributes.frame = frame
            
            if attributes.representedElementKind == UICollectionView.elementKindSectionHeader {
                headers[attributes.indexPath.section] = attributes
            } else {
                let currentAttribute = lastCells[attributes.indexPath.section]
                
                if currentAttribute == nil || currentAttribute?.indexPath != nil && attributes.indexPath.row > (currentAttribute as AnyObject).indexPath.row {
                    lastCells[attributes.indexPath.section] = attributes
                }
                
                if attributes.indexPath.item == .zero && attributes.indexPath.section == .zero {
                    isVisible = true
                }
            }
            
            attributes.zIndex = Constants.zIndex.min
        }
        
        isVisible = rect.minY <= .zero ? true : isVisible
        isVisible = isAlwaysOnTop ? true : isVisible
        
        if isVisible && !CGSize.zero.equalTo(size) {
            let currentAttribute = LNParallaxHeaderFlowLayoutAttributes(forSupplementaryViewOfKind: LNParallaxHeaderFlowLayout.kind, with: IndexPath(index: .zero))
            var frame = currentAttribute.frame
            frame.size.width = width
            frame.size.height = height
            
            let maxY = frame.maxY
            
            var y = min(maxY - minSize.height, layoutCollectionView.bounds.origin.y + layoutCollectionView.contentInset.top)
            
            let height = max(.zero, -y + maxY)
            let maxHeight = size.height
            let minHeight = minSize.height
            let progressiveness = (height - minHeight) / (maxHeight - minHeight)
            
            currentAttribute.progressiveness = progressiveness
            currentAttribute.zIndex = .zero
            
            if isAlwaysOnTop && height <= minSize.height {
                collectionView.map({ y = $0.contentOffset.y + $0.contentInset.top })
                currentAttribute.zIndex = Constants.zIndex.max
            }
            
            currentAttribute.frame = CGRect(x: frame.origin.x, y: y, width: frame.size.width, height: height)
            allItems.append(currentAttribute)
        }
        
        lastCells.forEach { cell in
            let numberOfSection = cell.value.indexPath.section
            
            var header = headers[numberOfSection]
            
            if header == nil {
                header = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: .zero, section: numberOfSection))
                
                header.map({ allItems.append($0) })
            }
            
            guard
                let attributes = header,
                let lastCellAttributes = lastCells[numberOfSection]
            else { return }
            
            update(attributes: attributes, lastCellAttributes: lastCellAttributes)
        }
        
        return allItems
    }
    
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard
            let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes,
            let height = indicativeSize?.height
        else {
            return nil
        }
        
        var frame = attributes.frame
        frame.origin.y += height
        attributes.frame = frame
        return attributes
    }
    
    override public var collectionViewContentSize: CGSize {
        guard collectionView?.superview != nil else { return .zero }

        var size = super.collectionViewContentSize
        indicativeSize.map { size.height += $0.height }
        return size
    }
    
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
}

// MARK: - Private

private extension LNParallaxHeaderFlowLayout {
        
    func update(attributes: UICollectionViewLayoutAttributes, lastCellAttributes: UICollectionViewLayoutAttributes) {
        guard let collectionView = collectionView else { return }
        
        attributes.zIndex = Constants.zIndex.default
        attributes.isHidden = false
        
        var origin = attributes.frame.origin
        
        let sectionMaxY = lastCellAttributes.frame.maxY - attributes.frame.size.height

        let bounds = collectionView.bounds
        var y = bounds.maxY - bounds.height + collectionView.contentInset.top
        
        if isAlwaysOnTop {
            y += minSize.height
        }
        
        let maxY = min(max(y, attributes.frame.origin.y), sectionMaxY)
        origin.y = maxY
        
        attributes.frame = CGRect(x: origin.x, y: origin.y, width: attributes.frame.size.width, height: attributes.frame.size.height)
    }
    
    // MARK: - Constants

    enum Constants {
        enum zIndex {
            static let `default` = 1024
            static let min = 1
            static let max = 2000
        }
    }
    
}
