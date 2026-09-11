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
            PageHeader(title: isEditing ? "Edit DNS Server" : "New DNS Server", icon: isEditing ? "pencil" : "plus", onClose: onClose)
            
            Divider().overlay(DS.Colors.border)
            
            ThinScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    nameField
                    dnsFields
                    colorPicker
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.lg)
                .padding(.bottom, 72)
            }
            .background(DS.Colors.bg)
        }
        .frame(width: DS.Layout.pageWidth, height: DS.Layout.pageHeight)
        .background(DS.Colors.bg)
        .overlay(alignment: .bottom) {
            footer
        }
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
            
            HStack(spacing: DS.Spacing.sm) {
                ForEach(DNSColor.allCases, id: \.self) { color in
                    ZStack {
                        Circle()
                            .fill(color.gradient)
                            .frame(width: 20, height: 20)
                            .shadow(color: selectedColor == color ? color.color.opacity(0.5) : .clear, radius: 5)
                        
                        if selectedColor == color {
                            Circle()
                                .stroke(.white, lineWidth: 1.5)
                                .frame(width: 20, height: 20)
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
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
        FooterIsland {
            HStack(spacing: DS.Spacing.sm) {
                if isEditing, let server = editing, !server.isPreset {
                    PillButton(title: "Delete", icon: "trash", color: DS.Colors.danger) {
                        showDeleteConfirm = true
                    }
                }
                
                Spacer()
                
                PillButton(
                    title: isEditing ? "Save Changes" : "Add Server",
                    icon: isEditing ? "checkmark" : "plus",
                    color: DS.Colors.accent,
                    isDefault: true
                ) {
                    save()
                }
                .opacity(isValid ? 1 : 0.4)
                .disabled(!isValid)
            }
        }
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
