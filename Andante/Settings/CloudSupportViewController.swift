//
//  CloudSupportViewController.swift
//  Andante
//
//  Created by Miles Vinson on 3/26/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

class CloudSupportViewController: UIViewController, UITextViewDelegate, MFMailComposeViewControllerDelegate {
    
    private let headerView = ModalViewHeader(title: "")
    private let textView = UITextView()
    
    private var attributedText = NSMutableAttributedString()
    
    private let syncURL = URL(string: "andante://sync")
    private let contactURL = URL(string: "andante://contact")
    
    public weak var settingsViewController: SettingsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Colors.foregroundColor
        
        headerView.showsSeparator = false
        headerView.showsHandle = false
        headerView.showsDoneButton = true
        headerView.doneButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        self.view.addSubview(headerView)
        
        textView.linkTextAttributes = [
            .font: Fonts.medium.withSize(17),
            .foregroundColor: Colors.orange
        ]
        
        textView.backgroundColor = .clear
        textView.alwaysBounceVertical = true
        textView.isEditable = false
        
        textView.delegate = self
        textView.contentInset.bottom = 50
        
        title("iCloud Sync")
        
        body("Andante automatically uses iCloud to back up and sync your Practice Sessions and Journal Entries. Here are some things to try if iCloud Sync isn't working as expected.")
        body("Be sure to note that changes can take a few minutes to show up on other devices, even for small changes.")
        
        header("Check your Andante profiles")
        body("Since Andante does not automatically merge profiles with the same name/icon, you may think things aren't syncing but really you are on a different, identical profile on each device! Go back and tap Change Profile and see if you see a profile you don't expect. You can always go to Profile Settings and merge profiles.")
        
        header("Check your Apple ID")
        body("Make sure you're signed into your devices with the same Apple ID.")
                
        header("Check your iCloud storage and settings")
        body("To check your iCloud storage, go to Settings > Apple ID > iCloud, and ensure that Andante is toggled on and that your iCloud storage isn't full.")
        body("If your storage is full, you'll need to clear some space for Andante. Once you've done so, you can manually toggle a sync (see below).")
            
        header("Manually toggle a sync")
        body("If new sessions/entries are properly syncing but old ones still won't appear on another device,")
        syncLink(" tap here to manually toggle a sync. ")
        body("This will usually resolve issues where iCloud Sync is connected but some data is inconsistent. Be sure to do it on each device, waiting a few minutes in between, as it will only upload data on the current device.")
        body("Note that this method will not delete anything. So if you delete a session on this device, and then later on notice syncing isn't working and toggle a sync, that deletion will not be a part of the sync. You can always manually delete sessions/entries.")
        body("This method will also not sync new/deleted profiles themselves, just the contents (sessions/journal). If a new profile isn't appearing on another device, try creating another profile and then merging the profile that isn't syncing into the newly created profile.")
        
        header("Still having probems?")
        body("Feel free to")
        emailLink(" contact me ")
        body("and I'll get back to you as soon as I can.", newLine: false)
        
        textView.attributedText = self.attributedText
        self.view.addSubview(textView)
    }
    
    private func title(_ text: String) {
        let attributes: [ NSAttributedString.Key : Any ] = [
            .paragraphStyle: paragraphSpacing(12, 0),
            .font: Fonts.bold.withSize(33),
            .foregroundColor: Colors.text
        ]
        attributedText.append(NSAttributedString(string: text, attributes: attributes))
    }
    
    private func header(_ text: String) {
        let attributes: [ NSAttributedString.Key : Any ] = [
            .paragraphStyle: paragraphSpacing(12, 16),
            .font: Fonts.bold.withSize(21),
            .foregroundColor: Colors.text
        ]
        attributedText.append(NSAttributedString(string: "\n" + text, attributes: attributes))
    }
    
    private func body(_ text: String, newLine: Bool = true) {
        let attributes: [ NSAttributedString.Key : Any ] = [
            .paragraphStyle: paragraphSpacing(8, lineSpacing: 6),
            .font: Fonts.regular.withSize(17),
            .foregroundColor: Colors.text.withAlphaComponent(0.95)
        ]
        
        attributedText.append(NSAttributedString(string: (newLine ? "\n" : "") + text, attributes: attributes))
    }
    
    private func syncLink(_ text: String) {
        let attributes: [ NSAttributedString.Key : Any ] = [
            .paragraphStyle: paragraphSpacing(8, lineSpacing: 6),
            .font: Fonts.medium.withSize(17),
            .foregroundColor: Colors.orange,
            .link: syncURL?.absoluteString
        ]
        
        attributedText.append(NSAttributedString(string: text, attributes: attributes))
    }
    
    private func emailLink(_ text: String) {
        let attributes: [ NSAttributedString.Key : Any ] = [
            .paragraphStyle: paragraphSpacing(8, lineSpacing: 6),
            .font: Fonts.medium.withSize(17),
            .foregroundColor: Colors.orange,
            .link: contactURL?.absoluteString
        ]
        
        attributedText.append(NSAttributedString(string: text, attributes: attributes))
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if URL == contactURL {
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.setToRecipients(["contact@andante.app"])
                mail.setSubject("Andante")
                mail.mailComposeDelegate = self
                self.present(mail, animated: true, completion: nil)

            }
        }
        else if URL == syncURL {
            toggleSync()
        }
        
        return false
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    private func paragraphSpacing(
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let (_, margin) = view.constrainedWidth(600)
        
        let height = headerView.sizeThatFits(self.view.bounds.size).height
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
        
        textView.frame = CGRect(
            from: CGPoint(x: 0, y: headerView.frame.maxY),
            to: CGPoint(x: view.bounds.maxX, y: view.bounds.maxY))
        
        textView.textContainerInset.left = margin - 5
        textView.textContainerInset.right = margin - 5
        
    }
    
    private func toggleSync() {
        
        let alert = CenterLoadingViewController(style: .indefinite)
        self.present(alert, animated: false, completion: nil)
        
        let context = DataManager.backgroundContext
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        User.shared.isForcingSync = true
        
        DispatchQueue.global(qos: .background).async {
            
            Thread.sleep(forTimeInterval: 1)
            
            context.performAndWait {
                do {
                    let profiles = try context.fetch(request)
                    for profile in profiles {
                        
                        if let sessions = profile.sessions as? Set<CDSession> {
                            for session in sessions {
                                let duplicate = session.duplicate(context: context)
                                context.delete(session)
                                profile.addToSessions(duplicate)
                            }
                        }
                        
                        if let folders = profile.journalFolders as? Set<CDJournalFolder> {
                            for folder in folders {
                                let duplicate = folder.duplicate(context: context)
                                context.delete(folder)
                                profile.addToJournalFolders(duplicate)
                            }
                        }
                        
                    }
                    
                    try context.save()
                    
                }
                catch {
                    print(error)
                }
            }
            
            DispatchQueue.main.async {
                alert.close(success: true)
                User.shared.isForcingSync = false
            }
            
        }
        
    }
    
}
