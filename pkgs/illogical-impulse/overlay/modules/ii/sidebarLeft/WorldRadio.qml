import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// World Radio: панель по мотивам плагина Noctalia (MIT, nilsonlinux).
Item {
    id: root
    property string view: "home" // home, countries, stations, favorites, custom
    property string heading: ""
    property string status: ""
    property var countries: []
    property var stations: []
    property var stats: ({})
    property string countryCode: ""
    property string selectedTag: ""
    property int offset: 0
    property bool more: false
    property bool loading: false
    property int serial: 0
    property int countryLimit: 50
    property bool editing: false
    property string editingId: ""
    readonly property var genres: [
        {name:"Rock", tag:"rock"}, {name:"Pop", tag:"pop"}, {name:"Jazz", tag:"jazz"},
        {name:"Classical", tag:"classical"}, {name:"Electronic", tag:"electronic"},
        {name:"Hip Hop", tag:"hip hop"}, {name:"News", tag:"news"}, {name:"Metal", tag:"metal"},
        {name:"Folk", tag:"folk"}, {name:"Ambient", tag:"ambient"}, {name:"80s", tag:"80s"}, {name:"90s", tag:"90s"}
    ]
    readonly property var filteredCountries: countries.filter(c => !searchBox.text.trim() || (c.name || "").toLowerCase().includes(searchBox.text.trim().toLowerCase()))
    readonly property var favoriteList: Array.from(Config.options.sidebar.radio.favorites)
    readonly property var customList: Array.from(Config.options.sidebar.radio.customStations)
    readonly property var currentList: view === "favorites" ? favoriteList : view === "custom" ? customList : stations
    readonly property string baseUrl: Config.options.sidebar.radio.apiServer.replace(/\/$/, "")

    function flag(code) {
        const c = (code || "").toUpperCase()
        if (!/^[A-Z]{2}$/.test(c)) return "🌐"
        return String.fromCodePoint(127397 + c.charCodeAt(0), 127397 + c.charCodeAt(1))
    }
    function request(path, ok, fail) {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) { if (fail) fail(); return }
            try { ok(JSON.parse(xhr.responseText)) } catch(e) { if (fail) fail() }
        }
        xhr.open("GET", baseUrl + path)
        xhr.send()
    }
    function ensureLoaded() {
        if (countries.length) return
        status = "Загружаем страны…"
        request("/json/stats", result => { root.stats = result }, () => {})
        request("/json/countries?order=stationcount&reverse=true&hidebroken=true", result => {
            root.countries = (Array.isArray(result) ? result : []).filter(c => c.iso_3166_1 && c.stationcount > 0)
            root.status = root.countries.length ? "" : "Страны не найдены"
        }, () => { root.status = "Не удалось загрузить страны. Проверь подключение." })
    }
    function home() { ++serial; loading = false; searchTimer.stop(); view = "home"; heading = ""; status = ""; searchBox.text = ""; editing = false; ensureLoaded() }
    function showCountries() { view = "countries"; heading = "Все страны"; countryLimit = 50; searchBox.text = ""; status = "" }
    function openStations(title, country, tag, initialQuery) {
        searchTimer.stop(); view = "stations"; heading = title; countryCode = country || ""; selectedTag = tag || ""
        searchBox.text = initialQuery || ""; stations = []; offset = 0; more = false; editing = false
        loadStations(false)
    }
    function loadStations(append) {
        if (loading && append) return
        searchTimer.stop()
        const requestSerial = ++serial
        const pageOffset = append ? offset : 0
        loading = true; status = "Загружаем станции…"
        let query = "/json/stations/search?hidebroken=true&order=votes&reverse=true&limit=50&offset=" + pageOffset
        if (countryCode) query += "&countrycode=" + encodeURIComponent(countryCode)
        if (selectedTag) query += "&tag=" + encodeURIComponent(selectedTag)
        if (searchBox.text.trim()) query += "&name=" + encodeURIComponent(searchBox.text.trim())
        request(query, result => {
            if (requestSerial !== root.serial) return
            const items = Array.isArray(result) ? result : []
            root.stations = append ? root.stations.concat(items) : items
            root.offset = pageOffset + items.length; root.more = items.length === 50
            root.loading = false; root.status = root.stations.length ? "" : "Станции не найдены"
        }, () => { if (requestSerial === root.serial) { root.loading = false; root.status = "Не удалось загрузить станции. Проверь подключение." } })
    }
    function showView(name, title) { ++serial; loading = false; searchTimer.stop(); view = name; heading = title; status = ""; searchBox.text = ""; editing = false }
    function isFavorite(item) { return favoriteList.some(s => s.stationuuid === item.stationuuid) }
    function favorite(item) {
        const a = favoriteList.filter(s => s.stationuuid !== item.stationuuid)
        if (!isFavorite(item)) a.unshift({stationuuid:item.stationuuid, name:item.name, url_resolved:item.url_resolved || item.url, favicon:item.favicon || "", country:item.country || "", countrycode:item.countrycode || "", bitrate:item.bitrate || 0, codec:item.codec || "", votes:item.votes || 0})
        Config.options.sidebar.radio.favorites = a
    }
    function editStation(item) {
        editingId = item?.stationuuid || ""
        customName.text = item?.name || ""
        customUrl.text = item?.url_resolved || item?.url || ""
        customCover.text = item?.favicon || ""
        editing = true
    }
    function saveStation() {
        const url = customUrl.text.trim()
        if (!/^https?:\/\//i.test(url)) { status = "Введите ссылку на поток с http:// или https://"; return }
        const image = customCover.text.trim()
        if (image && !/^https?:\/\//i.test(image)) { status = "Ссылка на обложку должна начинаться с http:// или https://"; return }
        const id = editingId || "local-" + Date.now().toString(36) + Math.floor(Math.random() * 10000).toString(36)
        const name = customName.text.trim() || url.replace(/^https?:\/\//i, "").split("/")[0]
        const item = {stationuuid:id, name:name, url_resolved:url, favicon:image, country:"Своя станция", custom:true}
        let a = customList.filter(s => s.stationuuid !== id); a.unshift(item)
        Config.options.sidebar.radio.customStations = a
        if (isFavorite(item)) { const f = favoriteList.map(s => s.stationuuid === id ? item : s); Config.options.sidebar.radio.favorites = f }
        editing = false; status = ""
    }
    function removeStation(item) {
        Config.options.sidebar.radio.customStations = customList.filter(s => s.stationuuid !== item.stationuuid)
        Config.options.sidebar.radio.favorites = favoriteList.filter(s => s.stationuuid !== item.stationuuid)
    }
    function searchChanged() {
        if (view === "stations") searchTimer.restart()
    }
    Timer { id: searchTimer; interval: 400; onTriggered: root.loadStations(false) }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Заголовок, быстрый доступ к избранному и своим станциям.
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: false; Layout.preferredHeight: 40; spacing: 6
            PluginButton { visible: root.view !== "home"; iconOnly: true; symbol: "arrow_back"; text: "Назад"; onClicked: root.home() }
            MaterialSymbol { visible: root.view === "home"; text: "radio"; iconSize: 24; color: Appearance.colors.colPrimary }
            StyledText { Layout.fillWidth: true; text: root.view === "home" ? "Мировое радио" : root.heading; font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.DemiBold; elide: Text.ElideRight }
            PluginButton { symbol: "favorite"; iconOnly: true; text: "Избранное"; toggled: root.view === "favorites"; onClicked: root.showView("favorites", "Избранное") }
            PluginButton { symbol: "podcasts"; iconOnly: true; text: "Свои станции"; toggled: root.view === "custom"; onClicked: root.showView("custom", "Свои станции") }
            PluginButton { visible: root.view === "custom"; symbol: "add"; iconOnly: true; text: "Добавить станцию"; onClicked: root.editStation(null) }
            PluginButton { symbol: "close"; iconOnly: true; text: "Закрыть"; onClicked: GlobalStates.radioOpen = false }
        }

        // Фиксированная высота: поле не растягивается на весь экран.
        RowLayout {
            visible: !root.editing; Layout.fillWidth: true; Layout.fillHeight: false
            Layout.preferredHeight: 42; Layout.minimumHeight: 42; Layout.maximumHeight: 42; spacing: 6
            ToolbarTextField {
                id: searchBox
                Layout.fillWidth: true; Layout.fillHeight: false
                Layout.preferredHeight: 42; Layout.minimumHeight: 42; Layout.maximumHeight: 42
                placeholderText: root.view === "home" || root.view === "countries" ? "Найти страну или нажать Enter для поиска станций" : "Поиск станций"
                selectByMouse: true
                onTextChanged: root.searchChanged()
                onAccepted: {
                    if (root.view === "home" || root.view === "countries") {
                        root.openStations("Поиск станций", "", "", text)
                    } else if (root.view === "stations") root.loadStations(false)
                }
            }
            PluginButton { iconOnly: true; symbol: "search"; text: "Искать станции"; onClicked: {
                if (root.view !== "stations") root.openStations("Поиск станций", "", "", searchBox.text)
                else root.loadStations(false)
            } }
        }
        StyledText { visible: root.status.length > 0; Layout.fillWidth: true; Layout.fillHeight: false; text: root.status; color: Appearance.colors.colSubtext; elide: Text.ElideRight }

        // Домашний экран: статистика, жанры и страны.
        Flickable {
            visible: root.view === "home" && !root.editing
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; contentWidth: width; contentHeight: dashboard.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: StyledScrollBar {}
            ColumnLayout {
                id: dashboard
                width: parent.width; spacing: 14
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Repeater {
                        model: [ {label:"Станций", number:root.stats.stations || 0, icon:"graphic_eq"}, {label:"Стран", number:root.stats.countries || 0, icon:"public"} ]
                        delegate: RippleButton {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.preferredHeight: 82; buttonRadius: Appearance.rounding.normal
                            colBackground: Appearance.colors.colLayer2; colBackgroundHover: Appearance.colors.colLayer2Hover
                            onClicked: index === 0 ? root.openStations("Все станции", "", "") : root.showCountries()
                            contentItem: Column {
                                spacing: 2
                                MaterialSymbol { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; iconSize: 20; color: Appearance.colors.colPrimary }
                                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: Number(modelData.number).toLocaleString(Qt.locale("ru_RU"), "f", 0); font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.DemiBold; color: Appearance.colors.colPrimary }
                                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { text: "Жанры и десятилетия"; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    MaterialSymbol { text: "music_note"; iconSize: 18; color: Appearance.colors.colSubtext }
                }
                Flow {
                    Layout.fillWidth: true; spacing: 5
                    Repeater {
                        model: root.genres
                        delegate: PluginButton {
                            required property var modelData
                            text: modelData.name; implicitHeight: 30
                            onClicked: root.openStations(modelData.name, "", modelData.tag)
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { text: "Страны"; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    PluginButton { text: "Все страны"; symbol: "arrow_forward"; onClicked: root.showCountries() }
                }
                GridLayout {
                    Layout.fillWidth: true; columns: 4; columnSpacing: 6; rowSpacing: 6
                    Repeater {
                        model: root.filteredCountries.slice(0, 12)
                        delegate: RippleButton {
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredHeight: 78; Layout.minimumWidth: 0
                            buttonRadius: Appearance.rounding.normal; colBackground: Appearance.colors.colLayer2; colBackgroundHover: Appearance.colors.colLayer2Hover
                            onClicked: root.openStations(modelData.name, modelData.iso_3166_1, "")
                            contentItem: Column {
                                spacing: 3
                                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: root.flag(modelData.iso_3166_1); font.family: "Noto Color Emoji"; font.pixelSize: 23 }
                                StyledText { anchors.horizontalCenter: parent.horizontalCenter; width: parent.width - 8; text: modelData.name; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; font.pixelSize: Appearance.font.pixelSize.smaller }
                                StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: Number(modelData.stationcount).toLocaleString(Qt.locale("ru_RU"), "f", 0); color: Appearance.colors.colPrimary; font.pixelSize: Appearance.font.pixelSize.smaller }
                            }
                        }
                    }
                }
                PluginButton { visible: root.filteredCountries.length > 12; text: "Показать все страны"; symbol: "public"; Layout.fillWidth: true; onClicked: root.showCountries() }
            }
        }

        // Полный список стран с постепенной отрисовкой.
        ListView {
            id: countryList
            visible: root.view === "countries" && !root.editing
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
            model: root.filteredCountries.slice(0, root.countryLimit)
            ScrollBar.vertical: StyledScrollBar {}
            delegate: RippleButton {
                id: countryRow
                required property var modelData
                width: ListView.view.width; height: 50; buttonRadius: Appearance.rounding.normal
                colBackground: Appearance.colors.colLayer2; colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.openStations(modelData.name, modelData.iso_3166_1, "")
                contentItem: RowLayout {
                    spacing: 10
                    StyledText { text: root.flag(countryRow.modelData.iso_3166_1); font.family: "Noto Color Emoji"; font.pixelSize: 24 }
                    StyledText { Layout.fillWidth: true; text: countryRow.modelData.name; elide: Text.ElideRight }
                    StyledText { text: Number(countryRow.modelData.stationcount).toLocaleString(Qt.locale("ru_RU"), "f", 0); color: Appearance.colors.colSubtext }
                    MaterialSymbol { text: "chevron_right"; iconSize: 20; color: Appearance.colors.colSubtext }
                }
            }
            footer: PluginButton { visible: root.countryLimit < root.filteredCountries.length; width: countryList.width; text: "Показать ещё"; onClicked: root.countryLimit += 50 }
        }

        // Станции, избранное и пользовательские потоки.
        Item {
            visible: (root.view === "stations" || root.view === "favorites" || root.view === "custom") && !root.editing
            Layout.fillWidth: true; Layout.fillHeight: true
            StyledText { anchors.centerIn: parent; visible: stationList.count === 0 && !root.loading && root.status.length === 0; text: root.view === "favorites" ? "Здесь появятся избранные станции" : root.view === "custom" ? "Добавь свою станцию кнопкой +" : "Станции не найдены"; color: Appearance.colors.colSubtext }
            ListView {
                id: stationList
                anchors.fill: parent; clip: true; spacing: 5
                model: root.currentList.filter(s => (root.view === "stations" || !searchBox.text.trim()) || (s.name || "").toLowerCase().includes(searchBox.text.trim().toLowerCase()))
                ScrollBar.vertical: StyledScrollBar {}
                delegate: Rectangle {
                    id: stationCard
                    required property var modelData
                    width: ListView.view.width; height: 66; radius: Appearance.rounding.normal; color: Appearance.colors.colLayer2
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 5; spacing: 6
                        RippleButton {
                            Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumWidth: 0
                            buttonRadius: Appearance.rounding.small; colBackground: "transparent"; colBackgroundHover: Appearance.colors.colLayer2Hover
                            onClicked: {
                                if (RadioPlayer.playing && RadioPlayer.station?.stationuuid === stationCard.modelData.stationuuid) RadioPlayer.stop()
                                else RadioPlayer.play(stationCard.modelData, root.currentList)
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                Rectangle {
                                    Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: Appearance.rounding.small; color: Appearance.colors.colSecondaryContainer
                                    MaterialSymbol { anchors.centerIn: parent; text: "radio"; iconSize: 22; color: Appearance.colors.colOnSecondaryContainer }
                                    Image { anchors.fill: parent; anchors.margins: 4; asynchronous: true; fillMode: Image.PreserveAspectFit; source: stationCard.modelData.favicon || ""; visible: status === Image.Ready }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 2
                                    StyledText { Layout.fillWidth: true; text: stationCard.modelData.name || ""; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                    StyledText { Layout.fillWidth: true; text: [stationCard.modelData.country || "", stationCard.modelData.codec || "", stationCard.modelData.bitrate ? stationCard.modelData.bitrate + " kbps" : "", stationCard.modelData.votes ? "★ " + stationCard.modelData.votes : ""].filter(Boolean).join(" · "); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller; elide: Text.ElideRight }
                                }
                                MaterialSymbol { text: RadioPlayer.playing && RadioPlayer.station?.stationuuid === stationCard.modelData.stationuuid ? "stop_circle" : "play_circle"; iconSize: 25; color: Appearance.colors.colPrimary }
                            }
                        }
                        PluginButton { visible: root.view === "custom"; iconOnly: true; symbol: "edit"; text: "Изменить"; onClicked: root.editStation(stationCard.modelData) }
                        PluginButton { visible: root.view === "custom"; iconOnly: true; symbol: "delete"; text: "Удалить"; onClicked: root.removeStation(stationCard.modelData) }
                        PluginButton { iconOnly: true; symbol: "favorite"; text: "Избранное"; toggled: root.isFavorite(stationCard.modelData); onClicked: root.favorite(stationCard.modelData) }
                    }
                }
                footer: PluginButton { visible: root.view === "stations" && root.more; width: stationList.width; text: root.loading ? "Загрузка…" : "Показать ещё"; enabled: !root.loading; onClicked: root.loadStations(true) }
            }
        }

        ColumnLayout {
            visible: root.editing; Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8
            StyledText { text: root.editingId ? "Изменить станцию" : "Новая станция"; font.weight: Font.DemiBold }
            ToolbarTextField { id: customName; Layout.fillWidth: true; Layout.fillHeight: false; Layout.preferredHeight: 42; placeholderText: "Название (необязательно)" }
            ToolbarTextField { id: customUrl; Layout.fillWidth: true; Layout.fillHeight: false; Layout.preferredHeight: 42; placeholderText: "Ссылка на поток (https://…)" }
            ToolbarTextField { id: customCover; Layout.fillWidth: true; Layout.fillHeight: false; Layout.preferredHeight: 42; placeholderText: "Ссылка на обложку (необязательно)" }
            RowLayout {
                PluginButton { text: "Отмена"; onClicked: root.editing = false }
                PluginButton { text: "Сохранить"; symbol: "check"; toggled: true; onClicked: root.saveStation() }
            }
            Item { Layout.fillHeight: true }
        }

        // Мини-плеер остаётся видимым при переходе между экранами.
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: false; Layout.preferredHeight: 94
            radius: Appearance.rounding.normal; color: Appearance.colors.colLayer2
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 9; spacing: 2
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    MaterialSymbol { text: RadioPlayer.playing ? "graphic_eq" : "radio"; iconSize: 22; color: Appearance.colors.colPrimary }
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 0
                        StyledText { text: RadioPlayer.station?.name ?? "Радио выключено"; Layout.fillWidth: true; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        StyledText { text: RadioPlayer.playing ? "В эфире" : "Выбери станцию"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                    }
                    PluginButton { iconOnly: true; symbol: "skip_previous"; text: "Предыдущая"; enabled: RadioPlayer.queue.length > 1; onClicked: RadioPlayer.skip(-1) }
                    PluginButton { iconOnly: true; symbol: RadioPlayer.playing ? "stop" : "play_arrow"; text: RadioPlayer.playing ? "Остановить" : "Воспроизвести"; enabled: RadioPlayer.station !== null; onClicked: RadioPlayer.playing ? RadioPlayer.stop() : RadioPlayer.resume() }
                    PluginButton { iconOnly: true; symbol: "skip_next"; text: "Следующая"; enabled: RadioPlayer.queue.length > 1; onClicked: RadioPlayer.skip(1) }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    MaterialSymbol { text: "volume_up"; iconSize: 16; color: Appearance.colors.colSubtext }
                    StyledSlider { Layout.fillWidth: true; Layout.preferredHeight: 16; from: 0; to: 100; stepSize: 1; value: Config.options.sidebar.radio.volume; onMoved: RadioPlayer.setVolume(value) }
                    StyledText { text: Math.round(Config.options.sidebar.radio.volume) + "%"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                }
            }
        }
    }
}
