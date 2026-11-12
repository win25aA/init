import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Общая pill-кнопка вкладок, использует цвета и ripple самой оболочки ii.
RippleButton {
    id: root
    property string symbol: ""
    property bool iconOnly: false
    implicitHeight: 36
    implicitWidth: iconOnly ? 36 : Math.max(64, buttonRow.implicitWidth + 24)
    buttonRadius: Appearance.rounding.full
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.colors.colLayer2Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    contentItem: RowLayout {
        id: buttonRow
        spacing: 6
        MaterialSymbol {
            visible: root.symbol.length > 0
            text: root.symbol
            fill: root.toggled ? 1 : 0
            iconSize: 19
            color: root.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
            Layout.alignment: Qt.AlignVCenter
        }
        StyledText {
            visible: !root.iconOnly && root.text.length > 0
            text: root.text
            color: root.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
            Layout.alignment: Qt.AlignVCenter
        }
    }
    StyledToolTip { text: root.text; extraVisibleCondition: root.iconOnly && root.text.length > 0 }
}
