import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property var stations: []
    property string status: ""
    property string view: "search"
    property bool filtersOpen: false
    property int requestId: 0

    function search() {
        root.view = "search"
        root.status = Translation.tr("Loading…")
        const serial = ++root.requestId
        let u = Config.options.sidebar.radio.apiServer + "/json/stations/search?hidebroken=true&order=clickcount&reverse=true&limit=" + Math.max(1, Math.min(100, Config.options.sidebar.radio.limit))
        if (query.text.trim()) u += "&name=" + encodeURIComponent(query.text.trim())
        if (Config.options.sidebar.radio.countryCode) u += "&countrycode=" + encodeURIComponent(Config.options.sidebar.radio.countryCode)
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || serial !== root.requestId) return
            if (xhr.status !== 200) { root.status = Translation.tr("Request failed"); return }
            try {
                root.stations = JSON.parse(xhr.responseText)
                root.status = root.stations.length ? "" : Translation.tr("No results")
            } catch(e) { root.status = Translation.tr("Request failed") }
        }
        xhr.open("GET", u); xhr.send()
    }
    function isFavorite(item) {
        return Array.from(Config.options.sidebar.radio.favorites).some(x => x.stationuuid === item.stationuuid)
    }
    function favorite(item) {
        let list = Array.from(Config.options.sidebar.radio.favorites)
        let i = list.findIndex(x => x.stationuuid === item.stationuuid)
        if (i >= 0) list.splice(i, 1); else list.unshift(item)
        Config.options.sidebar.radio.favorites = list
    }
    function changeView(next) { root.view = next; root.status = "" }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText { text: Translation.tr("Radio"); font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.DemiBold }
                StyledText { text: Translation.tr("Stations from around the world"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            PluginButton { symbol: "tune"; iconOnly: true; text: Translation.tr("Filters"); toggled: root.filtersOpen; onClicked: root.filtersOpen = !root.filtersOpen }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ToolbarTextField {
                id: query
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                placeholderText: Translation.tr("Search radio stations")
                selectByMouse: true
                onAccepted: root.search()
            }
            PluginButton { symbol: "search"; iconOnly: true; text: Translation.tr("Search"); onClicked: root.search() }
        }
        RowLayout {
            visible: root.filtersOpen
            Layout.fillWidth: true
            StyledText { text: Translation.tr("Country code"); color: Appearance.colors.colSubtext }
            ToolbarTextField {
                Layout.fillWidth: true; Layout.preferredHeight: 36
                placeholderText: Translation.tr("All countries (e.g. RU)")
                text: Config.options.sidebar.radio.countryCode
                maximumLength: 2
                onEditingFinished: Config.options.sidebar.radio.countryCode = text.trim().toUpperCase()
                onAccepted: { Config.options.sidebar.radio.countryCode = text.trim().toUpperCase(); root.search() }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            PluginButton { text: Translation.tr("Search"); symbol: "travel_explore"; toggled: root.view === "search"; Layout.fillWidth: true; onClicked: root.changeView("search") }
            PluginButton { text: Translation.tr("Favorites"); symbol: "favorite"; toggled: root.view === "favorites"; Layout.fillWidth: true; onClicked: root.changeView("favorites") }
            PluginButton { text: Translation.tr("Recent"); symbol: "history"; toggled: root.view === "recent"; Layout.fillWidth: true; onClicked: root.changeView("recent") }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: nowColumn.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colSecondaryContainer
            ColumnLayout {
                id: nowColumn
                anchors.fill: parent; anchors.margins: 10; spacing: 4
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    MaterialSymbol { text: RadioPlayer.playing ? "graphic_eq" : "radio"; fill: RadioPlayer.playing ? 1 : 0; iconSize: 22; color: Appearance.colors.colOnSecondaryContainer }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        StyledText { text: RadioPlayer.playing ? Translation.tr("Playing") : Translation.tr("Radio is off"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnSecondaryContainer }
                        StyledText { text: RadioPlayer.station?.name ?? Translation.tr("Select a station"); Layout.fillWidth: true; elide: Text.ElideRight; font.weight: Font.DemiBold; color: Appearance.colors.colOnSecondaryContainer }
                    }
                    PluginButton { visible: RadioPlayer.playing; iconOnly: true; symbol: "stop"; text: Translation.tr("Stop"); onClicked: RadioPlayer.stop() }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    MaterialSymbol { text: "volume_up"; iconSize: 18; color: Appearance.colors.colOnSecondaryContainer }
                    StyledSlider {
                        Layout.fillWidth: true
                        from: 0; to: 100; stepSize: 1
                        value: Config.options.sidebar.radio.volume
                        onMoved: RadioPlayer.setVolume(value)
                    }
                    StyledText { text: Math.round(Config.options.sidebar.radio.volume) + "%"; color: Appearance.colors.colOnSecondaryContainer; font.pixelSize: Appearance.font.pixelSize.smaller }
                }
            }
        }

        StyledText { visible: root.status.length > 0; Layout.fillWidth: true; text: root.status; color: Appearance.colors.colSubtext; elide: Text.ElideRight }
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            StyledText {
                anchors.centerIn: parent
                visible: stationList.count === 0 && root.status.length === 0
                width: parent.width - 24
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                color: Appearance.colors.colSubtext
                text: root.view === "favorites" ? Translation.tr("No favorite stations yet") : root.view === "recent" ? Translation.tr("Recently played stations appear here") : Translation.tr("Search by station name or browse popular stations")
            }
            StyledListView {
                id: stationList
                anchors.fill: parent; clip: true; spacing: 6
                model: root.view === "favorites" ? Config.options.sidebar.radio.favorites : root.view === "recent" ? Config.options.sidebar.radio.recent : root.stations
                delegate: Rectangle {
                    id: stationCard
                    required property var modelData
                    width: ListView.view.width; height: 66
                    radius: Appearance.rounding.normal; color: Appearance.colors.colLayer2
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 5; spacing: 6
                        RippleButton {
                            id: stationButton
                            Layout.fillWidth: true; Layout.fillHeight: true
                            buttonRadius: Appearance.rounding.small
                            colBackground: "transparent"; colBackgroundHover: Appearance.colors.colLayer2Hover
                            onClicked: RadioPlayer.play(stationCard.modelData)
                            contentItem: RowLayout {
                                spacing: 9
                                Rectangle {
                                    Layout.preferredWidth: 42; Layout.preferredHeight: 42
                                    radius: Appearance.rounding.small; color: Appearance.colors.colSecondaryContainer
                                    MaterialSymbol { anchors.centerIn: parent; text: "radio"; iconSize: 23; color: Appearance.colors.colOnSecondaryContainer }
                                    Image { anchors.fill: parent; anchors.margins: 6; source: stationCard.modelData.favicon || ""; fillMode: Image.PreserveAspectFit; asynchronous: true; visible: status === Image.Ready }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 1
                                    StyledText { Layout.fillWidth: true; text: stationCard.modelData.name || ""; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                    StyledText { Layout.fillWidth: true; text: stationCard.modelData.country || stationCard.modelData.tags || Translation.tr("Online radio"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller; elide: Text.ElideRight }
                                }
                                MaterialSymbol { text: RadioPlayer.playing && RadioPlayer.station?.stationuuid === stationCard.modelData.stationuuid ? "graphic_eq" : "play_arrow"; iconSize: 22; color: Appearance.colors.colPrimary }
                            }
                        }
                        PluginButton { iconOnly: true; symbol: "favorite"; text: Translation.tr("Favorites"); toggled: root.isFavorite(stationCard.modelData); onClicked: root.favorite(stationCard.modelData) }
                    }
                }
            }
        }
    }
}
