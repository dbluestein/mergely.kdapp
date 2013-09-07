class DropTargetHeader extends JView
  constructor:(side) ->
    options = {
      bind: "dragstart dragend dragover drop dragenter dragleave",
      cssClass:"header-droppable header-"+side,
    }
    super(options)
    @side = side
    @on "drop", (e)=>
      @parent.emit "DraggedItemDropped", e.originalEvent.dataTransfer.getData("text"), @side
      
class DiffHeaderView extends JView
  constructor:(options = {}) ->
    options.domId = "diffHeader"
    super(options)
    @left = new DropTargetHeader("lhs")
    @right = new DropTargetHeader("rhs")
  
  setFilename:(fileName, side)->
    $("#diffHeader .header-"+side).text(fileName);
  
  pistachio:->
    """
    {{> this.left}}
    {{> this.right}}
    """
