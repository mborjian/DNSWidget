import AppKit
import SwiftUI

struct AddEditDNSView: View {
    @EnvironmentObject var storage: StorageService
    
    let editing: DNSServer?
    var onClose: () -> Void
    
    @State private var name: String = ""
    @State private var primaryDNS: String = ""
    @State private var secondaryDNS: String = ""
    @State private var selectedColor: DNSColor = .blue
    @State private var showError: String?
    @State private var showDeleteConfirm = false
    @FocusState private var isNameFocused: Bool
    
    init(editing: DNSServer? = nil, onClose: @escaping () -> Void = {}) {
        self.editing = editing
        self.onClose = onClose
    }
    
    var isEditing: Bool { editing != nil }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider().overlay(DS.Colors.border)
            
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    nameField
                    dnsFields
                    colorPicker
                }
                .padding(DS.Spacing.lg)
            }
            .background(DS.Colors.bg)
            
            Divider().overlay(DS.Colors.border)
            
            footer
        }
        .frame(width: 360, height: 520)
        .background(DS.Colors.bg)
        .onExitCommand {
            onClose()
        }
        .alert("Delete DNS Server?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let server = editing {
                    storage.delete(server)
                    onClose()
                }
            }
        } message: {
            Text("This will permanently remove this DNS server.")
        }
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async {
                (NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }))?.makeKey()
                isNameFocused = true
            }
            
            if let server = editing {
                name = server.name
                primaryDNS = server.primaryDNS
                secondaryDNS = server.secondaryDNS
                selectedColor = server.color
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(DS.Colors.accentGradient)
                    .frame(width: 32, height: 32)
                Image(systemName: isEditing ? "pencil.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isEditing ? "Edit DNS Server" : "New DNS Server")
                    .font(DS.Font.title)
                    .foregroundStyle(DS.Colors.text)
                Text(isEditing ? "Update server configuration" : "Add a custom DNS resolver")
                    .font(DS.Font.caption)
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            
            Spacer()
            
            Button(action: { onClose() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(DS.Colors.card))
            }
            .buttonStyle(.plain)
        }
        .padding(DS.Spacing.lg)
        .background(DS.Colors.bgElevated)
    }
    
    // MARK: - Name Field
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Label("Server Name", systemImage: "tag")
                .font(DS.Font.caption)
                .foregroundStyle(DS.Colors.textTertiary)
            
            TextField("e.g. My Custom DNS", text: $name)
                .textFieldStyle(.plain)
                .font(DS.Font.body)
                .focused($isNameFocused)
                .padding(DS.Spacing.sm + 2)
                .background(DS.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                        .stroke(DS.Colors.border, lineWidth: 0.5)
                )
        }
    }
    
    // MARK: - DNS Fields
    
    private var dnsFields: some View {
        VStack(spacing: DS.Spacing.sm) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack {
                    Label("Primary DNS", systemImage: "globe")
                        .font(DS.Font.caption)
                        .foregroundStyle(DS.Colors.textTertiary)
                    if !primaryDNS.isEmpty {
                        if IPAddressFormatter.validate(primaryDNS) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                TextField("8.8.8.8", text: $primaryDNS)
                    .textFieldStyle(.plain)
                    .font(DS.Font.mono)
                    .padding(DS.Spacing.sm + 2)
                    .background(DS.Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                            .stroke(DS.Colors.border, lineWidth: 0.5)
                    )
            }
            
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                HStack {
                    Label("Secondary DNS", systemImage: "globe.badge.chevronleft")
                        .font(DS.Font.caption)
                        .foregroundStyle(DS.Colors.textTertiary)
                    Text("Optional")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(DS.Colors.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(DS.Colors.card)
                        .clipShape(Capsule())
                    if !secondaryDNS.isEmpty {
                        if IPAddressFormatter.validate(secondaryDNS) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                TextField("8.8.4.4", text: $secondaryDNS)
                    .textFieldStyle(.plain)
                    .font(DS.Font.mono)
                    .padding(DS.Spacing.sm + 2)
                    .background(DS.Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                            .stroke(DS.Colors.border, lineWidth: 0.5)
                    )
            }
        }
    }
    
    // MARK: - Color Picker
    
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label("Color", systemImage: "paintpalette")
                .font(DS.Font.caption)
                .foregroundStyle(DS.Colors.textTertiary)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.sm), count: 4),
                spacing: DS.Spacing.sm
            ) {
                ForEach(DNSColor.allCases, id: \.self) { color in
                    ZStack {
                        Circle()
                            .fill(color.gradient)
                            .frame(width: 32, height: 32)
                            .shadow(color: selectedColor == color ? color.color.opacity(0.5) : .clear, radius: 6)
                        
                        if selectedColor == color {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedColor = color
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            if isEditing, let server = editing, !server.isPreset {
                Button(action: { showDeleteConfirm = true }) {
                    HStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                        Text("Delete")
                            .font(DS.Font.caption)
                    }
                    .foregroundStyle(DS.Colors.danger)
                    .padding(.horizontal, DS.Spacing.sm + 2)
                    .padding(.vertical, DS.Spacing.xs + 2)
                    .background(DS.Colors.danger.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            Button("Cancel") { onClose() }
                .keyboardShortcut(.cancelAction)
                .font(DS.Font.body)
                .foregroundStyle(DS.Colors.textSecondary)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(DS.Colors.card)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            
            Button(action: save) {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: isEditing ? "checkmark" : "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text(isEditing ? "Save Changes" : "Add Server")
                        .font(DS.Font.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isValid ? DS.Colors.accentGradient : LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                )
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.plain)
            .disabled(!isValid)
        }
        .padding(DS.Spacing.lg)
        .background(DS.Colors.bgElevated)
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        IPAddressFormatter.validate(primaryDNS) &&
        (secondaryDNS.isEmpty || IPAddressFormatter.validate(secondaryDNS))
    }
    
    // MARK: - Actions
    
    private func save() {
        guard isValid else {
            showError = "Please enter a valid name and IP addresses"
            return
        }
        
        if let existing = editing {
            var updated = existing
            updated.name = name.trimmingCharacters(in: .whitespaces)
            updated.primaryDNS = primaryDNS.trimmingCharacters(in: .whitespaces)
            updated.secondaryDNS = secondaryDNS.trimmingCharacters(in: .whitespaces)
            updated.color = selectedColor
            storage.update(updated)
        } else {
            let server = DNSServer(
                name: name.trimmingCharacters(in: .whitespaces),
                primaryDNS: primaryDNS.trimmingCharacters(in: .whitespaces),
                secondaryDNS: secondaryDNS.trimmingCharacters(in: .whitespaces),
                color: selectedColor
            )
            storage.add(server)
        }
        
        onClose()
    }
}
