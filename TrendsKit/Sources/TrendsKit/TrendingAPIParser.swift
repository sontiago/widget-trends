import Foundation

/// Парсер ответа batchexecute (метод i0OFE) страницы «Trending Now».
///
/// Формат: анти-JSON-префикс `)]}'`, затем массив строк-конвертов;
/// в конверте `["wrb.fr","i0OFE","<json>"]` третий элемент — JSON-строка
/// вида `[null, [<тренд>, ...]]`, где тренд — массив:
/// индекс 0 — запрос, 3 — [unix-время старта], 6 — объём поиска,
/// 8 — процент роста.
public enum TrendingAPIParser {
    public enum ParserError: Error, Equatable {
        case notUTF8
        case unexpectedFormat
    }

    public static func parse(data: Data) throws -> [TrendItem] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw ParserError.notUTF8
        }
        guard let start = text.firstIndex(of: "[") else {
            throw ParserError.unexpectedFormat
        }
        guard let envelopes = try? JSONSerialization.jsonObject(
            with: Data(text[start...].utf8)
        ) as? [[Any]] else {
            throw ParserError.unexpectedFormat
        }

        for envelope in envelopes {
            guard envelope.count > 2,
                  envelope.first as? String == "wrb.fr",
                  let payloadString = envelope[2] as? String,
                  let payload = try? JSONSerialization.jsonObject(
                      with: Data(payloadString.utf8)
                  ) as? [Any]
            else { continue }

            guard payload.count > 1 else { return [] }
            guard let entries = payload[1] as? [[Any]] else { return [] }
            return entries.compactMap(parseEntry)
        }
        throw ParserError.unexpectedFormat
    }

    private static func parseEntry(_ entry: [Any]) -> TrendItem? {
        guard let title = entry.first as? String, !title.isEmpty else { return nil }
        let volume = (entry.count > 6 ? entry[6] as? Int : nil) ?? 0
        let growth = entry.count > 8 ? entry[8] as? Int : nil
        let geo = entry.count > 2 ? entry[2] as? String : nil
        var published: Date?
        if entry.count > 3, let timestamps = entry[3] as? [Any],
           let seconds = timestamps.first as? Double {
            published = Date(timeIntervalSince1970: seconds)
        }
        return TrendItem(title: title, volume: volume, growthPercent: growth, published: published, geo: geo)
    }
}
