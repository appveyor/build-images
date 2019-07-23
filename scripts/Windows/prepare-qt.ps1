function CreateJuncton ($link, $target) {
  if (test-path $link) {
    rd $link -force -recurce
  }
  cmd /c mklink /J $link $target
}

CreateJuncton -link C:\Qt\latest -target C:\qt\5.13.0
CreateJuncton -link C:\Qt\5.13 -target C:\qt\5.13.0
CreateJuncton -link C:\Qt\5.12 -target C:\qt\5.12.3 #5.12.4 has many issues
