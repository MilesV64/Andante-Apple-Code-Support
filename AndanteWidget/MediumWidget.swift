//
//  File.swift
//  AndanteWidgetExtension
//
//  Created by Miles Vinson on 9/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import SwiftUI
import WidgetKit


struct MediumWidget: View {
    let model: WidgetContent
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 14, content: {
                Image(model.profileIcon).resizable()
                    .padding(7)
                    .frame(width: 44, height: 44)
                    .background(Color("LightColor"))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 1, content: {
                    Text(model.profileName)
                        .font(.system(size: 16)).fontWeight(.bold)
                    Text("\(model.practiceToday) today")
                        .font(.system(size: 15)).fontWeight(.regular)
                        .foregroundColor(Color("LightText"))
                    
                })
                Spacer()
            })
            
            Spacer()
            
            Divider()
                .background(Color("Separator"))
                .opacity(0.4)
            
            Spacer()
            
            HStack(alignment: .center, spacing: 5, content: {
                ForEach(0..<7) { i in
                    SimpleProgressCircle(
                        progress: CGFloat(model.progress[i]),
                        day: model.weekdays[i],
                        today: i == 6)
                }
            })
        }
        .padding(
            EdgeInsets(top: 17, leading: 15, bottom: 20, trailing: 15))
        .background(Color.foreground)
        .widgetURL(URL(string: "AndanteWidget:\(model.profileID)"))
    }
    
}

struct SimpleProgressCircle: View {
    var progress: CGFloat = 0.66
    var day: String = "M"
    var today: Bool = false
       
    var body: some View {
        ZStack {
            Text(day)
                .font(.system(size: 12))
                .fontWeight(today ? .semibold : .regular)
                .foregroundColor(today ? Color.AndanteOrange : Color.primary)
            
            ProgressCircle(percent: Double(progress*100), ringWidth: 4.5)

        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct Medium_Preview: PreviewProvider {
    static var previews: some View {
        MediumWidget(
            model: WidgetContent(
                profileID: "",
                profileName: "Violin",
                profileIcon: "Piano",
                weekdays: ["M","T","W","T","F","S","S"],
                progress: [0.5,0.2,1,1,0,0.1,1],
                practiceToday: "25 min")
            ).previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
