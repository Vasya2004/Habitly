import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var profiles: [Profile]

    @State private var isAuthorized = false
    @State private var didCheckAuthorization = false
    @State private var showDeleteConfirmation = false
    @State private var showPrivacyPolicy = false
    @State private var exportFileURL: URL?
    @State private var exportFileName = ""
    @State private var showImporter = false
    @State private var importMessage: String?

    private static let avatarEmojis = ["🙂", "😎", "🦊", "🐼", "🐨", "🦁", "🐸", "🌸", "🚀", "⭐️", "🌱", "🔥"]

    private var profile: Profile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Настройки")
                    .font(Typography.largeTitle)
                    .fitsWidth()
                    .foregroundStyle(Theme.primaryText(for: scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let profile {
                    profileSection(profile)
                    appearanceSection(profile)
                    weekSection(profile)
                    notificationsSection
                    hapticsSection(profile)
                    dataSection
                    aboutSection
                }

                #if DEBUG
                debugSection
                #endif
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .task { await refreshAuthorizationStatus() }
        .sheet(isPresented: $showPrivacyPolicy) { PrivacyPolicyView() }
        .alert("Удалить все данные?", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить всё", role: .destructive, action: deleteAllData)
        } message: {
            Text("Все привычки и история их выполнения будут удалены без возможности восстановления.")
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
        .alert("Импорт", isPresented: Binding(get: { importMessage != nil }, set: { if !$0 { importMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage ?? "")
        }
    }

    // MARK: - Профиль

    private func profileSection(_ profile: Profile) -> some View {
        section(title: "Профиль") {
            VStack(spacing: Spacing.sm) {
                TextField("Ваше имя", text: Binding(
                    get: { profile.name },
                    set: { profile.name = $0; save() }
                ))
                .textFieldStyle(.plain)
                .padding(Spacing.sm)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.control))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(Self.avatarEmojis, id: \.self) { emoji in
                            Button {
                                Haptics.shared.selectionChanged()
                                profile.avatarEmoji = emoji
                                save()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 22))
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle().fill(profile.avatarEmoji == emoji ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.gray.opacity(0.12)))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    // MARK: - Внешний вид

    private func appearanceSection(_ profile: Profile) -> some View {
        section(title: "Внешний вид") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Picker("Тема", selection: Binding(
                    get: { profile.appearance },
                    set: { profile.appearance = $0; save() }
                )) {
                    ForEach(AppearanceMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                Text("Иконка приложения")
                    .font(Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText(for: scheme))
                AppIconPickerRow()
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    // MARK: - Неделя

    private func weekSection(_ profile: Profile) -> some View {
        section(title: "Начало недели") {
            Picker("Начало недели", selection: Binding(
                get: { profile.weekStartsMonday },
                set: { profile.weekStartsMonday = $0; save() }
            )) {
                Text("Понедельник").tag(true)
                Text("Воскресенье").tag(false)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Уведомления

    private var notificationsSection: some View {
        section(title: "Уведомления") {
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle().fill(Theme.brandGradient.opacity(0.18))
                        Image(systemName: isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                            .foregroundStyle(Theme.brandGradient)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isAuthorized ? String(localized: "Напоминания включены") : String(localized: "Напоминания выключены"))
                            .font(Typography.headline)
                            .foregroundStyle(Theme.primaryText(for: scheme))
                        Text(isAuthorized
                             ? String(localized: "Привычки с напоминаниями будут присылать уведомления по расписанию")
                             : String(localized: "Разрешите уведомления, чтобы не забывать о привычках"))
                            .font(Typography.caption)
                            .foregroundStyle(Theme.secondaryText(for: scheme))
                    }
                    Spacer()
                }
                .padding(Spacing.md)
                .cardStyle()

                if !isAuthorized && didCheckAuthorization {
                    CapsuleButton(title: "Включить уведомления", systemImage: "bell.fill") {
                        Task {
                            _ = await NotificationService.shared.requestAuthorization()
                            await refreshAuthorizationStatus()
                            await NotificationService.shared.rescheduleAll(habits: habits)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Haptics

    private func hapticsSection(_ profile: Profile) -> some View {
        section(title: "Тактильная отдача") {
            Toggle(isOn: Binding(
                get: { profile.hapticsEnabled },
                set: { profile.hapticsEnabled = $0; Haptics.shared.isEnabled = $0; save() }
            )) {
                Text("Haptics при отметках и переходах")
                    .foregroundStyle(Theme.primaryText(for: scheme))
            }
            .tint(Color(hex: "9B5CFF"))
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    // MARK: - Данные

    private var dataSection: some View {
        section(title: "Данные") {
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    exportButton(title: "Экспорт CSV", filename: "habitly-export.csv") {
                        DataExportService.exportCSV(habits: habits)
                    }
                    exportButton(title: "Экспорт JSON", filename: "habitly-export.json") {
                        DataExportService.exportJSON(habits: habits)
                    }
                }

                CapsuleButton(title: "Импорт из JSON", systemImage: "square.and.arrow.down", isProminent: false) {
                    showImporter = true
                }

                CapsuleButton(title: "Удалить все данные", systemImage: "trash", isProminent: false) {
                    showDeleteConfirmation = true
                }
                .tint(.red)
            }
        }
    }

    private func exportButton(title: String, filename: String, content: @escaping () -> String) -> some View {
        Group {
            if let exportFileURL, exportFileName == filename {
                ShareLink(item: exportFileURL) {
                    exportLabel(title)
                }
                .simultaneousGesture(TapGesture().onEnded { self.exportFileURL = nil })
            } else {
                Button {
                    exportFileURL = DataExportService.writeTempFile(contents: content(), filename: filename)
                    exportFileName = filename
                } label: {
                    exportLabel(title)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func exportLabel(_ title: String) -> some View {
        Text(title)
            .font(Typography.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .foregroundStyle(Theme.primaryText(for: scheme))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.control))
    }

    // MARK: - О приложении

    private var aboutSection: some View {
        section(title: "О приложении") {
            VStack(spacing: Spacing.xs) {
                HStack {
                    Text("Версия")
                        .foregroundStyle(Theme.secondaryText(for: scheme))
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                        .foregroundStyle(Theme.primaryText(for: scheme))
                }
                Button {
                    showPrivacyPolicy = true
                } label: {
                    HStack {
                        Text("Политика конфиденциальности")
                            .foregroundStyle(Theme.primaryText(for: scheme))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.secondaryText(for: scheme))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }

    #if DEBUG
    private var debugSection: some View {
        section(title: "Отладка") {
            CapsuleButton(title: "Добавить тестовые привычки", systemImage: "sparkles", isProminent: false) {
                SampleDataSeeder.seed(into: modelContext)
            }
        }
    }
    #endif

    private func section<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(Typography.subheadline)
                .foregroundStyle(Theme.secondaryText(for: scheme))
            content()
        }
    }

    private func save() {
        try? modelContext.save()
    }

    private func refreshAuthorizationStatus() async {
        isAuthorized = await NotificationService.shared.isAuthorized
        didCheckAuthorization = true
    }

    private func handleImport(_ picked: Result<URL, Error>) {
        do {
            let url = try picked.get()
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let result = try DataImportService.importJSON(Data(contentsOf: url), into: modelContext)
            WidgetRefreshService.reloadAll()
            Task { await NotificationService.shared.rescheduleAll(habits: habits) }
            Haptics.shared.success()
            importMessage = result.isEmpty
                ? String(localized: "Новых данных в файле не нашлось — всё уже есть в приложении.")
                : String(localized: "Добавлено привычек: \(result.habitsAdded), дополнено: \(result.habitsMerged), новых записей истории: \(result.logsAdded).")
        } catch {
            Haptics.shared.warning()
            importMessage = (error as? LocalizedError)?.errorDescription ?? String(localized: "Не удалось прочитать файл: \(error.localizedDescription)")
        }
    }

    private func deleteAllData() {
        for habit in habits { modelContext.delete(habit) }
        if let profile {
            profile.xp = 0
            profile.level = 1
            profile.streakFreezesLeft = 2
        }
        try? modelContext.save()
        Haptics.shared.warning()
    }
}

private struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Habitly хранит все данные о ваших привычках локально на устройстве. Мы не передаём их на серверы и не используем для рекламы или аналитики третьих сторон.")
                    Text("Уведомления формируются и планируются полностью на устройстве. Доступ к отправке уведомлений запрашивается только с вашего явного согласия.")
                    Text("Вы можете в любой момент экспортировать свои данные (CSV или JSON) или полностью удалить их в разделе «Данные».")
                }
                .font(Typography.body)
                .padding(Spacing.md)
            }
            .navigationTitle("Конфиденциальность")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, HabitLog.self, Profile.self, Achievement.self], inMemory: true)
}
