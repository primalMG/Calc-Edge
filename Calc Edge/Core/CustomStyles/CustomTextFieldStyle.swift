//
//  CustomTextFieldStyle.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 13/01/2026.
//

import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    
   func _body(configuration: TextField<Self._Label>) -> some View {
       configuration
           .padding(4)
           .frame(minWidth: 100)
           .textFieldStyle(.plain)
           .overlay {
               RoundedRectangle(cornerRadius: 10)
                   .stroke(.primary)
           }
    }
}

struct JournalCustomTextFieldStyle: TextFieldStyle {
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(4)
            .frame(maxWidth: .infinity)
            .textFieldStyle(.plain)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.primary)
            }
    }
}
