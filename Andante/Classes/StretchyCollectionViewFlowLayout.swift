//
//  StretchyCollectionViewFlowLayout.swift
//  Andante
//
//  Created by Miles on 8/28/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class StretchyCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else { return super.shouldInvalidateLayout(forBoundsChange: newBounds) }
        
        let minOffset: CGFloat = 0
        let maxOffset: CGFloat = max(0, collectionView.contentSize.width - collectionView.bounds.width)
        
        if newBounds.origin.x < minOffset {
            return true
        }
        else if newBounds.origin.x > maxOffset {
            return true
        }
        else {
            return super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let cells = super.layoutAttributesForElements(in: rect)
        return cells?.compactMap { self.layoutAttributesForItem(at: $0.indexPath) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        
        guard let collectionView = self.collectionView else { return attributes }
        
        let offset: CGFloat, minOffset: CGFloat, maxOffset: CGFloat
        
        if self.scrollDirection == .horizontal {
            offset = collectionView.contentOffset.x + collectionView.adjustedContentInset.left
            minOffset = 0
            maxOffset = max(0, collectionView.contentSize.width - collectionView.bounds.width)
        }
        else {
            offset = collectionView.contentOffset.y + collectionView.adjustedContentInset.top
            minOffset = 0
            maxOffset = max(0, collectionView.contentSize.height - collectionView.bounds.height)
        }
        
        var translation: CGFloat = 0
        
        if offset < minOffset {
            let overScroll = offset

            let index = CGFloat(indexPath.row)
            
            translation = min(0, overScroll * (0.4 - (index / 6)))

        }
        else if offset > maxOffset {
            let overScroll = offset - maxOffset
            
            let itemCount = collectionView.numberOfItems(inSection: 0)
            let reversedIndex = CGFloat(itemCount - (indexPath.row + 1))

            translation = max(0, overScroll * (0.4 - (reversedIndex / 6)))

        }
        
        if self.scrollDirection == .horizontal {
            attributes?.frame.origin.x += translation
        }
        else {
            attributes?.frame.origin.y += translation
        }
        
        return attributes
    }
    
}
