import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property var results: []
    property string status: ""
    property bool filtersOpen: false
    property bool applyAfterDownload: false
    property int page: 1
    property int lastPage: 1
    property int requestId: 0
    readonly property var sortModes: [
        { label: Translation.tr("Toplist"), value: "toplist" },
        { label: Translation.tr("Newest"), value: "date_added" },
        { label: Translation.tr("Relevance"), value: "relevance" },
        { label: Translation.tr("Random"), value: "random" },
        { label: Translation.tr("Views"), value: "views" },
        { label: Translation.tr("Favorites"), value: "favorites" }
    ]
    function search(nextPage) {
        const pageNumber = nextPage || 1
        root.status = Translation.tr("Loading…")
        const serial = ++root.requestId
        const c = Config.options.sidebar.wallhaven
        let u = "https://wallhaven.cc/api/v1/search?q=" + encodeURIComponent(query.text.trim()) + "&categories=" + encodeURIComponent(c.categories) + "&purity=" + encodeURIComponent(c.purity) + "&sorting=" + encodeURIComponent(c.sorting) + "&topRange=" + encodeURIComponent(c.topRange) + "&page=" + pageNumber
        if (c.atleast) u += "&atleast=" + encodeURIComponent(c.atleast)
        if (c.ratios) u += "&ratios=" + encodeURIComponent(c.ratios)
        if (c.apiKey) u += "&apikey=" + encodeURIComponent(c.apiKey)
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || serial !== root.requestId) return
            if (xhr.status !== 200) { root.status = Translation.tr("Request failed"); return }
            try {
                const data = JSON.parse(xhr.responseText)
                root.results = data.data || []
                root.page = data.meta?.current_page || pageNumber
                root.lastPage = data.meta?.last_page || root.page
                root.status = root.results.length ? "" : Translation.tr("No results")
                resultGrid.positionViewAtBeginning()
            } catch(e) { root.status = Translation.tr("Request failed") }
        }
        xhr.open("GET", u); xhr.send()
    }
    function categoryEnabled(index) { return Config.options.sidebar.wallhaven.categories[index] === "1" }
    function toggleCategory(index) {
        const current = Config.options.sidebar.wallhaven.categories
        let bits = [current[0] || "0", current[1] || "0", current[2] || "0"]
        bits[index] = bits[index] === "1" ? "0" : "1"
        if (bits.join("") !== "000") Config.options.sidebar.wallhaven.categories = bits.join("")
    }
    function download(item, apply) {
        if (downloadProc.running) return
        root.applyAfterDownload = apply
        root.status = Translation.tr("Downloading…")
        downloadProc.result = ""
        const directory = Config.options.sidebar.wallhaven.downloadPath || Config.options.wallpaperSelector.directory
        downloadProc.command = [Quickshell.shellPath("scripts/wallhaven/download.py"), item.path, directory]
        downloadProc.running = true
    }
    Process {
        id: downloadProc
        property string result: ""
        stdout: StdioCollector { onStreamFinished: downloadProc.result = text.trim() }
        onExited: (code, status) => {
            if (code !== 0 || !downloadProc.result) { root.status = Translation.tr("Download failed"); return }
            root.status = Translation.tr("Downloaded") + ": " + downloadProc.result
            if (root.applyAfterDownload) Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, downloadProc.result])
            downloadProc.result = ""
        }
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 10
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                StyledText { text: "Wallhaven"; font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.DemiBold }
                StyledText { text: Translation.tr("Find your next wallpaper"); Layout.fillWidth: true; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller; elide: Text.ElideRight }
            }
            PluginButton { symbol: "tune"; iconOnly: true; text: Translation.tr("Filters"); toggled: root.filtersOpen; onClicked: root.filtersOpen = !root.filtersOpen }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            ToolbarTextField { id: query; Layout.fillWidth: true; Layout.preferredHeight: 40; placeholderText: Translation.tr("Search Wallhaven"); selectByMouse: true; onAccepted: root.search(1) }
            PluginButton { symbol: "search"; iconOnly: true; text: Translation.tr("Search"); onClicked: root.search(1) }
        }
        ColumnLayout {
            visible: root.filtersOpen
            Layout.fillWidth: true; spacing: 6
            RowLayout {
                Layout.fillWidth: true; spacing: 5
                PluginButton { text: Translation.tr("General"); toggled: root.categoryEnabled(0); Layout.fillWidth: true; onClicked: root.toggleCategory(0) }
                PluginButton { text: Translation.tr("Anime"); toggled: root.categoryEnabled(1); Layout.fillWidth: true; onClicked: root.toggleCategory(1) }
                PluginButton { text: Translation.tr("People"); toggled: root.categoryEnabled(2); Layout.fillWidth: true; onClicked: root.toggleCategory(2) }
            }
            StyledComboBox {
                id: sortBox
                Layout.fillWidth: true; Layout.preferredHeight: 36
                buttonIcon: "sort"
                model: ListModel {
                    Component.onCompleted: {
                        for (const mode of root.sortModes) append({label: mode.label, value: mode.value})
                    }
                }
                textRole: "label"
                currentIndex: Math.max(0, root.sortModes.findIndex(x => x.value === Config.options.sidebar.wallhaven.sorting))
                onActivated: index => { Config.options.sidebar.wallhaven.sorting = root.sortModes[index].value }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                StyledText { text: Translation.tr("Minimum size"); color: Appearance.colors.colSubtext }
                ToolbarTextField {
                    Layout.fillWidth: true; Layout.preferredHeight: 36
                    placeholderText: "1920x1080"
                    text: Config.options.sidebar.wallhaven.atleast
                    onEditingFinished: Config.options.sidebar.wallhaven.atleast = text.trim()
                    onAccepted: { Config.options.sidebar.wallhaven.atleast = text.trim(); root.search(1) }
                }
            }
        }
        StyledText { visible: root.status.length > 0; Layout.fillWidth: true; text: root.status; color: Appearance.colors.colSubtext; elide: Text.ElideMiddle }
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            StyledText {
                anchors.centerIn: parent; width: parent.width - 24
                visible: resultGrid.count === 0 && root.status.length === 0
                text: Translation.tr("Search by tag or browse popular wallpapers")
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; color: Appearance.colors.colSubtext
            }
            GridView {
                id: resultGrid
                anchors.fill: parent; clip: true
                readonly property int columns: width >= 340 ? 2 : 1
                cellWidth: width / columns
                cellHeight: Math.max(192, cellWidth * 1.10)
                model: root.results
                ScrollBar.vertical: StyledScrollBar {}
                delegate: Item {
                    id: tile
                    required property var modelData
                    width: GridView.view.cellWidth; height: GridView.view.cellHeight
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 4
                        radius: Appearance.rounding.normal; color: Appearance.colors.colLayer2
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 6; spacing: 5
                            Item {
                                id: previewArea
                                Layout.fillWidth: true; Layout.fillHeight: true
                                layer.enabled: true
                                layer.effect: OpacityMask { maskSource: Rectangle { width: previewArea.width; height: previewArea.height; radius: Appearance.rounding.small } }
                                Rectangle { anchors.fill: parent; color: Appearance.colors.colLayer3 }
                                StyledImage { id: previewImage; anchors.fill: parent; source: tile.modelData.thumbs?.small ?? ""; fillMode: Image.PreserveAspectCrop }
                                MaterialSymbol { anchors.centerIn: parent; visible: previewImage.status !== Image.Ready; text: "image"; iconSize: 28; color: Appearance.colors.colSubtext }
                            }
                            StyledText { Layout.fillWidth: true; text: (tile.modelData.resolution ?? "") + "  ·  " + (tile.modelData.id ?? ""); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext; elide: Text.ElideRight }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 4
                                PluginButton { symbol: "download"; iconOnly: true; text: Translation.tr("Download"); enabled: !downloadProc.running; onClicked: root.download(tile.modelData, false) }
                                PluginButton { symbol: "wallpaper"; text: Translation.tr("Set"); Layout.fillWidth: true; enabled: !downloadProc.running; onClicked: root.download(tile.modelData, true) }
                                PluginButton { symbol: "open_in_new"; iconOnly: true; text: Translation.tr("Open in browser"); onClicked: Qt.openUrlExternally(tile.modelData.url) }
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: root.results.length > 0
            spacing: 8
            PluginButton { symbol: "chevron_left"; iconOnly: true; text: Translation.tr("Previous page"); enabled: root.page > 1; onClicked: root.search(root.page - 1) }
            StyledText { text: root.page + " / " + root.lastPage; color: Appearance.colors.colSubtext }
            PluginButton { symbol: "chevron_right"; iconOnly: true; text: Translation.tr("Next page"); enabled: root.page < root.lastPage; onClicked: root.search(root.page + 1) }
        }
    }
}
