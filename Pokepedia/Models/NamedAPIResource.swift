//
//  NamedAPIResource.swift
//  Pokepedia
//

import Foundation

/// A reusable reference resource from PokéAPI containing a resource name and its detail URL.
public struct NamedAPIResource: Codable, Identifiable, Hashable, Sendable {
    /// The name of the referenced resource.
    public let name: String

    /// The URL pointing to the detailed data for this resource.
    public let url: String

    /// Computes the unique integer identifier from the resource's URL.
    public var id: Int {
        let trimmed = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let lastComponent = trimmed.split(separator: "/").last,
              let parsedID = Int(lastComponent) else {
            return 0
        }
        return parsedID
    }

    /// Initializes a NamedAPIResource.
    public init(name: String, url: String) {
        self.name = name
        self.url = url
    }
}
