// Emacs mode hint: -*- mode: JavaScript -*-
// https://stackoverflow.com/questions/25105269/silent-install-qt-run-installer-on-ubuntu-server
// https://github.com/wireshark/wireshark/blob/master/tools/qt-installer-windows.qs

// Look for Name elements in
// https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5123/Updates.xml
// Unfortunately it is not possible to disable deps like qt.tools.qtcreator

//[xml]$xml = Get-Content "Updates.xml"
//foreach( $packageUpdate in $xml.Updates.PackageUpdate)
//{ 
//    Write-Host "`"$($packageUpdate.Name)`","
//}

// 5.14.0 - https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5140/Updates.xml
//   MSVC 2017 32-bit
//   MSVC 2017 64-bit
//   MinGW 7.3.0 32-bit
//   MinGW 7.3.0 64-bit
//   Qt Charts, Qt Quick 3D, Qt Data Visualization, Qt Lottie Animation, Qt Purchasing, Qt Virtual Keyboard, Qt WebEngine, Qt Network Authorization, Qt WebGL Streaming Plugin, Qt Script, Qt Debug Information Files, Qt Quick Timeline

// 5.13.2 - https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5132/Updates.xml
//   MSVC 2017 32-bit
//   MSVC 2017 64-bit
//   MinGW 7.3.0 32-bit
//   MinGW 7.3.0 64-bit
//   Qt Charts, Qt Data Visualization, Qt Lottie Animation, Qt Purchasing, Qt Virtual Keyboard, Qt WebEngine, Qt Network Authorization, Qt WebGL Streaming Plugin, Qt Script, Qt Debug Information Files

// 5.12.6 - https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5126/Updates.xml
//   MSVC 2017 32-bit
//   MSVC 2017 64-bit
//   MinGW 7.3.0 32-bit
//   MinGW 7.3.0 64-bit
//   Qt Charts, Qt Data Visualization, Qt Purchasing, Qt Virtual Keyboard, Qt WebEngine, Qt Network Authorization, Qt WebGL Streaming Plugin, Qt Script, Qt Debug Information Files

// 5.9.8 - https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_598/Updates.xml
//   MSVC 2015 32-bit
//   MSVC 2017 64-bit
//   MinGW 5.3.0 32-bit
//   Qt Charts, Qt Data Visualization, Qt Purchasing, Qt Virtual Keyboard, Qt WebEngine, Qt Network Authorization, Qt Remote Objects, Qt Speech, Qt Script

// Tools
//   MinGW 7.3.0 32-bit
//   MinGW 7.3.0 64-bit
//   MinGW 5.3.0 32-bit
//   Qt Installer Framework 2.0
//   Qt Installer Framework 3.1

