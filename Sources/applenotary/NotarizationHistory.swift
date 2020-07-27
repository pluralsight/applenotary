//
//  NotarizationHistory.swift
//  applenotary
//
//  Created by Adam Findley on 7/31/19.
//
import Foundation

struct NotarizationHistory: Decodable {

    private enum CodingKeys: String, CodingKey {
        case firstPage = "first-page"
        case items = "items"
        case nextPage = "next-page"
        case lastPage = "last-page"
    }

    var firstPage: Int?
    var items: [NotarizationInfo]?
    var nextPage: Int?
    var lastPage: Int?
}
