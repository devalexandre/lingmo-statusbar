/*
 * Copyright (C) 2024 LingmoOS Team.
 *
 * Author:     Reion Wong <aj@lingmo.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

import Lingmo.Accounts 1.0 as Accounts
import Lingmo.Bluez 1.0 as Bluez
import Lingmo.StatusBar 1.0
import Lingmo.Audio 1.0
import Lingmo.NetworkManagement 1.0 as NM
import LingmoUI.CompatibleModule 3.0 as LingmoUI

ControlCenterDialog {
    id: control

    width: 450
    height: _mainLayout.implicitHeight + LingmoUI.Units.largeSpacing * 2

    property var margin: 4 * Screen.devicePixelRatio
    property point position: Qt.point(0, 0)
    property var defaultSink: paSinkModel.defaultSink

    property bool bluetoothDisConnected: Bluez.Manager.bluetoothBlocked
    property var defaultSinkValue: defaultSink ? defaultSink.volume / PulseAudio.NormalVolume * 100.0 : -1

    property var borderColor: windowHelper.compositing ? LingmoUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.3)
                                                                  : Qt.rgba(0, 0, 0, 0.2) : LingmoUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.15)
                                                                                                                  : Qt.rgba(0, 0, 0, 0.15)

    property var volumeIconName: {
        if (defaultSinkValue <= 0)
            return "audio-volume-muted-symbolic"
        else if (defaultSinkValue <= 25)
            return "audio-volume-low-symbolic"
        else if (defaultSinkValue <= 75)
            return "audio-volume-medium-symbolic"
        else
            return "audio-volume-high-symbolic"
    }

    onBluetoothDisConnectedChanged: {
        bluetoothItem.checked = !bluetoothDisConnected
    }

    onWidthChanged: adjustCorrectLocation()
    onHeightChanged: adjustCorrectLocation()
    onPositionChanged: adjustCorrectLocation()

    color: "transparent"

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    Appearance {
        id: appearance
    }

    Notifications {
        id: notifications
    }

    SinkModel {
        id: paSinkModel

        onDefaultSinkChanged: {
            if (!defaultSink) {
                return
            }
        }
    }

    function toggleBluetooth() {
        const enable = !control.bluetoothDisConnected
        Bluez.Manager.bluetoothBlocked = enable

        for (var i = 0; i < Bluez.Manager.adapters.length; ++i) {
            var adapter = Bluez.Manager.adapters[i]
            adapter.powered = enable
        }
    }

    function adjustCorrectLocation() {
        var posX = control.position.x
        var posY = control.position.y

        if (posX + control.width >= StatusBar.screenRect.x + StatusBar.screenRect.width)
            posX = StatusBar.screenRect.x + StatusBar.screenRect.width - control.width - control.margin

        posY = rootItem.y + rootItem.height + control.margin

        control.x = posX
        control.y = posY
    }

    Brightness {
        id: brightness
    }

    NightLight {
        id: nightLight
    }

    Accounts.UserAccount {
        id: currentUser
    }

    LingmoUI.WindowBlur {
        view: control
        geometry: Qt.rect(control.x, control.y, control.width, control.height)
        windowRadius: _background.radius
        enabled: true
    }

    LingmoUI.WindowShadow {
        view: control
        geometry: Qt.rect(control.x, control.y, control.width, control.height)
        radius: _background.radius
    }

    Rectangle {
        id: _background
        anchors.fill: parent
        radius: windowHelper.compositing ? LingmoUI.Theme.bigRadius * 1.5 : 0
        color: LingmoUI.Theme.darkMode ? "#4D4D4D" : "#F0F0F0"
        opacity: windowHelper.compositing ? LingmoUI.Theme.darkMode ? 0.6 : 0.8 : 1.0
        antialiasing: true
        border.width: 1 / Screen.devicePixelRatio
        border.pixelAligned: Screen.devicePixelRatio > 1 ? false : true
        border.color: control.borderColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.Linear
            }
        }
    }

    ColumnLayout {
        id: _mainLayout
        anchors.fill: parent
        anchors.margins: LingmoUI.Units.largeSpacing
        spacing: LingmoUI.Units.largeSpacing

        Item {
            id: topItem
            Layout.fillWidth: true
            height: 32

            RowLayout {
                id: topItemLayout
                anchors.fill: parent
                anchors.rightMargin: LingmoUI.Units.largeSpacing
                spacing: LingmoUI.Units.largeSpacing

                Label {
                    leftPadding: LingmoUI.Units.largeSpacing
                    text: qsTr("Control Center")
                    font.bold: true
                    font.pointSize: 14
                    Layout.fillWidth: true
                }

                IconButton {
                    id: settingsButton
                    implicitWidth: topItem.height
                    implicitHeight: topItem.height
                    Layout.alignment: Qt.AlignTop
                    source: "qrc:/images/" + (LingmoUI.Theme.darkMode ? "dark/" : "light/") + "settings.svg"
                    onLeftButtonClicked: {
                        control.visible = false
                        process.startDetached("lingmo-settings")
                    }
                }

//                IconButton {
//                    id: shutdownButton
//                    implicitWidth: topItem.height
//                    implicitHeight: topItem.height
//                    Layout.alignment: Qt.AlignTop
//                    source: "qrc:/images/" + (LingmoUI.Theme.darkMode ? "dark/" : "light/") + "system-shutdown-symbolic.svg"
//                    onLeftButtonClicked: {
//                        control.visible = false
//                        process.startDetached("lingmo-shutdown")
//                    }
//                }
            }
        }

        Item {
            id: cardItems
            Layout.fillWidth: true
            Layout.preferredHeight: Math.ceil(cardLayout.count / 4) * 110

            property var cellWidth: cardItems.width / 4

            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: LingmoUI.Theme.bigRadius
                opacity: LingmoUI.Theme.darkMode ? 0.2 : 0.7
            }

            GridLayout {
                id: cardLayout
                anchors.fill: parent
                columnSpacing: 0
                columns: 4

                property int count: {
                    var count = 0

                    for (var i in cardLayout.children) {
                        if (cardLayout.children[i].visible)
                            ++count
                    }

                    return count
                }

                CardItem {
                    id: wirelessItem
                    Layout.fillHeight: true
                    Layout.preferredWidth: cardItems.cellWidth
                    icon: LingmoUI.Theme.darkMode || checked ? "qrc:/images/dark/network-wireless-connected-100.svg"
                                                           : "qrc:/images/light/network-wireless-connected-100.svg"
                    visible: enabledConnections.wirelessHwEnabled
                    checked: enabledConnections.wirelessEnabled
                    label: activeConnection.wirelessName ? activeConnection.wirelessName : qsTr("Wi-Fi")
                    onClicked: nmHandler.enableWireless(!checked)
                    onPressAndHold: {
                        control.visible = false
                        process.startDetached("lingmo-settings", ["-m", "wlan"])
                    }
                }

                CardItem {
                    id: bluetoothItem
                    Layout.fillHeight: true
                    Layout.preferredWidth: cardItems.cellWidth
                    icon: LingmoUI.Theme.darkMode || checked ? "qrc:/images/dark/bluetooth-symbolic.svg"
                                                           : "qrc:/images/light/bluetooth-symbolic.svg"
                    checked: !control.bluetoothDisConnected
                    label: qsTr("Bluetooth")
                    visible: Bluez.Manager.adapters.length
                    onClicked: control.toggleBluetooth()
                    onPressAndHold: {
                        control.visible = false
                        process.startDetached("lingmo-settings", ["-m", "bluetooth"])
                    }
                }

                CardItem {
                    id: darkModeItem
                    Layout.fillHeight: true
                    Layout.preferredWidth: cardItems.cellWidth
                    icon: LingmoUI.Theme.darkMode || checked ? "qrc:/images/dark/dark-mode.svg"
                                                           : "qrc:/images/light/dark-mode.svg"
                    checked: LingmoUI.Theme.darkMode
                    label: qsTr("Dark Mode")
                    onClicked: appearance.switchDarkMode(!LingmoUI.Theme.darkMode)
                }

                CardItem {
                    id: nightLightItem
                    Layout.fillHeight: true
                    Layout.preferredWidth: cardItems.cellWidth
                    icon: LingmoUI.Theme.darkMode || checked ? "qrc:/images/dark/night-light.svg"
                                                           : "qrc:/images/light/night-light.svg"
                    visible: nightLight.available
                    checked: nightLight.enabled
                    label: qsTr("Night Light")
                    onClicked: nightLight.enabled = !nightLight.enabled
                    onPressAndHold: {
                        control.visible = false
                        process.startDetached("lingmo-settings", ["-m", "display"])
                    }
                }

                CardItem {
                    Layout.fillHeight: true
                    Layout.preferredWidth: cardItems.cellWidth
                    icon: LingmoUI.Theme.darkMode || checked ? "qrc:/images/dark/do-not-disturb.svg"
                                                           : "qrc:/images/light/do-not-disturb.svg"
                    checked: notifications.doNotDisturb
                    label: qsTr("Do Not Disturb")
                    onClicked: notifications.doNotDisturb = !notifications.doNotDisturb
                }

                CardItem {
                    Layout.fillHeight: true
                    Layout.preferredWidth: cardItems.cellWidth
                    icon: LingmoUI.Theme.darkMode || checked ? "qrc:/images/dark/screenshot.svg"
                                                           : "qrc:/images/light/screenshot.svg"
                    checked: false
                    label: qsTr("Screenshot")
                    onClicked: {
                        control.visible = false
                        process.startDetached("lingmo-screenshot", ["-d", "500"])
                    }
                }
            }
        }

        // Network: wired and VPN connections with an on/off switch each
        Item {
            id: networkItem
            Layout.fillWidth: true
            implicitHeight: _networkColumn.implicitHeight + LingmoUI.Units.largeSpacing
            visible: _networkRepeater.visibleCount > 0

            NM.NetworkModel {
                id: _networkModel
            }

            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: LingmoUI.Theme.bigRadius
                opacity: LingmoUI.Theme.darkMode ? 0.2 : 0.7
            }

            Column {
                id: _networkColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: LingmoUI.Units.largeSpacing
                anchors.rightMargin: LingmoUI.Units.largeSpacing
                spacing: 2

                Repeater {
                    id: _networkRepeater
                    model: _networkModel

                    // Number of rows shown (wired + VPN), to hide the card when empty
                    property int visibleCount: 0
                    function recount() {
                        var n = 0
                        for (var i = 0; i < count; ++i)
                            if (itemAt(i) && itemAt(i).shown) ++n
                        visibleCount = n
                    }
                    onItemAdded: recount()
                    onItemRemoved: recount()

                    delegate: RowLayout {
                        readonly property bool isVpn: model.type === NM.Enums.Vpn
                        readonly property bool shown: (model.type === NM.Enums.Wired || isVpn)
                                                      && !model.duplicate && model.connectionPath !== ""
                        readonly property bool active: model.connectionState === NM.Enums.Activated
                        readonly property bool busy: model.connectionState === NM.Enums.Activating
                                                     || model.connectionState === NM.Enums.Deactivating

                        visible: shown
                        width: _networkColumn.width
                        height: shown ? 36 : 0
                        spacing: LingmoUI.Units.largeSpacing

                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            sourceSize: Qt.size(16, 16)
                            source: "qrc:/images/" + (LingmoUI.Theme.darkMode ? "dark/" : "light/")
                                    + (parent.isVpn ? "network-wired-activated" : "network-wired") + ".svg"
                            opacity: parent.active ? 1.0 : 0.5
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                text: model.name
                                elide: Text.ElideRight
                                color: LingmoUI.Theme.textColor
                            }

                            Label {
                                Layout.fillWidth: true
                                text: parent.parent.busy ? qsTr("Connecting…")
                                      : parent.parent.isVpn ? qsTr("VPN") : qsTr("Wired")
                                font.pointSize: 8
                                color: LingmoUI.Theme.disabledTextColor
                            }
                        }

                        Switch {
                            checked: parent.active || parent.busy
                            enabled: !parent.busy
                            onToggled: {
                                if (checked)
                                    nmHandler.activateConnection(model.connectionPath, model.devicePath, model.specificPath)
                                else
                                    nmHandler.deactivateConnection(model.connectionPath, model.devicePath)
                            }
                        }

                        onShownChanged: _networkRepeater.recount()
                    }
                }
            }
        }

        MprisItem {
            height: 96
            Layout.fillWidth: true
        }

        Item {
            id: brightnessItem
            Layout.fillWidth: true
            height: 40
            visible: brightness.enabled

            Rectangle {
                id: brightnessItemBg
                anchors.fill: parent
                color: "white"
                radius: LingmoUI.Theme.bigRadius
                opacity: LingmoUI.Theme.darkMode ? 0.2 : 0.7
            }

            RowLayout {
                anchors.fill: brightnessItemBg
                anchors.leftMargin: LingmoUI.Units.largeSpacing
                anchors.rightMargin: LingmoUI.Units.largeSpacing
                anchors.topMargin: LingmoUI.Units.smallSpacing
                anchors.bottomMargin: LingmoUI.Units.smallSpacing
                spacing: LingmoUI.Units.largeSpacing

                Image {
                    height: 16
                    width: height
                    sourceSize: Qt.size(width, height)
                    source: "qrc:/images/" + (LingmoUI.Theme.darkMode ? "dark" : "light") + "/brightness.svg"
                    smooth: false
                    antialiasing: true
                }

                Timer {
                    id: brightnessTimer
                    interval: 100
                    repeat: false
                    onTriggered: brightness.setValue(brightnessSlider.value)
                }

                Slider {
                    id: brightnessSlider
                    from: 1
                    to: 100
                    stepSize: 1
                    value: brightness.value
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onMoved: brightnessTimer.start()
                }

//                Label {
//                    text: brightnessSlider.value + "%"
//                    color: LingmoUI.Theme.disabledTextColor
//                    Layout.preferredWidth: _fontMetrics.advanceWidth("100%")
//                }
            }
        }

        // Night light warmth, while it is on
        Item {
            id: nightLightSliderItem
            Layout.fillWidth: true
            height: 40
            visible: nightLight.available && nightLight.enabled

            Rectangle {
                id: nightLightSliderBg
                anchors.fill: parent
                color: "white"
                radius: LingmoUI.Theme.bigRadius
                opacity: LingmoUI.Theme.darkMode ? 0.2 : 0.7
            }

            RowLayout {
                anchors.fill: nightLightSliderBg
                anchors.leftMargin: LingmoUI.Units.largeSpacing
                anchors.rightMargin: LingmoUI.Units.largeSpacing
                anchors.topMargin: LingmoUI.Units.smallSpacing
                anchors.bottomMargin: LingmoUI.Units.smallSpacing
                spacing: LingmoUI.Units.largeSpacing

                Image {
                    height: 16
                    width: height
                    sourceSize: Qt.size(width, height)
                    source: "qrc:/images/" + (LingmoUI.Theme.darkMode ? "dark" : "light") + "/night-light.svg"
                    smooth: false
                    antialiasing: true
                }

                Timer {
                    id: nightLightTimer
                    interval: 100
                    repeat: false
                    onTriggered: nightLight.temperature = nightLightSlider.value
                }

                // Warmer to the right
                Slider {
                    id: nightLightSlider
                    from: nightLight.maxTemperature
                    to: nightLight.minTemperature
                    stepSize: 100
                    value: nightLight.temperature
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onMoved: nightLightTimer.start()
                }

                Label {
                    text: nightLightSlider.value.toFixed(0) + " K"
                    color: LingmoUI.Theme.disabledTextColor
                    Layout.preferredWidth: _fontMetrics.advanceWidth("6500 K")
                }
            }
        }

        Item {
            id: volumeItem
            Layout.fillWidth: true
            height: 40
            visible: defaultSink

            Rectangle {
                id: volumeItemBg
                anchors.fill: parent
                color: "white"
                radius: LingmoUI.Theme.bigRadius
                opacity: LingmoUI.Theme.darkMode ? 0.2 : 0.7
            }

            RowLayout {
                anchors.fill: volumeItemBg
                anchors.leftMargin: LingmoUI.Units.largeSpacing
                anchors.rightMargin: LingmoUI.Units.largeSpacing
                anchors.topMargin: LingmoUI.Units.smallSpacing
                anchors.bottomMargin: LingmoUI.Units.smallSpacing
                spacing: LingmoUI.Units.largeSpacing

                Image {
                    height: 16
                    width: height
                    sourceSize: Qt.size(width, height)
                    source: "qrc:/images/" + (LingmoUI.Theme.darkMode ? "dark" : "light") + "/" + control.volumeIconName + ".svg"
                    smooth: false
                    antialiasing: true
                }

                Slider {
                    id: volumeSlider

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    from: PulseAudio.MinimalVolume
                    to: PulseAudio.NormalVolume

                    stepSize: to / (to / PulseAudio.NormalVolume * 100.0)

                    value: defaultSink ? defaultSink.volume : 0

                    onValueChanged: {
                        if (!defaultSink)
                            return

                        defaultSink.volume = value
                        defaultSink.muted = (value === 0)
                    }
                }

//                Label {
//                    text: parseInt(volumeSlider.value / PulseAudio.NormalVolume * 100.0) + "%"
//                    Layout.preferredWidth: _fontMetrics.advanceWidth("100%")
//                    color: LingmoUI.Theme.disabledTextColor
//                }
            }
        }

        FontMetrics {
            id: _fontMetrics
        }

        RowLayout {
            Layout.leftMargin: LingmoUI.Units.smallSpacing
            Layout.rightMargin: LingmoUI.Units.smallSpacing
            spacing: 0

            Label {
                id: timeLabel
                leftPadding: LingmoUI.Units.smallSpacing / 2
                color: LingmoUI.Theme.textColor

                Timer {
                    interval: 1000
                    repeat: true
                    running: true
                    triggeredOnStart: true
                    onTriggered: {
                        timeLabel.text = new Date().toLocaleDateString(Qt.locale(), Locale.LongFormat)
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            StandardItem {
                width: batteryLayout.implicitWidth + LingmoUI.Units.largeSpacing
                height: batteryLayout.implicitHeight + LingmoUI.Units.largeSpacing

                onClicked: {
                    control.visible = false
                    process.startDetached("lingmo-settings", ["-m", "battery"])
                }

                RowLayout {
                    id: batteryLayout
                    anchors.fill: parent
                    visible: battery.available
                    spacing: 0

                    Image {
                        id: batteryIcon
                        width: 22
                        height: 16
                        sourceSize: Qt.size(width, height)
                        source: "qrc:/images/" + (LingmoUI.Theme.darkMode ? "dark/" : "light/") + battery.iconSource
                        asynchronous: true
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        antialiasing: true
                        smooth: false
                    }

                    Label {
                        text: battery.chargePercent + "%"
                        color: LingmoUI.Theme.textColor
                        rightPadding: LingmoUI.Units.smallSpacing / 2
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    }
                }
            }
        }
    }

    function calcExtraSpacing(cellSize, containerSize) {
        var availableColumns = Math.floor(containerSize / cellSize)
        var extraSpacing = 0
        if (availableColumns > 0) {
            var allColumnSize = availableColumns * cellSize
            var extraSpace = Math.max(containerSize - allColumnSize, 0)
            extraSpacing = extraSpace / availableColumns
        }
        return Math.floor(extraSpacing)
    }
}
