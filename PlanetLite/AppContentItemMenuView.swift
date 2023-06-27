import SwiftUI


struct AppContentItemMenuView: View {
    @Binding var isShowingDeleteConfirmation: Bool
    @Binding var isSharingLink: Bool
    @Binding var sharedLink: String?

    var article: MyArticleModel

    var body: some View {
        VStack {
            Group {
                Button {
                    if let url = article.browserURL {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(url.absoluteString, forType: .string)
                    }
                } label: {
                    Text("Copy Link")
                }
                
                Button {
                    if let url = article.browserURL {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("Open in Browser")
                }
                
                Button {
                    if let url = article.localGatewayURL {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("Open in Local Gateway")
                }

                Divider()
            }
            
            Group {
                Button {
                    if let url = article.browserURL {
                        sharedLink = url.absoluteString
                        isSharingLink = true
                    }
                } label: {
                    Text("Share")
                }

                Divider()

                Button {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text("Delete Post")
                }
            }
        }
    }
}