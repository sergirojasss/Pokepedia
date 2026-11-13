//
//  URLSession-Decode.swift
//  Pokepedia
//
//  Created by SergiR on 12/11/2026.
//

import Foundation

/// Errors that may occur when performing network requests.
public enum NetworkError: LocalizedError, Sendable {
    /// The requested URL was invalid or could not be constructed.
    case invalidURL
    /// The response received from the server was not a valid HTTP response.
    case invalidResponse
    /// The server returned an HTTP error status code outside the 200-299 range.
    case httpError(statusCode: Int)
    /// An error occurred while decoding JSON data into the expected Swift model.
    case decodingError(Error)

    /// A localized, human-readable description of the error.
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The requested URL was invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpError(let statusCode):
            return "The server responded with an error (HTTP status code \(statusCode))."
        case .decodingError(let error):
            return "Failed to decode the response data: \(error.localizedDescription)"
        }
    }
}

/// A thread-safe, in-memory cache that stores decoded API responses with a time-to-live (TTL) expiration.
public actor APICache {
    /// The shared singleton instance of `APICache`.
    public static let shared = APICache()

    /// An internal wrapper for cached items containing the value and its expiration date.
    private struct CacheEntry {
        let value: Any
        let expirationDate: Date

        var isExpired: Bool {
            Date() > expirationDate
        }
    }

    /// Internal storage mapping URLs to their cached entries.
    private var storage: [URL: CacheEntry] = [:]

    /// Initializes a new instance of `APICache`.
    public init() {}

    /// Retrieves a cached response for the specified URL if it exists and has not expired.
    /// - Parameters:
    ///   - type: The expected Decodable type of the cached item.
    ///   - url: The URL acting as the cache key.
    /// - Returns: The cached instance of `T`, or `nil` if not found or expired.
    public func get<T>(_ type: T.Type, for url: URL) -> T? {
        guard let entry = storage[url] else { return nil }

        if entry.isExpired {
            storage.removeValue(forKey: url)
            return nil
        }

        return entry.value as? T
    }

    /// Stores a decoded response in the cache with a specified time-to-live (TTL).
    /// - Parameters:
    ///   - value: The value to store in the cache.
    ///   - url: The URL acting as the cache key.
    ///   - ttl: The time-to-live in seconds. Defaults to 300 seconds (5 minutes).
    public func set<T>(_ value: T, for url: URL, ttl: TimeInterval = 300) {
        let expirationDate = Date().addingTimeInterval(ttl)
        storage[url] = CacheEntry(value: value, expirationDate: expirationDate)
    }

    /// Removes a specific cached entry for a given URL.
    /// - Parameter url: The URL whose cached entry should be removed.
    public func remove(for url: URL) {
        storage.removeValue(forKey: url)
    }

    /// Clears all entries from the cache.
    public func clear() {
        storage.removeAll()
    }
}

extension URLSession {
    /// Fetches data asynchronously from a URL and decodes it to a specified `Decodable` type,
    /// utilizing an in-memory cache with time-to-live expiration.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode the response into. Defaults to inferring from context.
    ///   - url: The remote `URL` from which to download data.
    ///   - keyDecodingStrategy: The strategy used to decode keys. Defaults to `.convertFromSnakeCase`.
    ///   - dateDecodingStrategy: The strategy used to decode dates. Defaults to `.deferredToDate`.
    ///   - cacheTTL: The cache duration in seconds. Defaults to 300 seconds (5 minutes). Pass `nil` to bypass caching.
    /// - Returns: A decoded instance of type `T`.
    /// - Throws: `CancellationError` or `URLError.cancelled` if the request was cancelled,
    ///           `NetworkError.invalidResponse` if the response is not an `HTTPURLResponse`,
    ///           `NetworkError.httpError` if the HTTP status code is outside `200...299`,
    ///           `NetworkError.decodingError` if JSON decoding fails,
    ///           or any transport error thrown during the request.
    public func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from url: URL,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        cacheTTL: TimeInterval? = 300
    ) async throws -> T {
        // Check if a non-expired cached response exists for this URL
        if let cacheTTL, let cached = await APICache.shared.get(T.self, for: url) {
            print("⚡️ [Cache Hit (5m)] \(url.absoluteString)")
            return cached
        }

        // Fetch over network
        print("🌐 [API Request] Fetching URL: \(url.absoluteString)")

        let downloadedData: Data
        let response: URLResponse

        do {
            (downloadedData, response) = try await self.data(from: url)
        } catch is CancellationError {
            print("🛑 [API Cancelled] Crida cancel·lada per a la URL: \(url.absoluteString)")
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            print("🛑 [API Cancelled] Crida cancel·lada (URLError.cancelled) per a la URL: \(url.absoluteString)")
            throw urlError
        } catch {
            print("❌ [API Error] Error a la crida \(url.absoluteString): \(error.localizedDescription)")
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy

        let decoded: T
        do {
            decoded = try decoder.decode(T.self, from: downloadedData)
        } catch {
            throw NetworkError.decodingError(error)
        }

        // Store valid response in cache with the requested TTL
        if let cacheTTL {
            await APICache.shared.set(decoded, for: url, ttl: cacheTTL)
        }

        return decoded
    }
}
