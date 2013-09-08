KD.enableLogs()
do->
  appInstance.openFile = (file)->mergelyAppView.openLaunchedFile(file)
  mergelyAppView = new MergelyAppView
  appView.addSubView mergelyAppView
