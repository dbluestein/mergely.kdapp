class MergelyAppView extends JView
  constructor:(options = {}, data) ->
    options.cssClass = "mergely"
    super(options, data)
    
    @loadedFiles = {'lhs':null, 'rhs':null}
    
    @header = new DiffHeaderView

    @merge = new KDView
      domId: "merge"
    
    @header.on "DraggedItemDropped", (path, side)=>
        @loadFileFromPath(path,side)
        
    @initMenuEvents()
  
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
        @notify("No file to save.")
        return
      contents = $(@MERGELY_SELECTOR).mergely('get', side)
      file.once "fs.save.finished", (err, res)=>
          if err
            @notify "Error saving: #{err}"
            return
          @notify "Saved #{@labelForSide(side)} File"
      file.emit "file.requests.save", contents
          
  saveFileAs:(side)->
      contents = $(@MERGELY_SELECTOR).mergely('get', side)
      KD.utils.showSaveDialog appView, (input, finderController, dialog)=>
          node = finderController.treeController.selectedNodes[0]
          name = input.getValue()
          if not FSHelper.isValidFileName(name)
            return @notify "Enter a valid file name."
          if not node
            return @notify "Select a destination directory."
          dialog.destroy()
          parentDir = node.getData()
          file = @loadedFiles[side]
          if not file
            file = FSHelper.createFileFromPath "#{parentDir.path}/#{name}", "file"
          file.emit "file.requests.saveAs", contents, name, parentDir.path
          file.once "fs.saveAs.finished", (newfile,oldfile)=>
              @notify "Saved #{@labelForSide(side)}", "as #{newfile.path}"
              @loadedFiles[side] = newfile

  labelForSide:(side)->
      return {'lhs':"Left",'rhs':"Right"}[side];
  
  setDiffEditorContents:(side, contents)->
    $('#merge').mergely(side, contents)
  
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
