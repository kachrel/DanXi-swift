import DanXiKit
import SwiftUI
import ViewUtils

public struct ForumSettingsView: View {
    @ObservedObject private var profileStore = ProfileStore.shared
    
    private var sections: [ForumSettingsSection] {
        if profileStore.isAdmin {
            ForumSettingsSection.adminList
        } else {
            ForumSettingsSection.normalList
        }
    }
    
    public init() {}
    
    public var body: some View {
        Section {
            ForEach(sections) { section in
                DetailLink(value: section) {
                    section.label.navigationStyle()
                }
            }
        } header: {
            Text("Forum", bundle: .module)
        }
    }
}

public enum ForumSettingsSection: Identifiable, Hashable, CaseIterable {
    case notification
    case foldedContent
    case blockedContent
    case advancedSettings
    case adminSection
    
    static let normalList: [ForumSettingsSection] = [.notification, .foldedContent, .blockedContent]
    static let adminList: [ForumSettingsSection] = [.notification, .foldedContent, .blockedContent, .adminSection]
    
    public var id: ForumSettingsSection {
        self
    }
    
    public var label: some View {
        switch self {
        case .notification:
            Label(String(localized: "Push Notification Settings", bundle: .module), systemImage: "app.badge")
        case .foldedContent:
            Label(String(localized: "Folded Content", bundle: .module), systemImage: "eye.square")
        case .blockedContent:
            Label(String(localized: "Blocked Content", bundle: .module), systemImage: "hand.raised.app")
        case .advancedSettings:
            Label(String(localized: "Advanced Settings", bundle: .module), systemImage: "slider.horizontal.2.square")
        case .adminSection:
            Label(String(localized: "Key Admin Section", bundle: .module), systemImage: "key.card.fill")
        }
    }
    
    @ViewBuilder
    public var destination: some View {
        switch self {
        case .notification:
            NotificationSettingWrapper()
        case .foldedContent:
            FoldedContentSettings()
        case .blockedContent:
            BlockedContent()
        case .advancedSettings:
            AdvancedSettings()
        case .adminSection:
            KeyAdminSection()
        }
    }
}

fileprivate struct FoldedContentSettings: View {
    @ObservedObject private var settings = ForumSettings.shared
    
    var body: some View {
        Form {
            Picker(selection: $settings.foldedContent) {
                Text("Show", bundle: .module).tag(ForumSettings.SensitiveContentSetting.show)
                Text("Fold", bundle: .module).tag(ForumSettings.SensitiveContentSetting.fold)
                Text("Hide", bundle: .module).tag(ForumSettings.SensitiveContentSetting.hide)
            }
            .pickerStyle(.inline)
            .onChange(of: settings.foldedContent) { foldedContent in
                Task {
                    try await _ = ForumAPI.updateUserSettings(showFoldedConfiguration: String(describing: foldedContent))
                }
            }
        }
        .navigationTitle(String(localized: "Folded Content", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct BlockedContent: View {
    @ObservedObject private var settings = ForumSettings.shared
    
    var body: some View {
        Form {
            Section {
                TagEditor($settings.blockedTags)
            } header: {
                Text("Blocked Tags", bundle: .module)
            }
            
            Section {
                ForEach(settings.blockedHoles, id: \.self) { holeId in
                    Text(verbatim: "#\(String(holeId))")
                        .swipeActions {
                            Button(role: .destructive) {
                                if let idx = settings.blockedHoles.firstIndex(of: holeId) {
                                    withAnimation {
                                        _ = settings.blockedHoles.remove(at: idx)
                                    }
                                }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                }
                
                if settings.blockedHoles.isEmpty {
                    Text("You haven't blocked any holes. You can a block hole by pressing and holding it and select \"Block Hole\" in the menu.", bundle: .module)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } header: {
                Text("Blocked Holes", bundle: .module)
            }
            
            if !settings.hiddenMyHoles.isEmpty {
                Section {
                    Button {
                        withAnimation {
                            settings.hiddenMyHoles = []
                        }
                    } label: {
                        Text("Restore Hidden Posts", bundle: .module)
                    }
                } footer: {
                    Text("If you have hidden your posts in \"My Posts\" Page, you may restore them.", bundle: .module)
                }
            }
            
            if !settings.hiddenMyReplies.isEmpty {
                Section {
                    Button {
                        withAnimation {
                            settings.hiddenMyReplies = []
                        }
                    } label: {
                        Text("Restore Hidden Replies", bundle: .module)
                    }
                } footer: {
                    Text("If you have hidden your replies in \"My Reply\" Page, you may restore them.", bundle: .module)
                }
            }
        }
        .navigationTitle(String(localized: "Blocked Content", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingWrapper: View {
    var body: some View {
        AsyncContentView {
            async let profile = ForumAPI.getProfile()
            async let authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            return try await (profile, authorizationStatus)
        } content: { (profile: Profile, authorizationStatus: UNAuthorizationStatus) in
            NotificationSetting(profile, authorizationStatus)
        }
        .navigationTitle(String(localized: "Push Notification Settings", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct NotificationSetting: View {
    private let authorizationStatus: UNAuthorizationStatus
    private let notificationSettingsURL: URL?
    @State private var favorite: Bool
    @State private var mention: Bool
    @State private var report: Bool
    @State private var showAlert = false
    
    init(_ user: Profile, _ authorizationStatus: UNAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
        let notify = user.notificationConfiguration
        self._favorite = State(initialValue: notify.contains("favorite"))
        self._mention = State(initialValue: notify.contains("mention"))
        self._report = State(initialValue: notify.contains("report"))
        
        if let url = URL(string: UIApplication.openNotificationSettingsURLString), UIApplication.shared.canOpenURL(url) {
            self.notificationSettingsURL = url
        } else {
            self.notificationSettingsURL = nil
        }
    }
    
    private func updateConfig() async {
        do {
            var notifyConfig: [String] = []
            if favorite {
                notifyConfig.append("favorite")
            }
            if mention {
                notifyConfig.append("mention")
            }
            if report {
                notifyConfig.append("report")
            }
            let newProfile = try await ForumAPI.updateUserSettings(notificationConfiguration: notifyConfig)
            await MainActor.run {
                ProfileStore.shared.profile = newProfile
            }
        } catch {
            showAlert = true
        }
    }
    
    var body: some View {
        List {
            if authorizationStatus != .authorized {
                Section {
                    Button {
                        if let url = notificationSettingsURL {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label(String(localized: "Push Notification Not Authorized", bundle: .module), systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            
            Section {
                Toggle(isOn: $mention) {
                    Text("Notify when my post is mentioned", bundle: .module)
                }
                .onChange(of: mention) { _ in
                    Task { await updateConfig() }
                }
                
                Toggle(isOn: $favorite) {
                    Text("Notify when favorited hole gets reply", bundle: .module)
                }
                .onChange(of: favorite) { _ in
                    Task { await updateConfig() }
                }
                
                Toggle(isOn: $report) {
                    Text("Notify when my report is dealt", bundle: .module)
                }
                .onChange(of: report) { _ in
                    Task { await updateConfig() }
                }
            }
            .disabled(authorizationStatus != .authorized)
            
            if let url = notificationSettingsURL {
                Section {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Text("Open Notification Settings", bundle: .module)
                    }
                }
            }
        }
        .alert(String(localized: "Update Notification Config Failed", bundle: .module), isPresented: $showAlert) {}
        .labelStyle(.titleOnly)
    }
}

#Preview {
    List {
        ForumSettingsView()
    }
}
