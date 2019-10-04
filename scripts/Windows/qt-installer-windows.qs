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

// 5.13.1 - https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5131/Updates.xml
//   MSVC 2017 32-bit
//   MSVC 2017 64-bit
//   MinGW 7.3.0 32-bit
//   MinGW 7.3.0 64-bit
//   Qt Charts, Qt Data Visualization, Qt Lottie Animation, Qt Purchasing, Qt Virtual Keyboard, Qt WebEngine, Qt Network Authorization, Qt WebGL Streaming Plugin, Qt Script, Qt Debug Information Files
// 5.12.5 - https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5125/Updates.xml
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

var INSTALL_COMPONENTS = [
    // 5.13.1
    "qt.qt5.5131.win32_msvc2017",
    "qt.qt5.5131.win64_msvc2017_64",
    "qt.qt5.5131.win32_mingw73",
    "qt.qt5.5131.win64_mingw73",
    "qt.qt5.5131.debug_info",
    "qt.qt5.5131.debug_info.win32_msvc2017",
    "qt.qt5.5131.debug_info.win64_msvc2017_64",
    "qt.qt5.5131.qtcharts",
    "qt.qt5.5131.qtcharts.win32_mingw73",
    "qt.qt5.5131.qtcharts.win32_msvc2017",
    "qt.qt5.5131.qtcharts.win64_mingw73",
    "qt.qt5.5131.qtcharts.win64_msvc2017_64",
    "qt.qt5.5131.qtdatavis3d",
    "qt.qt5.5131.qtdatavis3d.win32_mingw73",
    "qt.qt5.5131.qtdatavis3d.win32_msvc2017",
    "qt.qt5.5131.qtdatavis3d.win64_mingw73",
    "qt.qt5.5131.qtdatavis3d.win64_msvc2017_64",
    "qt.qt5.5131.qtlottie",
    "qt.qt5.5131.qtlottie.win32_mingw73",
    "qt.qt5.5131.qtlottie.win32_msvc2017",
    "qt.qt5.5131.qtlottie.win64_mingw73",
    "qt.qt5.5131.qtlottie.win64_msvc2017_64",
    "qt.qt5.5131.qtnetworkauth",
    "qt.qt5.5131.qtnetworkauth.win32_mingw73",
    "qt.qt5.5131.qtnetworkauth.win32_msvc2017",
    "qt.qt5.5131.qtnetworkauth.win64_mingw73",
    "qt.qt5.5131.qtnetworkauth.win64_msvc2017_64",
    "qt.qt5.5131.qtpurchasing",
    "qt.qt5.5131.qtpurchasing.win32_mingw73",
    "qt.qt5.5131.qtpurchasing.win32_msvc2017",
    "qt.qt5.5131.qtpurchasing.win64_mingw73",
    "qt.qt5.5131.qtpurchasing.win64_msvc2017_64",
    "qt.qt5.5131.qtscript",
    "qt.qt5.5131.qtscript.win32_mingw73",
    "qt.qt5.5131.qtscript.win32_msvc2017",
    "qt.qt5.5131.qtscript.win64_mingw73",
    "qt.qt5.5131.qtscript.win64_msvc2017_64",
    "qt.qt5.5131.qtvirtualkeyboard",
    "qt.qt5.5131.qtvirtualkeyboard.win32_mingw73",
    "qt.qt5.5131.qtvirtualkeyboard.win32_msvc2017",
    "qt.qt5.5131.qtvirtualkeyboard.win64_mingw73",
    "qt.qt5.5131.qtvirtualkeyboard.win64_msvc2017_64",
    "qt.qt5.5131.qtwebengine",
    "qt.qt5.5131.qtwebengine.win32_msvc2017",
    "qt.qt5.5131.qtwebengine.win64_msvc2017_64",
    "qt.qt5.5131.qtwebglplugin",
    "qt.qt5.5131.qtwebglplugin.win32_mingw73",
    "qt.qt5.5131.qtwebglplugin.win32_msvc2017",
    "qt.qt5.5131.qtwebglplugin.win64_mingw73",
    "qt.qt5.5131.qtwebglplugin.win64_msvc2017_64",

    // 5.12.5
    "qt.qt5.5125.win32_mingw73",
    "qt.qt5.5125.win32_msvc2017",
    "qt.qt5.5125.win64_mingw73",
    "qt.qt5.5125.win64_msvc2017_64",
    "qt.qt5.5125.debug_info",
    "qt.qt5.5125.debug_info.win32_msvc2017",
    "qt.qt5.5125.debug_info.win64_msvc2017_64",
    "qt.qt5.5125.qtcharts",
    "qt.qt5.5125.qtcharts.win32_mingw73",
    "qt.qt5.5125.qtcharts.win32_msvc2017",
    "qt.qt5.5125.qtcharts.win64_mingw73",
    "qt.qt5.5125.qtcharts.win64_msvc2017_64",
    "qt.qt5.5125.qtdatavis3d",
    "qt.qt5.5125.qtdatavis3d.win32_mingw73",
    "qt.qt5.5125.qtdatavis3d.win32_msvc2017",
    "qt.qt5.5125.qtdatavis3d.win64_mingw73",
    "qt.qt5.5125.qtdatavis3d.win64_msvc2017_64",
    "qt.qt5.5125.qtnetworkauth",
    "qt.qt5.5125.qtnetworkauth.win32_mingw73",
    "qt.qt5.5125.qtnetworkauth.win32_msvc2017",
    "qt.qt5.5125.qtnetworkauth.win64_mingw73",
    "qt.qt5.5125.qtnetworkauth.win64_msvc2017_64",
    "qt.qt5.5125.qtpurchasing",
    "qt.qt5.5125.qtpurchasing.win32_mingw73",
    "qt.qt5.5125.qtpurchasing.win32_msvc2017",
    "qt.qt5.5125.qtpurchasing.win64_mingw73",
    "qt.qt5.5125.qtpurchasing.win64_msvc2017_64",
    "qt.qt5.5125.qtscript",
    "qt.qt5.5125.qtscript.win32_mingw73",
    "qt.qt5.5125.qtscript.win32_msvc2017",
    "qt.qt5.5125.qtscript.win64_mingw73",
    "qt.qt5.5125.qtscript.win64_msvc2017_64",
    "qt.qt5.5125.qtvirtualkeyboard",
    "qt.qt5.5125.qtvirtualkeyboard.win32_mingw73",
    "qt.qt5.5125.qtvirtualkeyboard.win32_msvc2017",
    "qt.qt5.5125.qtvirtualkeyboard.win64_mingw73",
    "qt.qt5.5125.qtvirtualkeyboard.win64_msvc2017_64",
    "qt.qt5.5125.qtwebengine",
    "qt.qt5.5125.qtwebengine.win32_msvc2017",
    "qt.qt5.5125.qtwebengine.win64_msvc2017_64",
    "qt.qt5.5125.qtwebglplugin",
    "qt.qt5.5125.qtwebglplugin.win32_mingw73",
    "qt.qt5.5125.qtwebglplugin.win32_msvc2017",
    "qt.qt5.5125.qtwebglplugin.win64_mingw73",
    "qt.qt5.5125.qtwebglplugin.win64_msvc2017_64",

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

Controller.prototype.TargetDirectoryPageCallback = function()
{
    // Keep default at "C:\Qt".
    //gui.currentPageWidget().TargetDirectoryLineEdit.setText("E:\\Qt");
    //gui.currentPageWidget().TargetDirectoryLineEdit.setText(installer.value("HomeDir") + "/Qt");
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ComponentSelectionPageCallback = function() {
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