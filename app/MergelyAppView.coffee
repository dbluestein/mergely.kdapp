class MergelyAppView extends JView
  constructor:(options = {}, data) ->
    options.cssClass = "mergely"
    super(options, data)
    
    @loadedFiles = {'lhs':null, 'rhs':null}
    
    @header = new DiffHeaderView

    @merge = new KDView
      domId: "merge"
    
    @header.on "DraggedItemDropped", (path, side)=>
        @loadFileFromPath path, side
        
    @initMenuEvents()
    
    #handler to adjust mergely canvas on fullscreen toggle
    KD.getSingleton("mainView").on "fullscreen", (enabled)=>
          console.log "fullscreen toggled " + enabled
          sel = @MERGELY_SELECTOR
          if enabled
              $(sel).mergely "resize"
          else
              # Need to hook into the event that's fired at the end of 
              # the css transition when reducing from full-screen, so we can
              # have the mergely editors resize properly
              KD.getSingleton("mainView").once 'transitionend', (e)->
                  $(sel).mergely "resize"
  
  MERGELY_SELECTOR:'#merge'
  
  notify:(title="", content="", cssClass="error",type="main", duration="3500")->
      new KDNotificationView(
          {title:title,
          cssClass:cssClass,
          content:content,
          type:type,
          duration:duration})
  
  initMenuEvents:->
      appView.on "openMenuItemClicked", =>
          console.log "(inside mergely) openMenuItemClicked"
          @notify "Open not implemented yet", "use drag/drop instead"
      appView.on "saveChangedMenuItemClicked", =>
          console.log "save changed"
          @notify "Save Changed not implemented yet"
      appView.on "saveLeftMenuItemClicked", =>
          console.log "save left"
          @saveFile "lhs"
      appView.on "saveRightMenuItemClicked", =>
          console.log "save right"
          @saveFile "rhs"
      appView.on "saveLeftAsMenuItemClicked", =>
          console.log "save left as"
          @saveFileAs "lhs"
      appView.on "saveRightAsMenuItemClicked", =>
          console.log "save right as"
          @saveFileAs "rhs"
      appView.on "fullScreenMenuItemClicked", =>
          @toggleFullscreen()

  toggleFullscreen:->
      console.log "toggle fullscreen"
      KD.getSingleton("mainView").toggleFullscreen()
  
  # Called from index.coffee when a "FileNeedsToBeOpened" event is received
  fileOpenedFromTree:(file)->
      console.log "mergelyAppView open file from tree:"
      console.log file
      if @loadedFiles.lhs == null
        side = 'lhs'
      else if @loadedFiles.rhs == null
        side = 'rhs'
      else
        side = 'lhs'
        # TODO: figure out how to prompt user to pick which side to use
      console.log "Opening on " + side
      @loadFile(file, side)

  loadFileFromPath:(path, side)->
      file=FSHelper.createFileFromPath(path)
      @loadFile(file, side)
  
  loadFile:(file, side)->
      file.fetchContents( (err, contents)=>
          @setDiffEditorContents(side, contents)
          @header.setFilename(file.path, side)
          @loadedFiles[side] = file
      )
  
  saveFile:(side)->
      file = @loadedFiles[side]
      if not file
        @saveFileAs side
      else
        contents = @getDiffEditorContents side
        
        # callback that'll notify us when save is done
        file.once "fs.save.finished", (err, res)=>
            if err
              @notify "Error saving", "#{err.message}"
              console.log err
            else
              @notify "Saved #{@labelForSide(side)} File", file.path
        # and now request the file to be saved
        file.emit "file.requests.save", contents
          
  saveFileAs:(side)->
      contents = @getDiffEditorContents side
      KD.utils.showSaveDialog appView, (input, finderController, dialog)=>
          node = finderController.treeController.selectedNodes[0]
          name = input.getValue()
          if not FSHelper.isValidFileName(name)
            return @notify "Enter a valid file name."
          if not node
            return @notify "Select a destination directory."
          dialog.destroy()
          parentDir = node.getData()
          
          # create a FSfile object that our file will be saved-as
          file = FSHelper.createFileFromPath FSHelper.plainPath "#{parentDir.path}/#{name}", "file"
          
          ## Set up some callbacks for notifications of saving success, or error 
          
          # the fs.saveAs.finished handler will only execute if the file
          # saves successfully, not if there's an error.
          file.once "fs.saveAs.finished", (newfile,oldfile)=>
              @notify "Saved #{@labelForSide(side)}", "as #{newfile.path}"
              @loadedFiles[side] = newfile
              @header.setFilename newfile.path, "rhs"
          
          # the fs.save.finished will execute with a non-null error 
          # if there's a problem saving the file (typically if the path
          # can't be written) FSFile.saveAs() invokes FSFile.save()
          # so we can use this here
          file.once "fs.save.finished", (err, res)=>
            if err
              @notify "Error saving #{file.path}", "#{err.message}"
              console.log err
          
          # And then request the file to be saved
          # saveAs, if it's asked to save as a file that already exists,
          # it'll append _1, _2, etc. to the filename if it's saving
          # to a path that already exists
          file.emit "file.requests.saveAs", contents, name, parentDir.path

  labelForSide:(side)->
      return {'lhs':"Left",'rhs':"Right"}[side];
  
  setDiffEditorContents:(side, contents)->
    $(@MERGELY_SELECTOR).mergely side, contents 
  
  getDiffEditorContents:(side)->
    $(@MERGELY_SELECTOR).mergely 'get', side
  
  pistachio:->
    """
    {{> this.header}}
    {{> this.merge}}
    """

  viewAppended: ->
    super()
    $(@MERGELY_SELECTOR).mergely(
        {
            cmsettings: { readOnly: false, lineNumbers: true },
            editor_height:'94%',
            width:'auto'
        }
    )
    @setDiffEditorContents "lhs", "Drag a file from your tree\nonto the gray bar above"
    @setDiffEditorContents "rhs", "Drag a file from your tree\ninto the gray bar above"
    @header.setFilename "Drop here", "lhs"
    @header.setFilename "Drop here", "rhs"
