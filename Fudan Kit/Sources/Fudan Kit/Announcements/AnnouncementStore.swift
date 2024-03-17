import Foundation

/// App-wide cache for announcement. Cache is invalidated between app launches.
public actor AnnouncementStore {
    var page = 1
    var finished = false
    var announcements: [Announcement] = []
    
    /// Fetch more announcements and return the entire list
    public func getCachedAnnouncements() async throws -> [Announcement] {
        if finished { return self.announcements }
        
        let announcementDelta = try await AnnouncementAPI.getAnnouncement(page: page)
        page += 1
        self.announcements += announcementDelta
        finished = announcementDelta.isEmpty
        return self.announcements
    }
    
    /// Clear cache and load annoucements from server
    public func getRefreshedAnnouncements() async throws -> [Announcement] {
        page = 1
        finished = false
        self.announcements = try await AnnouncementAPI.getAnnouncement(page: page)
        finished = self.announcements.isEmpty
        return self.announcements
    }
}
