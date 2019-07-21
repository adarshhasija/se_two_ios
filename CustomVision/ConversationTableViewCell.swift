//
//  ConversationTableViewCell.swift
//  Suno
//
//  Created by Adarsh Hasija on 09/04/19.
//  Copyright © 2019 Adam Behringer. All rights reserved.
//

import Foundation
import UIKit

class ConversationTableViewCell : UITableViewCell {
    
    var delegate : ChatBubbleDelegate!
    var indexPath : IndexPath!
    
    @IBAction func chatBubbleTapped(_ sender: UIView) {
        self.delegate?.conversationBubbleTapped(at: indexPath)
    }
    
    
    @IBOutlet weak var textViewLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageOriginLabel: UILabel! //Which device sent the message
}

protocol ChatBubbleDelegate {
    func conversationBubbleTapped(at indexPath:IndexPath)
}
