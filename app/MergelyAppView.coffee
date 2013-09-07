{nickname} = KD.whoami().profile

class MergelyAppView extends JView
  #cssClass: "mergely"
  constructor:(options = {}, data) ->
    options.cssClass = "mergely"
    super(options)
    
    @header = new DiffHeaderView

    @merge = new KDView
      domId: "merge"
      
    @openFile = (path)->
        @loadFile(path, 'lhs')
    
    @header.on "DraggedItemDropped", (path, side)=>
        @loadFile(path,side)

  loadFile:(path, side)->
    file = FSHelper.createFileFromPath(path)
    file.fetchContents( (err, contents)=>
      @setDiffEditorContents(side, contents)
      @header.setFilename(path, side)
    )
  
  setDiffEditorContents:(side, contents)->
    $('#merge').mergely(side, contents)

  loadTestFiles:(a,b)->
    @loadFile(a, 'lhs')
    @loadFile(b, 'rhs')
  
  
  pistachio:->
    """
    {{> this.header}}
    {{> this.merge}}
    """
  viewAppended: ->
    # @setTemplate do @pistachio
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
