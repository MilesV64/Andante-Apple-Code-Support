//
//  SmallWidget.swift
//  AndanteWidgetExtension
//
//  Created by Miles Vinson on 9/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import SwiftUI
import WidgetKit

struct SmallWidget: View {
    let model: WidgetContent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2, content: {
                Text(model.profileName)
                    .font(.system(size: 16)).fontWeight(.bold)
                Text("\(model.practiceToday) today")
                    .font(.system(size: 15)).fontWeight(.regular)
                    .foregroundColor(Color("LightText"))
                Spacer()
                ZStack {
                    Image(model.profileIcon).resizable()
                        .padding(13)
                    ProgressCircle(percent: model.progress.last!*100, ringWidth: 6)
                }
                .frame(width: 60, height: 60)
            })
            Spacer()
        }
        .padding(
            EdgeInsets(top: 17, leading: 15, bottom: 15, trailing: 15))
        .background(Color.foreground)
        .widgetURL(URL(string: "AndanteWidget:\(model.profileID)"))
    }
    
    
}

struct Preview: PreviewProvider {
    static var previews: some View {
        SmallWidget(
            model: WidgetContent(
                profileID: "",
                profileName: "Violin",
                profileIcon: "Piano",
                weekdays: ["M","T","W","T","F","S","S"],
                progress: [0.5,0.2,1,1,0,0.1,1],
                practiceToday: "25 min")
            ).previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
