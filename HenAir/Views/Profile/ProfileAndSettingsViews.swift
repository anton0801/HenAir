import SwiftUI

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel
    @State private var showAdd = false
    @State private var appeared = false
    @State private var filter: TaskFilter = .pending

    enum TaskFilter: String, CaseIterable { case pending = "Pending"; case completed = "Completed"; case all = "All" }

    var filtered: [CoopTask] {
        switch filter {
        case .pending: return coopsVM.tasks.filter { !$0.isCompleted }
        case .completed: return coopsVM.tasks.filter { $0.isCompleted }
        case .all: return coopsVM.tasks
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter
                HStack(spacing: 8) {
                    ForEach(TaskFilter.allCases, id: \.self) { f in
                        Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { filter = f } }) {
                            Text(f.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(filter == f ? .white : Color.textSecondary)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(filter == f ? Color.accentGreen : Color.white)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.divider1, lineWidth: 1))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle").font(.system(size: 44)).foregroundColor(Color.divider2)
                        Text(filter == .completed ? "No completed tasks" : "No pending tasks").font(AppFont.display(15)).foregroundColor(Color.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { task in
                                TaskCard(task: task,
                                    onToggle: { coopsVM.toggleTask(task) },
                                    onDelete: { withAnimation { coopsVM.deleteTask(task) } }
                                )
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(coopsVM.tasks.firstIndex(where: { $0.id == task.id }) ?? 0) * 0.06), value: appeared)
                            }
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Color.accentGreen)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddTaskView() }
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true } }
    }
}

