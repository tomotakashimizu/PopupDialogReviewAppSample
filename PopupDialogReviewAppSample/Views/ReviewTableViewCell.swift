//
//  ReviewTableViewCell.swift
//  PopupDialogReviewAppSample
//
//  Created by 清水智貴 on 2020/09/25.
//

import UIKit
import Cosmos

class ReviewTableViewCell: UITableViewCell {
    
    @IBOutlet var userIdLabel: UILabel!
    @IBOutlet var reviewLabel: UILabel!
    @IBOutlet var reviewCosmosView: CosmosView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
