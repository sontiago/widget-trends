import Foundation

/// Парсер RSS-фида Google Trends (https://trends.google.com/trending/rss?geo=XX).
/// Извлекает title, ht:approx_traffic и pubDate каждого item.
public final class TrendsFeedParser: NSObject {
    public enum ParserError: Error, Equatable {
        case malformedXML
    }

    private var items: [TrendItem] = []
    private var currentElement = ""
    private var insideItem = false
    private var currentTitle = ""
    private var currentTraffic = ""
    private var currentPubDate = ""

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    public static func parse(data: Data) throws -> [TrendItem] {
        let delegate = TrendsFeedParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = false
        guard parser.parse() else { throw ParserError.malformedXML }
        return delegate.items
    }
}

extension TrendsFeedParser: XMLParserDelegate {
    public func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentTraffic = ""
            currentPubDate = ""
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "ht:approx_traffic": currentTraffic += string
        case "pubDate": currentPubDate += string
        default: break
        }
    }

    public func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        currentElement = ""
        guard elementName == "item" else { return }
        insideItem = false

        let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let traffic = currentTraffic.trimmingCharacters(in: .whitespacesAndNewlines)
        let pubDate = currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)
        items.append(TrendItem(
            title: title,
            approxTraffic: traffic.isEmpty ? nil : traffic,
            published: TrendsFeedParser.dateFormatter.date(from: pubDate)
        ))
    }
}
