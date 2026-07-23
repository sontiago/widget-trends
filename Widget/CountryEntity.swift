import AppIntents
import TrendsKit

/// Страна в конфигурации виджета: параметр-массив даёт штатный UI
/// «добавить/удалить из списка» в меню «Редактировать виджет».
struct CountryEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Country")
    static let defaultQuery = CountryEntityQuery()

    let id: String

    var country: TrendsCountry { TrendsCountry(code: id) }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(country.flag) \(country.name)")
    }

    static func from(_ country: TrendsCountry) -> CountryEntity {
        CountryEntity(id: country.code)
    }
}

struct CountryEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CountryEntity] {
        identifiers.map(CountryEntity.init)
    }

    func suggestedEntities() async throws -> [CountryEntity] {
        TrendsCountry.supported.map(CountryEntity.from)
    }

    func defaultResult() async -> [CountryEntity]? {
        [CountryEntity.from(.fallback)]
    }
}
