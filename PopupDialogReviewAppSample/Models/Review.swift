//
//  Review.swift
//  PopupDialogReviewAppSample
//
//  Created by 清水智貴 on 2020/09/25.
//

import UIKit

class Review {
    var user: User
    var reviewText: String
    var createDate: Date
    var reviewRating: Double
    
    init(user: User, reviewText: String, createDate: Date, reviewRating: Double) {
        self.user = user
        self.reviewText = reviewText
        self.createDate = createDate
        self.reviewRating = reviewRating
    }
}
