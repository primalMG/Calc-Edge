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
           .padding(.vertical, 3)
           .frame(width: 150)
           .textFieldStyle(.plain)
           .overlay {
               RoundedRectangle(cornerRadius: 6)
                   .stroke(.white)
           }
    }
}
