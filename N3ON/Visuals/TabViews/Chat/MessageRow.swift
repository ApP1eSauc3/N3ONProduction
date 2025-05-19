//
//  MessageRow.swift
//  N3ON
//
//  Created by liam howe on 7/11/2024.
//

import SwiftUI


struct MessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack{
            if message.isCurrentUser{
                Spacer()
                Text(message.content)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color("neonPurpleBackground"), Color("dullPurple")],
                            
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15.0)
                    .shadow(color: Color("neonPurpleBackground"), radius: 5, x: 0, y: 2)
                
            } else {
                VStack(alignment: .leading, spacing: 4){
                    Text(message.sender)
                        .font(.caption)
                        .foregroundColor(Color("neonPurpleBackground"))

                    Text(message.content)
                        .padding()
                        .background(Color("darkGray"))
                        .foregroundColor(.white)
                        .cornerRadius(15.0)
                }
            Spacer() //pushes messages to the left for other users
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        MessageRow(message: ChatMessage(
            sender: "User1",
            content: "Hello, this is a test message.",
            timestamp: Date(),
            isCurrentUser: false
        ))
    }
}
