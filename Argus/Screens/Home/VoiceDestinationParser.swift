import Foundation

/// A recognized destination and an optional starting-point change. No GPS or microphone work happens here.
struct VoiceDestinationParser {
    enum Origin {
        case currentLocation
        case place(CampusPlace)
    }

    let destination: CampusPlace
    let origin: Origin?

    /// Accepts place names and phrases such as “from Boyd Hall to the library.”
    static func parse(_ transcript: String) -> Result<VoiceDestinationParser, InputError> {
        let words = transcript.lowercased()
        var destinationWords = words
        var originWords: String?

        if let from = words.range(of: "from ") {
            let afterFrom = String(words[from.upperBound...])
            if let to = afterFrom.range(of: " to ") {
                originWords = String(afterFrom[..<to.lowerBound])
                destinationWords = String(afterFrom[to.upperBound...])
            } else {
                originWords = afterFrom
                destinationWords = String(words[..<from.lowerBound])
            }
        }

        let destinations = matchedPlaces(in: destinationWords)
        guard destinations.count == 1, let destination = destinations.first else {
            return .failure(destinations.count > 1 ? .ambiguousDestination : .unknownDestination)
        }

        var origin: Origin?
        if let originWords {
            let origins = matchedPlaces(in: originWords)
            if origins.count == 1, let place = origins.first {
                origin = .place(place)
            } else if originWords.contains("current location")
                || originWords.trimmingCharacters(in: .whitespacesAndNewlines) == "here"
            {
                origin = .currentLocation
            } else {
                return .failure(.unknownOrigin)
            }
        }
        return .success(VoiceDestinationParser(destination: destination, origin: origin))
    }

    // Match whole words so unrelated words containing “boyd” or “library” do not resolve to a place.
    private static func matchedPlaces(in words: String) -> [CampusPlace] {
        let tokens = Set(words.split { !$0.isLetter }.map(String.init))
        return CampusPlace.places.filter { tokens.contains($0.id == "library" ? "library" : "boyd") }
    }

    enum InputError: Error {
        case ambiguousDestination, unknownDestination, unknownOrigin

        var message: String {
            switch self {
            case .ambiguousDestination:
                return "Choose one destination: TSU Library or Boyd Hall."
            case .unknownDestination:
                return "Try saying TSU Library or Boyd Hall, or choose from the list."
            case .unknownOrigin:
                return
                    "I couldn’t identify the starting point. Try ‘from Boyd Hall to the library,’ or use the Location menu."
            }
        }
    }
}
