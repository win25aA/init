import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Плавающая панель радио на активном мониторе, как в World Radio.
Scope {
    PanelWindow {
        id: panel
        visible: GlobalStates.radioOpen && Config.options.sidebar.radio.enable
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        WlrLayershell.namespace: "quickshell:radio"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusiveZone: 0
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        mask: Region { item: radioSurface }
        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panel)
                radioContent.ensureLoaded()
            } else GlobalFocusGrab.removeDismissable(panel)
        }
        Connections { target: GlobalFocusGrab; function onDismissed() { GlobalStates.radioOpen = false } }
        Rectangle {
            id: radioSurface
            anchors.centerIn: parent
            width: Math.min(520, parent.width - 24)
            height: Math.min(740, parent.height - 24)
            radius: Appearance.rounding.windowRounding
            color: Appearance.colors.colLayer0
            border.width: 1; border.color: Appearance.colors.colLayer0Border
            focus: GlobalStates.radioOpen
            Keys.onEscapePressed: GlobalStates.radioOpen = false
            WorldRadio { id: radioContent; anchors.fill: parent }
        }
    }
    IpcHandler {
        target: "radio"
        function toggle(): void { if (Config.options.sidebar.radio.enable) GlobalStates.radioOpen = !GlobalStates.radioOpen }
        function open(): void { if (Config.options.sidebar.radio.enable) GlobalStates.radioOpen = true }
        function close(): void { GlobalStates.radioOpen = false }
    }
    GlobalShortcut { name: "radioToggle"; description: "Toggle world radio"; onPressed: { if (Config.options.sidebar.radio.enable) GlobalStates.radioOpen = !GlobalStates.radioOpen } }
}