struct TaskCard: View {
    let task: CoopTask
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundColor(task.isCompleted ? .accentGreen : .divider2)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title).font(AppFont.display(14)).foregroundColor(Color.textPrimary)
                    .strikethrough(task.isCompleted, color: .textInactive)
                if !task.notes.isEmpty {
                    Text(task.notes).font(AppFont.body(12)).foregroundColor(Color.textSecondary).lineLimit(2)
                }
                HStack(spacing: 8) {
                    Label(task.coopName, systemImage: "house.fill")
                        .font(.system(size: 10, weight: .medium)).foregroundColor(Color.textInactive)
//                    Label(task.dueDate, style: .date)
//                        .font(.system(size: 10)).foregroundColor(Color.textInactive)
                }
            }
            Spacer()
            PriorityBadge(priority: task.priority)
        }
        .padding(14)
        .background(task.isCompleted ? Color(hex: "#F8FFFE") : Color.cardWhite)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(task.isCompleted ? Color.divider1 : task.priority.color.opacity(0.2), lineWidth: 1))
        .appShadow(AppShadow.card)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var coopName = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var saved = false
    @State private var titleError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Task Title").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                            TextField("e.g. Ventilate Layer House", text: $title)
                                .padding(14).background(Color.white).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(titleError ? Color.statusDanger : Color.divider1, lineWidth: 1))
                            if titleError { Text("Enter a title").font(AppFont.body(12)).foregroundColor(.statusDanger) }
                        }
                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes (optional)").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                            TextField("Details...", text: $notes)
                                .padding(14).background(Color.white).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider1, lineWidth: 1))
                        }
                        // Coop
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Coop").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                            if coopsVM.coops.isEmpty {
                                TextField("Coop name", text: $coopName)
                                    .padding(14).background(Color.white).cornerRadius(14)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider1, lineWidth: 1))
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(coopsVM.coops) { c in
                                            Button(action: { withAnimation { coopName = c.name } }) {
                                                Text(c.name).font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(coopName == c.name ? .white : Color.textSecondary)
                                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                                    .background(coopName == c.name ? Color.accentGreen : Color.white)
                                                    .cornerRadius(10)
                                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider1, lineWidth: 1))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Button(action: { withAnimation { priority = p } }) {
                                        Text(p.rawValue).font(.system(size: 13, weight: .bold))
                                            .foregroundColor(priority == p ? .white : p.color)
                                            .padding(.horizontal, 16).padding(.vertical, 10)
                                            .background(priority == p ? p.color : p.color.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        // Due date
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Due Date").font(AppFont.body(13, weight: .semibold)).foregroundColor(Color.textSecondary)
                            DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .padding(14).background(Color.white).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider1, lineWidth: 1))
                        }

                        if saved {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.accentGreen)
                                Text("Task added!").foregroundColor(.accentGreen).font(AppFont.body(14, weight: .semibold))
                            }
                        }

                        PrimaryButton(title: "Add Task", icon: "plus.circle.fill") {
                            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
                                withAnimation { titleError = true }; return
                            }
                            let task = CoopTask(title: title.trimmingCharacters(in: .whitespaces), notes: notes, coopName: coopName.isEmpty ? (coopsVM.coops.first?.name ?? "General") : coopName, isCompleted: false, dueDate: dueDate, priority: priority)
                            coopsVM.addTask(task)
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Color.accentGreen)
                }
            }
        }
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    @EnvironmentObject var coopsVM: CoopsViewModel

    struct ActivityItem: Identifiable {
        let id = UUID()
        let icon: String; let title: String; let time: Date; let color: Color
    }

    var activities: [ActivityItem] {
        var items: [ActivityItem] = []
        for alert in coopsVM.alerts.prefix(5) {
            items.append(ActivityItem(icon: "exclamationmark.triangle.fill", title: "Alert: \(alert.type.rawValue) in \(alert.coopName)", time: alert.timestamp, color: .statusWarning))
        }
        for task in coopsVM.tasks.filter({ $0.isCompleted }).prefix(5) {
            items.append(ActivityItem(icon: "checkmark.circle.fill", title: "Completed: \(task.title)", time: task.dueDate, color: .accentGreen))
        }
        return items.sorted { $0.time > $1.time }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                if activities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock").font(.system(size: 44)).foregroundColor(Color.divider2)
                        Text("No activity yet").font(AppFont.display(15)).foregroundColor(Color.textSecondary)
                    }.padding(.top, 60)
                } else {
                    ForEach(activities) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.icon).font(.system(size: 16)).foregroundColor(item.color)
                                .frame(width: 32, height: 32)
                                .background(item.color.opacity(0.1)).cornerRadius(10)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(AppFont.body(13)).foregroundColor(Color.textPrimary).lineLimit(2)
                                Text(item.time, style: .relative).font(AppFont.body(11)).foregroundColor(Color.textInactive)
                            }
                            Spacer()
                        }
                        .padding(12).cardStyle()
                    }
                }
                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Activity History")
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coopsVM: CoopsViewModel
    @State private var editingName = false
    @State private var editingFarm = false
    @State private var nameInput = ""
    @State private var farmInput = ""
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Profile header
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.accentGreen, Color.accentGreenLight], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                            Text(String(appState.userName.prefix(1)).uppercased())
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Text(appState.userName).font(AppFont.display(20)).foregroundColor(Color.textPrimary)
                        if !appState.farmName.isEmpty {
                            Text(appState.farmName).font(AppFont.body(14)).foregroundColor(Color.textSecondary)
                        }
                    }
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                    // Stats
                    HStack(spacing: 12) {
                        ProfileStat(value: "\(coopsVM.coops.count)", label: "Coops")
                        ProfileStat(value: "\(coopsVM.alerts.count)", label: "Alerts")
                        ProfileStat(value: "\(coopsVM.tasks.filter(\.isCompleted).count)", label: "Tasks Done")
                    }
                    .opacity(appeared ? 1 : 0)

                    // Edit info
                    VStack(spacing: 14) {
                        SectionHeader(title: "Profile Info", icon: "person.fill")

                        // Name
                        ProfileEditRow(
                            label: "Name", value: appState.userName, icon: "person.fill",
                            onEdit: { nameInput = appState.userName; editingName = true }
                        )

                        // Farm name
                        ProfileEditRow(
                            label: "Farm Name", value: appState.farmName.isEmpty ? "Not set" : appState.farmName, icon: "house.fill",
                            onEdit: { farmInput = appState.farmName; editingFarm = true }
                        )

                        // Email
                        if !appState.userEmail.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill").font(.system(size: 14)).foregroundColor(Color.accentBlue).frame(width: 32)
                                Text(appState.userEmail).font(AppFont.body(14)).foregroundColor(Color.textSecondary)
                                Spacer()
                            }
                            .padding(14).cardStyle()
                        }
                    }
                    .opacity(appeared ? 1 : 0)

                    // Navigation links
                    VStack(spacing: 10) {
                        SectionHeader(title: "More", icon: "ellipsis.circle.fill")
                        NavigationLink(destination: ActivityHistoryView()) {
                            DetailNavRow(icon: "clock.fill", title: "Activity History", subtitle: "All recent actions", color: .accentBlue)
                        }
                        NavigationLink(destination: ReportsView()) {
                            DetailNavRow(icon: "chart.bar.fill", title: "Reports", subtitle: "Analytics & comparisons", color: .accentGreenActive)
                        }
                        NavigationLink(destination: SettingsView()) {
                            DetailNavRow(icon: "gearshape.fill", title: "Settings", subtitle: "Theme, units, notifications", color: .textSecondary)
                        }
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Profile")
            .sheet(isPresented: $editingName) {
                QuickEditSheet(title: "Edit Name", placeholder: "Your name", value: $nameInput) {
                    if !nameInput.trimmingCharacters(in: .whitespaces).isEmpty { appState.userName = nameInput.trimmingCharacters(in: .whitespaces) }
                    editingName = false
                }
            }
            .sheet(isPresented: $editingFarm) {
                QuickEditSheet(title: "Farm Name", placeholder: "Your farm name", value: $farmInput) {
                    appState.farmName = farmInput.trimmingCharacters(in: .whitespaces)
                    editingFarm = false
                }
            }
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true } }
    }
}

