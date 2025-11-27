//
//  CityStore.swift
//  SimpleWeatherapp
//
//  Uses Core Data instead of UserDefaults, but keeps
//  the same public API & behavior.
//  Created by Anupam Yadav on 23/11/25.
//

import Foundation
import CoreData

/// Simple persistence layer backed by Core Data.
/// Acts like a tiny database for City objects.
final class CityStore {
    static let shared = CityStore()

    // MARK: - Core Data stack (local to this store)

    private lazy var persistentContainer: NSPersistentContainer = {
        // Name MUST match your .xcdatamodeld file name
        let container = NSPersistentContainer(name: "SimpleWeatherapp")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // For a simple demo app, crash loudly if Core Data fails
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // This is what the rest of the app uses.
    private(set) var cities: [City] = []

    private init() {
        load()
    }

    // MARK: - Load / Save

    private func load() {
        let request: NSFetchRequest<CityEntity> = CityEntity.fetchRequest()
        // Nice to keep the list sorted
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let entities = try context.fetch(request)
            let decoder = JSONDecoder()

            cities = entities.map { entity in
                let name = entity.name ?? ""

                var lastWeather: WeatherResponse? = nil
                if let data = entity.lastWeatherData {
                    lastWeather = try? decoder.decode(WeatherResponse.self, from: data)
                }

                return City(
                    name: name,
                    lastWeather: lastWeather,
                    lastUpdated: entity.lastUpdated
                )
            }
        } catch {
            print("❌ Failed to fetch cities from Core Data:", error)
            cities = []
        }
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("❌ Core Data save error:", error)
        }
    }

    // MARK: - Mutating helpers
    // Behaviour kept same as your old UserDefaults version.

    /// Add a city if not already present (case-insensitive).
    func addCity(named rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        // If already in memory, do nothing (same as before)
        if cities.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return
        }

        // Create a new Core Data entity
        let entity = CityEntity(context: context)
        entity.name = name
        entity.lastUpdated = nil
        entity.lastWeatherData = nil

        saveContext()
        load() // refresh in-memory array
    }

    /// Save latest weather for a city (add if missing) and time-stamp it.
    func updateWeather(for rawName: String, with weather: WeatherResponse) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        // Find existing entity (case-insensitive), or create new one
        let request: NSFetchRequest<CityEntity> = CityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", name)
        request.fetchLimit = 1

        let entity: CityEntity
        if let existing = try? context.fetch(request).first {
            entity = existing
        } else {
            let newEntity = CityEntity(context: context)
            newEntity.name = name
            entity = newEntity
        }

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(weather) {
            entity.lastWeatherData = data
        }
        entity.lastUpdated = Date()

        saveContext()
        load()
    }

    /// Delete a city at a specific index.
    func deleteCity(at index: Int) {
        guard cities.indices.contains(index) else { return }

        let city = cities[index]

        let request: NSFetchRequest<CityEntity> = CityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", city.name)

        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            saveContext()
        } catch {
            print("❌ Failed to delete city from Core Data:", error)
        }

        load()
    }
}