var LATEST_COMPONENTS = [
    // 5.14.0
    "qt.qt5.5140.win32_msvc2017",
    "qt.qt5.5140.win64_msvc2017_64",
    "qt.qt5.5140.win32_mingw73",
    "qt.qt5.5140.win64_mingw73",
    "qt.qt5.5140.debug_info",
    "qt.qt5.5140.debug_info.win32_msvc2017",
    "qt.qt5.5140.debug_info.win64_msvc2017_64",
    "qt.qt5.5140.qtcharts",
    "qt.qt5.5140.qtcharts.win32_mingw73",
    "qt.qt5.5140.qtcharts.win32_msvc2017",
    "qt.qt5.5140.qtcharts.win64_mingw73",
    "qt.qt5.5140.qtcharts.win64_msvc2017_64",

    "qt.qt5.5140.qtquick3d",
    "qt.qt5.5140.qtquick3d.win32_mingw73",
    "qt.qt5.5140.qtquick3d.win32_msvc2017",
    "qt.qt5.5140.qtquick3d.win64_mingw73",
    "qt.qt5.5140.qtquick3d.win64_msvc2017_64",

    "qt.qt5.5140.qtdatavis3d",
    "qt.qt5.5140.qtdatavis3d.win32_mingw73",
    "qt.qt5.5140.qtdatavis3d.win32_msvc2017",
    "qt.qt5.5140.qtdatavis3d.win64_mingw73",
    "qt.qt5.5140.qtdatavis3d.win64_msvc2017_64",
    "qt.qt5.5140.qtlottie",
    "qt.qt5.5140.qtlottie.win32_mingw73",
    "qt.qt5.5140.qtlottie.win32_msvc2017",
    "qt.qt5.5140.qtlottie.win64_mingw73",
    "qt.qt5.5140.qtlottie.win64_msvc2017_64",
    "qt.qt5.5140.qtnetworkauth",
    "qt.qt5.5140.qtnetworkauth.win32_mingw73",
    "qt.qt5.5140.qtnetworkauth.win32_msvc2017",
    "qt.qt5.5140.qtnetworkauth.win64_mingw73",
    "qt.qt5.5140.qtnetworkauth.win64_msvc2017_64",
    "qt.qt5.5140.qtpurchasing",
    "qt.qt5.5140.qtpurchasing.win32_mingw73",
    "qt.qt5.5140.qtpurchasing.win32_msvc2017",
    "qt.qt5.5140.qtpurchasing.win64_mingw73",
    "qt.qt5.5140.qtpurchasing.win64_msvc2017_64",
    "qt.qt5.5140.qtscript",
    "qt.qt5.5140.qtscript.win32_mingw73",
    "qt.qt5.5140.qtscript.win32_msvc2017",
    "qt.qt5.5140.qtscript.win64_mingw73",
    "qt.qt5.5140.qtscript.win64_msvc2017_64",
    "qt.qt5.5140.qtvirtualkeyboard",
    "qt.qt5.5140.qtvirtualkeyboard.win32_mingw73",
    "qt.qt5.5140.qtvirtualkeyboard.win32_msvc2017",
    "qt.qt5.5140.qtvirtualkeyboard.win64_mingw73",
    "qt.qt5.5140.qtvirtualkeyboard.win64_msvc2017_64",
    "qt.qt5.5140.qtwebengine",
    "qt.qt5.5140.qtwebengine.win32_msvc2017",
    "qt.qt5.5140.qtwebengine.win64_msvc2017_64",
    "qt.qt5.5140.qtwebglplugin",
    "qt.qt5.5140.qtwebglplugin.win32_mingw73",
    "qt.qt5.5140.qtwebglplugin.win32_msvc2017",
    "qt.qt5.5140.qtwebglplugin.win64_mingw73",
    "qt.qt5.5140.qtwebglplugin.win64_msvc2017_64",

    "qt.qt5.5140.qtquicktimeline",
    "qt.qt5.5140.qtquicktimeline.win32_mingw73",
    "qt.qt5.5140.qtquicktimeline.win32_msvc2017",
    "qt.qt5.5140.qtquicktimeline.win64_mingw73",
    "qt.qt5.5140.qtquicktimeline.win64_msvc2017_64"    
];

