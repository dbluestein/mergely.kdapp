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
  
  """
  Called from index.coffee when a "FileNeedsToBeOpened" event is received
  """
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
  
  setDiffEditorContents:(side, contents)->
    $('#merge').mergely(side, contents)
  
  pistachio:->
    """
    {{> this.header}}
    {{> this.merge}}
    """

  viewAppended: ->
    super()
    $('#merge').mergely(
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
