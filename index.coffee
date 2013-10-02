do->
  mergelyAppView = new MergelyAppView
  appView.addSubView mergelyAppView
  
  appView.on("FileNeedsToBeOpened", 
    (file)->
        console.log "mergely's parent appView received FileNeedsToBeOpened with file: "
        console.log file
        mergelyAppView.fileOpenedFromTree file
  )
  
  appView.emit "ready"