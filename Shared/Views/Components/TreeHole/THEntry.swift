import SwiftUI

struct THEntry: View {
    @Environment(\.colorScheme) var colorScheme
    
    let hole: OTHole
    
    var body: some View {
        VStack(alignment: .leading) {
            if let tagList = hole.tags {
                TagList(tags: tagList)
            }
            Text(hole.firstFloor.content)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
        }
        .padding()
#if !os(watchOS)
        .background(Color(uiColor: colorScheme == .dark ? .secondarySystemBackground : .systemBackground))
#endif
        .cornerRadius(13)
        .padding(.horizontal)
        .padding(.vertical, 5.0)
    }
}

struct THEntry_Previews: PreviewProvider {
    static let tag = OTTag(id: 1, temperature: 1, name: "Tag")
    
    static let floor = OTFloor(
        id: 1234567, holeId: 123456,
        updateTime: "2022-04-14T08:23:12.761042+08:00",
        createTime: "2022-04-14T08:23:12.761042+08:00",
        like: 12,
        liked: true,
        storey: 5,
        content: """
        Hello, **Dear** readers!
        
        We can make text *italic*, ***bold italic***, or ~~striked through~~.
        
        You can even create [links](https://www.twitter.com/twannl) that actually work.
        
        Or use `Monospace` to mimic `Text("inline code")`.
        
        """,
        poster: "Dax")
    
    static let hole = OTHole(
        id: 123456,
        divisionId: 1,
        view: 15,
        reply: 13,
        updateTime: "2022-04-14T08:23:12.761042+08:00",
        createTime: "2022-04-14T08:23:12.761042+08:00",
        tags: Array(repeating: tag, count: 5),
        firstFloor: floor, lastFloor: floor, floors: Array(repeating: floor, count: 10))
    
    static var previews: some View {
        Group {
            THEntry(hole: hole)
            THEntry(hole: hole)
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
