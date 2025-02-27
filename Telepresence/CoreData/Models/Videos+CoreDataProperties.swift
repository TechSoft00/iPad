//
//  Videos+CoreDataProperties.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/6/25.
//
//

import Foundation
import CoreData


extension Videos {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Videos> {
        return NSFetchRequest<Videos>(entityName: "Videos")
    }

    @NSManaged public var activationPhrase: String?
    @NSManaged public var keyword: String?
    @NSManaged public var showOnHome: Bool
    @NSManaged public var videoURL: String?

}

extension Videos : Identifiable {

}
