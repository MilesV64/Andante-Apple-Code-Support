//
//  CDJournalEntry+CoreDataClass.swift
//  
//
//  Created by Miles Vinson on 2/7/21.
//
//

import Foundation
import UIKit
import CoreData

@objc(CDJournalEntry)
public class CDJournalEntry: NSManagedObject {
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        if self.creationDate == nil {
            self.creationDate = Date()
        }
    }
    
    public func duplicate(context: NSManagedObjectContext? = nil) -> CDJournalEntry {
        let newEntry = CDJournalEntry(context: context ?? DataManager.context)
        if context != nil {
            DataManager.obtainPermanentID(for: newEntry)
        }
        newEntry.creationDate = self.creationDate
        newEntry.editDate = self.editDate
        newEntry.index = self.index
        newEntry.string = self.string
        
        for att in self.attributes as? Set<CDStringAttributes> ?? [] {
            let newAtt = CDStringAttributes(context: context ?? DataManager.context)
            newAtt.value = att.value
            newAtt.location = att.location
            newAtt.length = att.length
            newEntry.addToAttributes(newAtt)
        }
        
        return newEntry
    }
    
    public func saveAttrText(_ text: NSAttributedString) {
        removeFromAttributes(attributes ?? [])
        
        let textRange = NSRange(location: 0, length: text.length)
        text.enumerateAttributes(in: textRange) {
            (att, range, stop) in
            
            if let font = att[.font] as? UIFont {
                if font == EntryTextAttributes.TitleAttributes[.font] as? UIFont {
                    let attribute = CDStringAttributes(context: DataManager.context)
                    attribute.location = Int64(range.location)
                    attribute.length = Int64(range.length)
                    attribute.value = 0
                    addToAttributes(attribute)
                }
                else  if font == EntryTextAttributes.HeaderAttributes[.font] as? UIFont {
                    let attribute = CDStringAttributes(context: DataManager.context)
                    attribute.location = Int64(range.location)
                    attribute.length = Int64(range.length)
                    attribute.value = 1
                    addToAttributes(attribute)
                }
            }
            
        }

        self.string = text.string
        self.editDate = Date()
    }
    
    func attributedText(layout: JournalViewController.EntryLayout? = nil) -> NSAttributedString {
        if self.string == nil || self.string == "" {
            return NSAttributedString()
        }
        
        let att = NSMutableAttributedString(
            string: self.string ?? "",
            attributes: EntryTextAttributes.textAttributes(for: 2, layout: layout))
        
        if let attributes = self.attributes as? Set<CDStringAttributes> {
           
            for attribute in attributes {
                
                let range = NSRange(location: Int(attribute.location), length: Int(attribute.length))
                if range.location + (range.length-1) < att.string.count {
                    att.addAttributes(
                        EntryTextAttributes.textAttributes(
                            for: Int(attribute.value), layout: layout),
                        range: range)
                }
                
            }
        }
        
        return att
        
    }

}

extension NSAttributedString.Key {
    static let customStyle = NSAttributedString.Key("CustomStyle")
}

class EntryTextAttributes {
    
    private static var shared = EntryTextAttributes()
        
    public static var TitleAttributes: [NSAttributedString.Key : Any] {
        return [
            .customStyle : 0,
            .font : Fonts.bold.withSize(24),
            .paragraphStyle : EntryTextAttributes.paragraphSpacing(12, 14),
            .foregroundColor : Colors.text
        ]
    }
    
    public static var HeaderAttributes: [NSAttributedString.Key : Any] {
        return [
            .customStyle : 1,
            .font : Fonts.semibold.withSize(21),
            .paragraphStyle : EntryTextAttributes.paragraphSpacing(10, 10),
            .foregroundColor : Colors.text
        ]
    }
    
    public static var BodyAttributes: [NSAttributedString.Key : Any] {
        return [
            .customStyle : 2,
            .font : Fonts.regular.withSize(17),
            .paragraphStyle : EntryTextAttributes.paragraphSpacing(8, lineSpacing: 4),
            .foregroundColor : Colors.text.withAlphaComponent(0.95)
        ]
    }
    
    
    private static var SmallTitleAttributes: [NSAttributedString.Key : Any] {
        return [
            .font : Fonts.bold.withSize(17),
            .paragraphStyle : EntryTextAttributes.paragraphSpacing(8, 8),
            .foregroundColor : Colors.text
        ]
    }
    
    private static var SmallHeaderAttributes: [NSAttributedString.Key : Any] {
        return [
            .font : Fonts.semibold.withSize(16),
            .paragraphStyle : EntryTextAttributes.paragraphSpacing(6, 8),
            .foregroundColor : Colors.text
        ]
    }
    
    private static var SmallBodyAttributes: [NSAttributedString.Key : Any] {
        return [
            .font : Fonts.regular.withSize(15),
            .paragraphStyle : EntryTextAttributes.paragraphSpacing(6),
            .foregroundColor : Colors.text.withAlphaComponent(0.92)
        ]
    }
    
    private static var ExtraSmallTitleAttributes: [NSAttributedString.Key : Any] {
        return [
            .font : Fonts.bold.withSize(17),
            .paragraphStyle : EntryTextAttributes.paragraphSpacing(6, 8),
            .foregroundColor : Colors.text
        ]
    }
    
    private static var ExtraSmallHeaderAttributes: [NSAttributedString.Key : Any] {
        return [
            .font : Fonts.semibold.withSize(14),
            .paragraphStyle : EntryTextAttributes.paragraphSpacing(4, 6),
            .foregroundColor : Colors.text
        ]
    }
    
    private static var ExtraSmallBodyAttributes: [NSAttributedString.Key : Any] {
        return [
            .font : Fonts.regular.withSize(12),
            .paragraphStyle : EntryTextAttributes.paragraphSpacing(4),
            .foregroundColor : Colors.text.withAlphaComponent(0.92)
        ]
    }
    
    static func textAttributes(
        for value: Int,
        layout: JournalViewController.EntryLayout? = nil
    ) -> [NSAttributedString.Key : Any] {
        
        if let layout = layout {
            switch value {
            case 0: return layout == .list ? SmallTitleAttributes : ExtraSmallTitleAttributes
            case 1: return layout == .list ? SmallHeaderAttributes : ExtraSmallHeaderAttributes
            default: return layout == .list ? SmallBodyAttributes : ExtraSmallBodyAttributes
            }
        }
        else {
            switch value {
            case 0: return TitleAttributes
            case 1: return HeaderAttributes
            default: return BodyAttributes
            }
        }
        
    }
    
    private static func paragraphSpacing(
        _ spacing: CGFloat, _ before: CGFloat? = nil, lineSpacing: CGFloat? = nil
    ) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = spacing
        if let before = before {
            style.paragraphSpacingBefore = before
        }
        if let lineSpacing = lineSpacing {
            style.lineSpacing = lineSpacing
        }
        return style
    }
    
}
