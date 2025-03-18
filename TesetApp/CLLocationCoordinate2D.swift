//
//  CLLocationCoordinate2D.swift
//  TesetApp
//
//  Created by Katie Pell on 3/18/25.
//

import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