var PREVIOUS_COMPONENTS = [
    // 5.13.2
    "qt.qt5.5132.win32_msvc2017",
    "qt.qt5.5132.win64_msvc2017_64",
    "qt.qt5.5132.win32_mingw73",
    "qt.qt5.5132.win64_mingw73",
    "qt.qt5.5132.debug_info",
    "qt.qt5.5132.debug_info.win32_msvc2017",
    "qt.qt5.5132.debug_info.win64_msvc2017_64",
    "qt.qt5.5132.qtcharts",
    "qt.qt5.5132.qtcharts.win32_mingw73",
    "qt.qt5.5132.qtcharts.win32_msvc2017",
    "qt.qt5.5132.qtcharts.win64_mingw73",
    "qt.qt5.5132.qtcharts.win64_msvc2017_64",
    "qt.qt5.5132.qtdatavis3d",
    "qt.qt5.5132.qtdatavis3d.win32_mingw73",
    "qt.qt5.5132.qtdatavis3d.win32_msvc2017",
    "qt.qt5.5132.qtdatavis3d.win64_mingw73",
    "qt.qt5.5132.qtdatavis3d.win64_msvc2017_64",
    "qt.qt5.5132.qtlottie",
    "qt.qt5.5132.qtlottie.win32_mingw73",
    "qt.qt5.5132.qtlottie.win32_msvc2017",
    "qt.qt5.5132.qtlottie.win64_mingw73",
    "qt.qt5.5132.qtlottie.win64_msvc2017_64",
    "qt.qt5.5132.qtnetworkauth",
    "qt.qt5.5132.qtnetworkauth.win32_mingw73",
    "qt.qt5.5132.qtnetworkauth.win32_msvc2017",
    "qt.qt5.5132.qtnetworkauth.win64_mingw73",
    "qt.qt5.5132.qtnetworkauth.win64_msvc2017_64",
    "qt.qt5.5132.qtpurchasing",
    "qt.qt5.5132.qtpurchasing.win32_mingw73",
    "qt.qt5.5132.qtpurchasing.win32_msvc2017",
    "qt.qt5.5132.qtpurchasing.win64_mingw73",
    "qt.qt5.5132.qtpurchasing.win64_msvc2017_64",
    "qt.qt5.5132.qtscript",
    "qt.qt5.5132.qtscript.win32_mingw73",
    "qt.qt5.5132.qtscript.win32_msvc2017",
    "qt.qt5.5132.qtscript.win64_mingw73",
    "qt.qt5.5132.qtscript.win64_msvc2017_64",
    "qt.qt5.5132.qtvirtualkeyboard",
    "qt.qt5.5132.qtvirtualkeyboard.win32_mingw73",
    "qt.qt5.5132.qtvirtualkeyboard.win32_msvc2017",
    "qt.qt5.5132.qtvirtualkeyboard.win64_mingw73",
    "qt.qt5.5132.qtvirtualkeyboard.win64_msvc2017_64",
    "qt.qt5.5132.qtwebengine",
    "qt.qt5.5132.qtwebengine.win32_msvc2017",
    "qt.qt5.5132.qtwebengine.win64_msvc2017_64",
    "qt.qt5.5132.qtwebglplugin",
    "qt.qt5.5132.qtwebglplugin.win32_mingw73",
    "qt.qt5.5132.qtwebglplugin.win32_msvc2017",
    "qt.qt5.5132.qtwebglplugin.win64_mingw73",
    "qt.qt5.5132.qtwebglplugin.win64_msvc2017_64",

    // 5.12.6
    "qt.qt5.5126.win32_mingw73",
    "qt.qt5.5126.win32_msvc2017",
    "qt.qt5.5126.win64_mingw73",
    "qt.qt5.5126.win64_msvc2017_64",
    "qt.qt5.5126.debug_info",
    "qt.qt5.5126.debug_info.win32_msvc2017",
    "qt.qt5.5126.debug_info.win64_msvc2017_64",
    "qt.qt5.5126.qtcharts",
    "qt.qt5.5126.qtcharts.win32_mingw73",
    "qt.qt5.5126.qtcharts.win32_msvc2017",
    "qt.qt5.5126.qtcharts.win64_mingw73",
    "qt.qt5.5126.qtcharts.win64_msvc2017_64",
    "qt.qt5.5126.qtdatavis3d",
    "qt.qt5.5126.qtdatavis3d.win32_mingw73",
    "qt.qt5.5126.qtdatavis3d.win32_msvc2017",
    "qt.qt5.5126.qtdatavis3d.win64_mingw73",
    "qt.qt5.5126.qtdatavis3d.win64_msvc2017_64",
    "qt.qt5.5126.qtnetworkauth",
    "qt.qt5.5126.qtnetworkauth.win32_mingw73",
    "qt.qt5.5126.qtnetworkauth.win32_msvc2017",
    "qt.qt5.5126.qtnetworkauth.win64_mingw73",
    "qt.qt5.5126.qtnetworkauth.win64_msvc2017_64",
    "qt.qt5.5126.qtpurchasing",
    "qt.qt5.5126.qtpurchasing.win32_mingw73",
    "qt.qt5.5126.qtpurchasing.win32_msvc2017",
    "qt.qt5.5126.qtpurchasing.win64_mingw73",
    "qt.qt5.5126.qtpurchasing.win64_msvc2017_64",
    "qt.qt5.5126.qtscript",
    "qt.qt5.5126.qtscript.win32_mingw73",
    "qt.qt5.5126.qtscript.win32_msvc2017",
    "qt.qt5.5126.qtscript.win64_mingw73",
    "qt.qt5.5126.qtscript.win64_msvc2017_64",
    "qt.qt5.5126.qtvirtualkeyboard",
    "qt.qt5.5126.qtvirtualkeyboard.win32_mingw73",
    "qt.qt5.5126.qtvirtualkeyboard.win32_msvc2017",
    "qt.qt5.5126.qtvirtualkeyboard.win64_mingw73",
    "qt.qt5.5126.qtvirtualkeyboard.win64_msvc2017_64",
    "qt.qt5.5126.qtwebengine",
    "qt.qt5.5126.qtwebengine.win32_msvc2017",
    "qt.qt5.5126.qtwebengine.win64_msvc2017_64",
    "qt.qt5.5126.qtwebglplugin",
    "qt.qt5.5126.qtwebglplugin.win32_mingw73",
    "qt.qt5.5126.qtwebglplugin.win32_msvc2017",
    "qt.qt5.5126.qtwebglplugin.win64_mingw73",
    "qt.qt5.5126.qtwebglplugin.win64_msvc2017_64",

    // 5.9.8
    "qt.qt5.598.win32_mingw53",
    "qt.qt5.598.win32_msvc2015",
    "qt.qt5.598.win64_msvc2017_64",
    "qt.qt5.598.qtcharts",
    "qt.qt5.598.qtcharts.win32_mingw53",
    "qt.qt5.598.qtcharts.win32_msvc2015",
    "qt.qt5.598.qtcharts.win64_msvc2017_64",
    "qt.qt5.598.qtdatavis3d",
    "qt.qt5.598.qtdatavis3d.win32_mingw53",
    "qt.qt5.598.qtdatavis3d.win32_msvc2015",
    "qt.qt5.598.qtdatavis3d.win64_msvc2017_64",
    "qt.qt5.598.qtnetworkauth",
    "qt.qt5.598.qtnetworkauth.win32_mingw53",
    "qt.qt5.598.qtnetworkauth.win32_msvc2015",
    "qt.qt5.598.qtnetworkauth.win64_msvc2017_64",
    "qt.qt5.598.qtpurchasing",
    "qt.qt5.598.qtpurchasing.win32_mingw53",
    "qt.qt5.598.qtpurchasing.win32_msvc2015",
    "qt.qt5.598.qtpurchasing.win64_msvc2017_64",
    "qt.qt5.598.qtremoteobjects",
    "qt.qt5.598.qtremoteobjects.win32_mingw53",
    "qt.qt5.598.qtremoteobjects.win32_msvc2015",
    "qt.qt5.598.qtremoteobjects.win64_msvc2017_64",
    "qt.qt5.598.qtscript",
    "qt.qt5.598.qtscript.win32_mingw53",
    "qt.qt5.598.qtscript.win32_msvc2015",
    "qt.qt5.598.qtscript.win64_msvc2017_64",
    "qt.qt5.598.qtspeech",
    "qt.qt5.598.qtspeech.win32_mingw53",
    "qt.qt5.598.qtspeech.win32_msvc2015",
    "qt.qt5.598.qtspeech.win64_msvc2017_64",
    "qt.qt5.598.qtvirtualkeyboard",
    "qt.qt5.598.qtvirtualkeyboard.win32_mingw53",
    "qt.qt5.598.qtvirtualkeyboard.win32_msvc2015",
    "qt.qt5.598.qtvirtualkeyboard.win64_msvc2017_64",
    "qt.qt5.598.qtwebengine",
    "qt.qt5.598.qtwebengine.win32_msvc2015",
    "qt.qt5.598.qtwebengine.win64_msvc2017_64",

    // Tools
    "qt.tools.win32_mingw530",
    "qt.tools.win32_mingw730",
    "qt.tools.win64_mingw730",
    "qt.tools.ifw.20",
    "qt.tools.ifw.30",
    "qt.tools.ifw.31"
];

