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
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

import Lingmo.StatusBar 1.0
import Lingmo.NetworkManagement 1.0 as NM
import LingmoUI.CompatibleModule 3.0 as LingmoUI

Item {
    id: rootItem

    property int iconSize: 16

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    // Follows the system theme (the wallpaper-driven colour logic was never ported)
    property bool darkMode: LingmoUI.Theme.darkMode
    property color textColor: rootItem.darkMode ? "#FFFFFF" : "#000000";
    property var fontSize: rootItem.height ? rootItem.height / 3 : 1

    property var timeFormat: StatusBar.twentyFourTime ? "HH:mm" : "h:mm ap"

    onTimeFormatChanged: {
        timeTimer.restart()
    }

    // TODO: Fix ME!
    // System.Wallpaper {
    //     id: sysWallpaper

    //     function reload() {
    //         if (sysWallpaper.type === 0)
    //             bgHelper.setBackgound(sysWallpaper.path)
    //         else
    //             bgHelper.setColor(sysWallpaper.color)
    //     }

    //     Component.onCompleted: sysWallpaper.reload()

    //     onTypeChanged: sysWallpaper.reload()
    //     onColorChanged: sysWallpaper.reload()
    //     onPathChanged: sysWallpaper.reload()
    // }

    // BackgroundHelper {
    //     id: bgHelper

    //     onNewColor: {
    //         background.color = color
    //         rootItem.darkMode = darkMode
    //     }
    // }

    // Solid bar: white in the light theme, Dracula-like near-black in the dark one
    Rectangle {
        id: background
        anchors.fill: parent
        color: rootItem.darkMode ? "#282A36" : "#FFFFFF"

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        // Hairline separating the bar from the desktop
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: rootItem.darkMode ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)
        }

//        color: LingmoUI.Theme.darkMode ? "#4D4D4D" : "#FFFFFF"
//        opacity: windowHelper.compositing ? LingmoUI.Theme.darkMode ? 0.5 : 0.7 : 1.0

