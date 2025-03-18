import Foundation

// Struct to decode the response for business search
struct YelpSearchResponse: Decodable {
    let businesses: [YelpBusinessDetails] // Renamed YelpBusiness to avoid conflict
}

// Struct for business details
struct YelpBusinessDetails: Decodable { // Renamed YelpBusiness to avoid conflict
    let id: String // This is the Yelp ID
    let name: String
    let location: YelpLocation
    let hours: [YelpBusinessHours]?
}

// Struct for business hours
struct YelpBusinessHours: Decodable {
    let open: [YelpOpenHours]?
}

// Struct for open hours
struct YelpOpenHours: Decodable {
    let start: String
    let end: String
}

// Struct for the location (this could include address components)
struct YelpLocation: Decodable {
    let address1: String
    let city: String
    let state: String
    let country: String
    let zip_code: String
}

// Fetch Yelp Business ID
func fetchYelpID(libraryName: String, libraryLocation: String, completion: @escaping (String?) -> Void) {
    let apiKey = "PMM5T6NVtKTbqQC4hT8Y_eFgZEPyrn0Hmxil2XjmaFgxndOqvbXZjRJdKAjvWd782kap6Xz4iOwtU8sNc9ym2wBz5VchzXJqt7N1q4XgfxxtGP3wX1bju0b19vTYZ3Yx"
    
    // Yelp Business Search API URL
    let urlString = "https://api.yelp.com/v3/businesses/search?term=\(libraryName)&location=\(libraryLocation)"
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    // Perform the network request to get the business data
    URLSession.shared.dataTask(with: request) { data, _, error in
        if let error = error {
            print("Error fetching Yelp data: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("No data received")
            completion(nil)
            return
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(YelpSearchResponse.self, from: data)
            // Assume the first result is the correct library
            if let firstBusiness = response.businesses.first {
                completion(firstBusiness.id) // Return the Yelp ID
            } else {
                completion(nil)
            }
        } catch {
            print("Error decoding Yelp data: \(error.localizedDescription)")
            completion(nil)
        }
    }.resume()
}
