class MergelyAppView extends JView
  constructor:(options = {}, data) ->
    options.cssClass = "mergely"
    super(options, data)
    
    @header = new DiffHeaderView

    @merge = new KDView
      domId: "merge"
    
    @header.on "DraggedItemDropped", (path, side)=>
        @loadFileFromPath(path,side)
  
  openLaunchedFile:(file)->
      @loadFile(file, 'lhs')

  loadFileFromPath:(path, side)->
      file=FSHelper.createFileFromPath(path)
      @loadFile(file, side)
  
  loadFile:(file, side)->
      file.fetchContents( (err, contents)=>
          @setDiffEditorContents(side, contents)
          @header.setFilename(file.path, side)
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
