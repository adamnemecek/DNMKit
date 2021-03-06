//
//  StringExtensions.swift
//  DNMModel
//
//  Created by James Bean on 11/17/15.
//  Copyright © 2015 James Bean. All rights reserved.
//

import Foundation

public extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
    }
}