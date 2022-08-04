import SwiftUI

struct PostPage: View {
    @State var hole: THHole?
    @State var floors: [THFloor] = []
    @State var endReached = false
    @State var bookmarked: Bool
    @State var holeId: Int
    var targetFloorId: Int? = nil
    
    init(hole: THHole) {
        self._hole = State(initialValue: hole)
        self._bookmarked = State(initialValue: treeholeDataModel.user?.favorites.contains(hole.id) ?? false)
        self._holeId = State(initialValue: hole.id)
    }
    
    init(holeId: Int) { // init from hole ID, load info afterwards
        self._hole = State(initialValue: nil)
        self._bookmarked = State(initialValue: treeholeDataModel.user?.favorites.contains(holeId) ?? false)
        self._holeId = State(initialValue: holeId)
    }
    
    init(targetFloorId: Int) { // init from floor ID, scroll to that floor
        self.targetFloorId = targetFloorId
        self._hole = State(initialValue: nil)
        self._holeId = State(initialValue: 0)
        self._bookmarked = State(initialValue: false)
    }
    
    @State var showReplyPage = false
    
    func loadMoreFloors() async {
        do {
            let newFloors = try await networks.loadFloors(holeId: holeId, startFloor: floors.count)
            floors.append(contentsOf: newFloors)
            endReached = newFloors.isEmpty
        } catch {
            print("DANXI-DEBUG: load floors failed")
        }
    }
    
    func loadHoleInfo() async {
        do {
            self.hole = try await networks.loadHoleById(holeId: holeId)
        } catch {
            print("DANXI-DEBUG: load hole info failed")
        }
    }
    
    func loadToTargetFloor() async {
        guard let targetFloorId = targetFloorId else {
            return
        }
        
        do {
            let targetFloor = try await networks.loadFloorById(floorId: targetFloorId)
            
            self.holeId = targetFloor.holeId
            self.hole = try await networks.loadHoleById(holeId: holeId)
            
            var newFloors: [THFloor] = []
            repeat {
                newFloors = try await networks.loadFloors(holeId: holeId, startFloor: floors.count)
                self.floors.append(contentsOf: newFloors)
                if newFloors.contains(targetFloor) {
                    break
                }
            } while !newFloors.isEmpty
        } catch {
            print("DANXI-DEBUG: load to target floor failed")
        }
    }
    
    func toggleBookmark() async {
        do {
            let bookmarks = try await networks.toggleFavorites(holeId: holeId, add: !bookmarked)
            treeholeDataModel.updateBookmarks(bookmarks: bookmarks)
            bookmarked = bookmarks.contains(holeId)
        } catch {
            print("DANXI-DEBUG: toggle bookmark failed")
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    ForEach(floors) { floor in
                        FloorView(floor: floor, isPoster: floor.posterName == hole?.firstFloor.posterName ?? "")
                            .task {
                                if floor == floors.last {
                                    await loadMoreFloors()
                                }
                            }
                            .id(floor.id)
                    }
                } header: {
                    if let hole = hole {
                        TagListNavigation(tags: hole.tags)
                    }
                } footer: {
                    if !endReached {
                        HStack() {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .task {
                            // initial load
                            if self.hole == nil {
                                if targetFloorId != nil { // init from target floor
                                    await loadToTargetFloor()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // hack to give a time redraw
                                        proxy.scrollTo(targetFloorId, anchor: .top) // FIXME: can't `withAnimation`, will cause Fatal error: List update took more than 1 layout cycle to converge
                                    }
                                } else { // initial load hole
                                    await loadHoleInfo()
                                }
                            }
                            
                            if floors.isEmpty { // all relevant data present, ready to load floors
                                await loadMoreFloors()
                            }
                        }
                    }
                }
                .textCase(nil)
            }
            .listStyle(.grouped)
            .navigationTitle("#\(String(holeId))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbar
                }
            }
        }
    }
    
    var toolbar: some View {
        Group {
            if hole != nil {
                Button(action: { showReplyPage = true }) {
                    Image(systemName: "arrowshape.turn.up.left")
                }
                .sheet(isPresented: $showReplyPage) {
                    ReplyPage(
                        holeId: holeId,
                        showReplyPage: $showReplyPage,
                        content: "")
                }
                
                Button {
                    Task { @MainActor in
                        await toggleBookmark()
                    }
                } label: {
                    Image(systemName: bookmarked ? "bookmark.fill" : "bookmark")
                }
            }
        }
    }
}

struct PostPage_Previews: PreviewProvider {
    static var previews: some View {
        PostPage(hole: PreviewDecode.decodeObj(name: "hole")!)
    }
}

