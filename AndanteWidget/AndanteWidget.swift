//
//  AndanteWidget.swift
//  AndanteWidget
//
//  Created by Miles Vinson on 9/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

extension FileManager {
  static func sharedContainerURL() -> URL {
    return FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.milesvinson.Andante.contents"
    )!
  }
}

extension Color {
    static let AndanteOrange = Color("AccentColor")
    static let foreground = Color("Foreground")
    
}

let EmptyContent = WidgetContent(
    profileID: "",
    profileName: "",
    profileIcon: "",
    weekdays: ["","","","","","",""],
    progress: [0,0,0,0,0,0,0],
    practiceToday: ""
)

struct Provider: IntentTimelineProvider {
    public typealias Entry = WidgetContent
    
    func readContents(_ profile: WidgetProfile?) -> [WidgetContent] {
        let contents = WidgetFileManager.getContents()
        
        var content: WidgetContent
        
        if let profile = profile {
            content = contents.first { widgetContent -> Bool in
                return widgetContent.profileID == profile.identifier
            } ?? EmptyContent
        }
        else {
            content = contents.first ?? EmptyContent
        }
        
        let contentDay = Day(date: content.date)
        let today = Day(date: Date())
        
        if contentDay != today {
            var newProgress: [Double] = []
            var newWeekdays: [String] = []
            
            var progressDays: [ Day : Double ] = [:]
            for (i, progress) in content.progress.enumerated() {
                progressDays[contentDay.addingDays(-6 + i)] = progress
            }
            
            for i in 0...6 {
                let day = today.addingDays(-6 + i)
                newProgress.append(progressDays[day] ?? 0)
                newWeekdays.append(day.weekdayString())
                
            }
            
            return [WidgetContent(
                date: content.date,
                profileID: content.profileID,
                profileName: content.profileName,
                profileIcon: content.profileIcon,
                weekdays: newWeekdays,
                progress: newProgress,
                practiceToday: "0 min"
            )]
        }
        else {
            return [content]
        }
        
    }
    
    func placeholder(in context: Context) -> WidgetContent {
        return WidgetContent(
            profileID: "",
            profileName: "----",
            profileIcon: "",
            weekdays: ["","","","","","",""],
            progress: [0,0,0,0,0,0,0],
            practiceToday: "--"
        )
    }

    func getSnapshot(
        for configuration: ChooseProfileIntent,
        in context: Context,
        completion: @escaping (WidgetContent) -> ()
    ) {
        let content = readContents(configuration.profile)
        completion(content.first!)
    }

    func getTimeline(
        for configuration: ChooseProfileIntent,
        in context: Context,
        completion: @escaping (Timeline<Entry>) -> ()
    ) {
       
        let entries = readContents(configuration.profile)
        
        let today = Date()
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = calendar.component(.day, from: today)
        components.month = calendar.component(.month, from: today)
        components.year = calendar.component(.year, from: today)
        components.minute = calendar.component(.minute, from: today) + 1
        components.hour = calendar.component(.hour, from: today)
        let tomorrow = calendar.date(from: components)!
        
        let timeline = Timeline(entries: entries, policy: .after(tomorrow))
        completion(timeline)
    }
}

struct WidgetFork: View {
    @Environment(\.widgetFamily) var widgetFamily

    let model: WidgetContent
    
    var body: some View {
        if widgetFamily == .systemSmall {
            SmallWidget(model: model)
        } else {
            MediumWidget(model: model)
        }
    }
}

@main
struct AndanteWidget: Widget {
    
    let kind: String = "AndanteWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ChooseProfileIntent.self,
            provider: Provider()
        ) { entry in
            
            WidgetFork(model: entry)
                        
        }
        .configurationDisplayName("Daily Goal")
        .description("See how much you practiced every day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension Day {
    func weekdayString() -> String {
        let weekday = Calendar.current.component(.weekday, from: self.date)
        switch weekday {
        case 1: return "S"
        case 2: return "M"
        case 3: return "T"
        case 4: return "W"
        case 5: return "T"
        case 6: return "F"
        default: return "S"
        }
    }
}
