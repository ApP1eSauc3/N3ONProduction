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
                    .background(Color.purple.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth:250, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4){
                    Text(message.sender)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(message.content)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .frame(maxWidth: 250, alignment: .leading)
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