struct ProfileStat: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(AppFont.display(22)).foregroundColor(Color.textPrimary)
            Text(label).font(.system(size: 11)).foregroundColor(Color.textInactive)
        }
        .frame(maxWidth: .infinity).padding(14).cardStyle()
    }
}

struct ProfileEditRow: View {
    let label: String; let value: String; let icon: String; let onEdit: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color.accentGreen).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 10)).foregroundColor(Color.textInactive)
                Text(value).font(AppFont.body(14)).foregroundColor(Color.textPrimary)
            }
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill").font(.system(size: 20)).foregroundColor(Color.accentGreen.opacity(0.6))
            }
        }
        .padding(14).cardStyle()
    }
}

struct QuickEditSheet: View {
    let title: String; let placeholder: String
    @Binding var value: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField(placeholder, text: $value)
                    .padding(14).background(Color.white).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider1, lineWidth: 1))
                PrimaryButton(title: "Save", action: onSave)
                Spacer()
            }
            .padding(20)
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Color.accentGreen)
                }
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
    @State private var showResetAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Appearance
                SettingsSection(title: "Appearance", icon: "paintbrush.fill") {
                    VStack(spacing: 0) {
                        Text("Theme").font(AppFont.body(13)).foregroundColor(Color.textSecondary).frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 8)
                        HStack(spacing: 8) {
                            ForEach([("Light", "sun.max.fill", "light"), ("Dark", "moon.fill", "dark"), ("System", "circle.lefthalf.filled", "system")], id: \.0) { item in
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        appState.colorSchemeRaw = item.2
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: item.1).font(.system(size: 18)).foregroundColor(appState.colorSchemeRaw == item.2 ? .white : Color.textSecondary)
                                        Text(item.0).font(.system(size: 11, weight: .semibold)).foregroundColor(appState.colorSchemeRaw == item.2 ? .white : Color.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(appState.colorSchemeRaw == item.2 ? Color.accentGreen : Color.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider1, lineWidth: 1))
                                }
                            }
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)

                // Units
                SettingsSection(title: "Measurements", icon: "ruler.fill") {
                    VStack(spacing: 12) {
                        HStack {
                            Label("Temperature Unit", systemImage: "thermometer.medium").font(AppFont.body(14)).foregroundColor(Color.textPrimary)
                            Spacer()
                            Picker("", selection: $appState.temperatureUnitRaw) {
                                ForEach(TemperatureUnit.allCases, id: \.rawValue) { u in
                                    Text(u.rawValue).tag(u.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 100)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)

                // Notifications
                SettingsSection(title: "Notifications", icon: "bell.fill") {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Enable Alerts").font(AppFont.body(14)).foregroundColor(Color.textPrimary)
                                Text("Get notified about climate issues").font(AppFont.body(12)).foregroundColor(Color.textInactive)
                            }
                            Spacer()
                            Toggle("", isOn: $appState.notificationsEnabled)
                                .tint(Color.accentGreen)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)

                // About
                SettingsSection(title: "About", icon: "info.circle.fill") {
                    VStack(spacing: 10) {
                        AboutRow(label: "App Version", value: "1.0.0")
                        AboutRow(label: "Build", value: "2025.1")
                        AboutRow(label: "Minimum iOS", value: "14.0")
                    }
                }
                .opacity(appeared ? 1 : 0)

                // Reset
                Button(action: { showResetAlert = true }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise").foregroundColor(.statusDanger)
                        Text("Reset Onboarding").font(AppFont.body(14, weight: .medium)).foregroundColor(.statusDanger)
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.statusDanger.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.statusDanger.opacity(0.2), lineWidth: 1))
                }
                .alert("Reset Onboarding?", isPresented: $showResetAlert) {
                    Button("Reset", role: .destructive) { appState.hasCompletedOnboarding = false }
                    Button("Cancel", role: .cancel) {}
                }
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 80)
            }
            .padding(16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Settings")
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { appeared = true } }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String; let icon: String; let content: () -> Content
    init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title; self.icon = icon; self.content = content
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, icon: icon)
            content()
                .padding(16)
                .background(Color.cardWhite)
                .cornerRadius(16)
                .appShadow(AppShadow.card)
        }
    }
}

struct AboutRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).font(AppFont.body(14)).foregroundColor(Color.textSecondary)
            Spacer()
            Text(value).font(AppFont.body(14, weight: .semibold)).foregroundColor(Color.textPrimary)
        }
    }
}