var INSTALL_COMPONENTS = LATEST_COMPONENTS;
if (!installer.environmentVariable("INSTALL_LATEST_ONLY")) {
    INSTALL_COMPONENTS = LATEST_COMPONENTS.concat(PREVIOUS_COMPONENTS);
}

function Controller() {
    installer.autoRejectMessageBoxes();
    installer.installationFinished.connect(function() {
        gui.clickButton(buttons.NextButton);
    })
}

Controller.prototype.WelcomePageCallback = function() {
    // click delay here because the next button is initially disabled for ~1 second
    gui.clickButton(buttons.NextButton, 3000);
}

Controller.prototype.CredentialsPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.DynamicTelemetryPluginFormCallback = function() {
    gui.currentPageWidget().TelemetryPluginForm.statisticGroupBox.disableStatisticRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);

    //for(var key in widget.TelemetryPluginForm.statisticGroupBox){
    //    console.log(key);
    //}
}

Controller.prototype.TargetDirectoryPageCallback = function()
{
    // Keep default at "C:\Qt".
    //gui.currentPageWidget().TargetDirectoryLineEdit.setText("E:\\Qt");
    //gui.currentPageWidget().TargetDirectoryLineEdit.setText(installer.value("HomeDir") + "/Qt");
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ComponentSelectionPageCallback = function() {

    // https://doc-snapshots.qt.io/qtifw-3.1/noninteractive.html
    var page = gui.pageWidgetByObjectName("ComponentSelectionPage");

    var archiveCheckBox = gui.findChild(page, "Archive");
    var latestCheckBox = gui.findChild(page, "Latest releases");
    var fetchButton = gui.findChild(page, "FetchCategoryButton");

    archiveCheckBox.click();
    latestCheckBox.click();
    fetchButton.click();

    var widget = gui.currentPageWidget();

    widget.deselectAll();

    for (var i = 0; i < INSTALL_COMPONENTS.length; i++) {
        widget.selectComponent(INSTALL_COMPONENTS[i]);
    }

    // widget.deselectComponent("qt.tools.qtcreator");
    // widget.deselectComponent("qt.55.qt3d");

    gui.clickButton(buttons.NextButton);
}

Controller.prototype.LicenseAgreementPageCallback = function() {
    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.StartMenuDirectoryPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ReadyForInstallationPageCallback = function()
{
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.FinishedPageCallback = function() {
var checkBoxForm = gui.currentPageWidget().LaunchQtCreatorCheckBoxForm;
if (checkBoxForm && checkBoxForm.launchQtCreatorCheckBox) {
    checkBoxForm.launchQtCreatorCheckBox.checked = false;
}
    gui.clickButton(buttons.FinishButton);
}