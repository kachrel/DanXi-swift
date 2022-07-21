import SwiftUI

struct THHoleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let hole: THHole
    
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
                .transition(.slide)
        }
    }
}

struct THEntry_Previews: PreviewProvider {
    static let tag = THTag(id: 1, temperature: 1, name: "Tag")
    
    static let floor = THFloor(
        id: 1234567, holeId: 123456,
        iso8601UpdateTime: "2022-04-14T08:23:12.761042+08:00",
        iso8601CreateTime: "2022-04-14T08:23:12.761042+08:00",
        updateTime: Date.now, createTime: Date.now,
        like: 12,
        liked: true,
        storey: 5,
        content: """
        Hello, **Dear** readers!
        
        We can make text *italic*, ***bold italic***, or ~~striked through~~.
        
        You can even create [links](https://www.twitter.com/twannl) that actually work.
        
        Or use `Monospace` to mimic `Text("inline code")`.
        
        """,
        posterName: "Dax")
    
    static let hole = THHole(
        id: 123456,
        divisionId: 1,
        view: 15,
        reply: 13,
        iso8601UpdateTime: "2022-04-14T08:23:12.761042+08:00",
        iso8601CreateTime: "2022-04-14T08:23:12.761042+08:00",
        updateTime: Date.now, createTime: Date.now,
        tags: Array(repeating: tag, count: 5),
        firstFloor: floor, lastFloor: floor, floors: Array(repeating: floor, count: 10))
    
    static var previews: some View {
        Group {
            THHoleView(hole: hole)
            THHoleView(hole: hole)
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
