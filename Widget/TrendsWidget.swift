import WidgetKit
import SwiftUI

struct TrendsWidget: Widget {
    let kind = "TrendsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: RegionConfigurationIntent.self,
            provider: TrendsTimelineProvider()
        ) { entry in
            TrendsWidgetView(entry: entry)
        }
        .configurationDisplayName("Search Trends")
        .description("Live Google search trends for your countries.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct TrendsWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrendsWidget()
    }
}