//        Behavior on color {
//            ColorAnimation {
//                duration: 100
//                easing.type: Easing.Linear
//            }
//        }
    }

    LingmoUI.WindowHelper {
        id: windowHelper
    }

    LingmoUI.PopupTips {
        id: popupTips
    }

    LingmoUI.DesktopMenu {
        id: acticityMenu

        MenuItem {
            text: qsTr("Close")
            icon.name: "window-close"
            onTriggered: acticity.close()
        }
    }

    // Main layout
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: LingmoUI.Units.smallSpacing
        anchors.rightMargin: LingmoUI.Units.smallSpacing
        spacing: LingmoUI.Units.smallSpacing / 2

        // App name
        StandardItem {
            id: acticityItem
            animationEnabled: true
            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(rootItem.width / 3,
                                            acticityLayout.implicitWidth + LingmoUI.Units.largeSpacing)
            onClicked: {
                if (mouse.button === Qt.RightButton)
                    acticityMenu.open()
            }

            RowLayout {
                id: acticityLayout
                anchors.fill: parent
                anchors.leftMargin: LingmoUI.Units.smallSpacing
                anchors.rightMargin: LingmoUI.Units.smallSpacing
                spacing: LingmoUI.Units.smallSpacing

                Image {
                    id: acticityIcon
                    width: rootItem.iconSize
                    height: rootItem.iconSize
                    sourceSize: Qt.size(rootItem.iconSize,
                                        rootItem.iconSize)
                    source: acticity.icon ? "image://icontheme/" + acticity.icon : ""
                    visible: status === Image.Ready
                    antialiasing: true
                    smooth: false
                }

                Label {
                    id: acticityLabel
                    text: acticity.title
                    Layout.fillWidth: true
                    elide: Qt.ElideRight
                    color: rootItem.textColor
                    visible: text
                    Layout.alignment: Qt.AlignVCenter
                    font.pointSize: rootItem.fontSize
                }
            }
        }

        // App menu
        Item {
            id: appMenuItem
            Layout.fillHeight: true
            Layout.fillWidth: true

            ListView {
                id: appMenuView
                anchors.fill: parent
                orientation: Qt.Horizontal
                spacing: LingmoUI.Units.smallSpacing
                visible: appMenuModel.visible
                interactive: false
                clip: true

                model: appMenuModel

                // Initialize the current index
                onVisibleChanged: {
                    if (!visible)
                        appMenuView.currentIndex = -1
                }

                delegate: StandardItem {
                    id: _menuItem
                    width: _actionText.width + LingmoUI.Units.largeSpacing
                    height: ListView.view.height
                    checked: appMenuApplet.currentIndex === index

                    onClicked: {
                        appMenuApplet.trigger(_menuItem, index)

                        checked = Qt.binding(function() {
                            return appMenuApplet.currentIndex === index
                        })
                    }

                    Text {
                        id: _actionText
                        anchors.centerIn: parent
                        color: rootItem.textColor
                        font.pointSize: rootItem.fontSize
                        text: {
                            var text = activeMenu
                            text = text.replace(/([^&]*)&(.)([^&]*)/g, function (match, p1, p2, p3) {
                                return p1.concat(p2, p3)
                            })
                            return text
                        }
                    }

                    // QMenu opens on press, so we'll replicate that here
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: appMenuApplet.currentIndex !== -1
                        onPressed: parent.clicked(null)
                        onEntered: parent.clicked(null)
                    }
                }

                AppMenuModel {
                    id: appMenuModel
                    onRequestActivateIndex: appMenuApplet.requestActivateIndex(appMenuView.currentIndex)
                    Component.onCompleted: {
                        appMenuView.model = appMenuModel
                    }
                }

                AppMenuApplet {
                    id: appMenuApplet
                    model: appMenuModel
                }

                Component.onCompleted: {
                    appMenuApplet.buttonGrid = appMenuView

                    // Handle left and right shortcut keys.
                    appMenuApplet.requestActivateIndex.connect(function (index) {
                        var idx = Math.max(0, Math.min(appMenuView.count - 1, index))
                        var button = appMenuView.itemAtIndex(index)
                        if (button) {
                            button.clicked(null)
                        }
                    });

                    // Handle mouse movement.
                    appMenuApplet.mousePosChanged.connect(function (x, y) {
                        var item = itemAt(x, y)
                        if (item)
                            item.clicked(null)
                    });
                }
            }
        }
        StandardItem {
            id: lyricsItem
            visible: lyricsHelper.lyricsVisible
            animationEnabled: true
            Layout.fillHeight: true
            Layout.preferredWidth: _lyricsLayout.implicitWidth + LingmoUI.Units.smallSpacing

            RowLayout {
                id: _lyricsLayout
                anchors.fill: parent

                Label {
                    id: lyricsLabel
                    Layout.alignment: Qt.AlignCenter
                    font.pointSize: rootItem.fontSize
                    color: rootItem.textColor
                    text: lyricsHelper.lyrics
                    }
                }
         }
        // System tray(Right)
        SystemTray {}

        StandardItem {
            id: permissionSurveillanceItem
            visible: permissionSurveillance.permissionSurveillanceVisible
            backcolor: "#ee7959"
            backColorEnabled: true
            checked: true
            popupText: permissionSurveillance.cameraUser + " " + qsTr("is using the camera")
            animationEnabled: true
            Layout.fillHeight: true
            Layout.preferredWidth: shutdownIcon.implicitWidth + LingmoUI.Units.smallSpacing + 4
            Image {
                id: permissionSurveillanceIcon
                anchors.centerIn: parent
                width: rootItem.iconSize
                height: width
                sourceSize: Qt.size(width, height)
                source: "qrc:/images/dark/camera.svg"
                asynchronous: true
                antialiasing: true
                smooth: false
            }
        }

        // Spotlight: click opens it, right click lets the user change its shortcut
        StandardItem {
            id: spotlightItem
            animationEnabled: true
            Layout.fillHeight: true
            Layout.preferredWidth: rootItem.iconSize + LingmoUI.Units.largeSpacing
            popupText: qsTr("Spotlight") + (spotlightShortcut.shortcut ? " (" + spotlightShortcut.shortcut + ")" : "")

            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton)
                    spotlightMenu.open()
                else
                    spotlightShortcut.openSpotlight()
            }

            // Magnifier glyph in the bar's text colour
            Item {
                anchors.centerIn: parent
                width: rootItem.iconSize
                height: width

                Rectangle {
                    x: 1; y: 1
                    width: parent.width * 0.62; height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1.6
                    border.color: rootItem.textColor
                }
                Rectangle {
                    width: parent.width * 0.36; height: 1.8; radius: 0.9
                    x: parent.width * 0.52; y: parent.height * 0.70
                    rotation: 45
                    transformOrigin: Item.Left
                    color: rootItem.textColor
                    antialiasing: true
                }
            }
        }

        StandardItem {
            id: controler

            checked: controlCenter.item.visible
            animationEnabled: true
            Layout.fillHeight: true
            Layout.preferredWidth: _controlerLayout.implicitWidth + LingmoUI.Units.largeSpacing

            onClicked: {
                toggleDialog()
            }

            function toggleDialog() {
                if (controlCenter.item.visible)
                    controlCenter.item.close()
                else {
                    // 先初始化，用户可能会通过Alt鼠标左键移动位置
                    controlCenter.item.position = Qt.point(0, 0)
                    controlCenter.item.position = mapToGlobal(0, 0)
                    controlCenter.item.open()
                }
            }

            RowLayout {
                id: _controlerLayout
                anchors.fill: parent
                anchors.leftMargin: LingmoUI.Units.smallSpacing
                anchors.rightMargin: LingmoUI.Units.smallSpacing

                spacing: LingmoUI.Units.largeSpacing

                Image {
                    id: volumeIcon
                    visible: controlCenter.item.defaultSink
                    source: "qrc:/images/" + (rootItem.darkMode ? "dark/" : "light/") + controlCenter.item.volumeIconName + ".svg"
                    width: rootItem.iconSize
                    height: width
                    sourceSize: Qt.size(width, height)
                    asynchronous: true
                    Layout.alignment: Qt.AlignCenter
                    antialiasing: true
                    smooth: false
                }

                // Network: wired, Wi-Fi (signal strength) or disconnected, plus a VPN badge
                RowLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignCenter

                    Image {
                        id: networkIcon
                        width: rootItem.iconSize
                        height: width
                        sourceSize: Qt.size(width, height)
                        source: "qrc:/images/" + (rootItem.darkMode ? "dark/" : "light/") + activeConnection.networkIcon + ".svg"
                        asynchronous: true
                        Layout.alignment: Qt.AlignCenter
                        opacity: activeConnection.connectionType === "none" ? 0.45 : 1.0
                        antialiasing: true
                        smooth: false
                    }

                    Rectangle {
                        visible: activeConnection.vpnActive
                        Layout.alignment: Qt.AlignCenter
                        implicitWidth: _vpnLabel.implicitWidth + 8
                        implicitHeight: _vpnLabel.implicitHeight + 2
                        radius: 3
                        color: "transparent"
                        border.width: 1
                        border.color: rootItem.textColor

                        Label {
                            id: _vpnLabel
                            anchors.centerIn: parent
                            text: "VPN"
                            font.pixelSize: 9
                            font.bold: true
                            color: rootItem.textColor
                        }
                    }
                }

                // Battery Item
                RowLayout {
                    visible: battery.available

                    Image {
                        id: batteryIcon
                        height: rootItem.iconSize
                        width: height + 6
                        sourceSize: Qt.size(width, height)
                        source: "qrc:/images/" + (rootItem.darkMode ? "dark/" : "light/") + battery.iconSource
                        Layout.alignment: Qt.AlignCenter
                        antialiasing: true
                        smooth: false
                    }

                    Label {
                        text: battery.chargePercent + "%"
                        font.pointSize: rootItem.fontSize
                        color: rootItem.textColor
                        visible: battery.showPercentage
                    }
                }
            }
        }

        StandardItem {
            id: shutdownItem

            animationEnabled: true
            Layout.fillHeight: true
            Layout.preferredWidth: shutdownIcon.implicitWidth + LingmoUI.Units.smallSpacing
            checked: shutdownDialog.item.visible

            onClicked: {
                shutdownDialog.item.position = Qt.point(0, 0)
                shutdownDialog.item.position = mapToGlobal(0, 0)
                shutdownDialog.item.open()
            }

            Image {
                id: shutdownIcon
                anchors.centerIn: parent
                width: rootItem.iconSize
                height: width
                sourceSize: Qt.size(width, height)
                source: "qrc:/images/" + (rootItem.darkMode ? "dark/" : "light/") + "system-shutdown-symbolic.svg"
                asynchronous: true
                antialiasing: true
                smooth: false
            }
        }

        // Pop-up notification center and calendar
        StandardItem {
            id: datetimeItem

            animationEnabled: true
            Layout.fillHeight: true
            Layout.preferredWidth: _dateTimeLayout.implicitWidth + LingmoUI.Units.smallSpacing

            onClicked: {
                process.startDetached("lingmo-notificationd", ["-s"])
            }

            RowLayout {
                id: _dateTimeLayout
                anchors.fill: parent

                // Notification bell: count badge, or the do-not-disturb icon
                Item {
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: rootItem.iconSize + (_badge.visible ? _badge.width / 2 : 0)
                    implicitHeight: rootItem.iconSize

                    Image {
                        id: _bell
                        width: rootItem.iconSize
                        height: width
                        sourceSize: Qt.size(width, height)
                        source: "qrc:/images/" + (rootItem.darkMode ? "dark/" : "light/")
                                + (notificationState.doNotDisturb ? "do-not-disturb.svg"
                                   : notificationState.count > 0 ? "notification-new-symbolic.svg"
                                   : "notification-symbolic.svg")
                        asynchronous: true
                        antialiasing: true
                        smooth: false
                    }

                    Rectangle {
                        id: _badge
                        visible: notificationState.count > 0 && !notificationState.doNotDisturb
                        anchors.left: _bell.horizontalCenter
                        anchors.top: _bell.top
                        anchors.topMargin: -3
                        height: 13
                        width: Math.max(height, _badgeText.implicitWidth + 7)
                        radius: height / 2
                        color: "#F2555A"

                        Label {
                            id: _badgeText
                            anchors.centerIn: parent
                            text: notificationState.count > 99 ? "99+" : notificationState.count
                            font.pixelSize: 9
                            font.bold: true
                            color: "white"
                        }
                    }
                }

                Label {
                    id: timeLabel
                    Layout.alignment: Qt.AlignCenter
                    font.pointSize: rootItem.fontSize
                    color: rootItem.textColor

                    Timer {
                        id: timeTimer
                        interval: 1000
                        repeat: true
                        running: true
                        triggeredOnStart: true
                        onTriggered: {
                            timeLabel.text = new Date().toLocaleTimeString(Qt.locale(), StatusBar.twentyFourTime ? rootItem.timeFormat
                                                                                                                 : Locale.ShortFormat)
                        }
                    }
                }
            }
        }

    }

    MouseArea {
        id: _sliding
        anchors.fill: parent
        z: -1

        property int startY: -1
        property bool activated: false

        onActivatedChanged: {
            // TODO
            // if (activated)
            //     acticity.move()
        }

        onPressed: {
            startY = mouse.y
        }

        onReleased: {
            startY = -1
        }

        onDoubleClicked: {
            acticity.toggleMaximize()
        }

        onMouseYChanged: {
            if (startY === parseInt(mouse.y)) {
                activated = false
                return
            }

            // Up
            if (startY > parseInt(mouse.y)) {
                activated = false
                return
            }

            if (mouse.y > rootItem.height)
                activated = true
            else
                activated = false
        }
    }

    // Components
    Loader {
        id: controlCenter
        sourceComponent: ControlCenter {}
        asynchronous: true
    }

    Loader {
        id: shutdownDialog
        sourceComponent: ShutdownDialog {}
        asynchronous: true
    }

    // Spotlight shortcut (stored in lingmo-chotkeys' config)
    SpotlightShortcut {
        id: spotlightShortcut
    }

    LingmoUI.DesktopMenu {
        id: spotlightMenu

        MenuItem {
            text: qsTr("Open Spotlight")
            icon.name: "system-search"
            onTriggered: spotlightShortcut.openSpotlight()
        }

        MenuItem {
            enabled: false
            text: qsTr("Shortcut: %1").arg(spotlightShortcut.shortcut || qsTr("none"))
        }

        MenuItem {
            text: qsTr("Change shortcut…")
            icon.name: "preferences-desktop-keyboard-shortcuts"
            onTriggered: shortcutDialog.show()
        }
    }

    // Small window that records the next key combination
    Window {
        id: shortcutDialog
        width: 360
        height: 170
        flags: Qt.Dialog | Qt.WindowStaysOnTopHint
        title: qsTr("Spotlight shortcut")
        color: rootItem.darkMode ? "#282A36" : "#FFFFFF"

        property string captured: ""
        property string error: ""

        function show() {
            captured = ""
            error = ""
            x = Screen.virtualX + (Screen.width - width) / 2
            y = Screen.virtualY + Screen.height / 3
            visible = true
            requestActivate()
            _capture.forceActiveFocus()
        }

        Item {
            id: _capture
            anchors.fill: parent
            focus: true

            Keys.onPressed: function(event) {
                event.accepted = true
                if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                    shortcutDialog.close()
                    return
                }
                var seq = spotlightShortcut.sequenceFromKey(event.key, event.modifiers)
                if (seq !== "") {
                    shortcutDialog.captured = seq
                    shortcutDialog.error = ""
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 12
                width: parent.width - 40

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Press the new key combination for Spotlight")
                    color: rootItem.textColor
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: 16
                    font.bold: true
                    text: shortcutDialog.captured || spotlightShortcut.shortcut || "…"
                    color: shortcutDialog.captured ? LingmoUI.Theme.highlightColor : rootItem.textColor
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: shortcutDialog.error !== ""
                    text: shortcutDialog.error
                    color: "#F2555A"
                    wrapMode: Text.WordWrap
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Button {
                        text: qsTr("Cancel")
                        onClicked: shortcutDialog.close()
                    }

                    Button {
                        text: qsTr("Save")
                        enabled: shortcutDialog.captured !== ""
                        onClicked: {
                            var err = spotlightShortcut.setShortcut(shortcutDialog.captured)
                            if (err === "")
                                shortcutDialog.close()
                            else
                                shortcutDialog.error = err
                        }
                    }
                }
            }
        }
    }

    // Notification center state (count, do not disturb) from lingmo-notificationd
    Notifications {
        id: notificationState
    }

    // NetworkManager state (Lingmo.NetworkManagement from lib_lingmo)
    NM.ActiveConnection {
        id: activeConnection
    }

    NM.EnabledConnections {
        id: enabledConnections
    }

    NM.Handler {
        id: nmHandler
    }
}
