//
//  EventService.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import Foundation

struct EventService {
    static func fetchUpcomingEvents(
        near location: CLLocation,
        radius: Double
    ) -> AnyPublisher<[Event], Error> {
        Future { promise in
            let query = """
            query EventsByLocation($lat: Float!, $long: Float!, $radius: Float!) {
              eventsByLocation(latitude: $lat, longitude: $long, radius: $radius) {
                items {
                  id name description eventDate
                  venue { id name latitude longitude }
                  ticketTypes { id name price }
                }
              }
            }
            """
            
            Amplify.API.query(
                request: .init(
                    document: query,
                    variables: [
                        "lat": location.coordinate.latitude,
                        "long": location.coordinate.longitude,
                        "radius": radius
                    ],
                    responseType: EventsResponse.self
                )
            ) { result in
                switch result {
                case .success(let response):
                    promise(.success(response.events))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

private struct EventsResponse: Decodable {
    let events: [Event]
}
