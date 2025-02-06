//
//  ChatView.swift
//  N3ON
//
//  Created by liam howe on 7/11/2024.
//

import SwiftUI

struct ChatView: View {    @ObservedObject var viewModel = ChatViewModel()
    
    var body: some View {
        VStack{
            ScrollView{
                VStack(spacing: 8) {
                    ForEach(viewModel.messages.map { ChatMessage(from: $0, currentUserID: viewModel.currentUserID) }) { chatMessage in
                        MessageRow(message: chatMessage)
                    }
                                }
                            }
            .background(Color.black)
            .padding()
            
            //message imput field
            
            HStack {
                TextField("Type a message...", text: $viewModel.messageText)
                                    .padding(10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
            }
           
            .padding()
            background(Color.purple)
            
        }
        .navigationTitle("Group Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
