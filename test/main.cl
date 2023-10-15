import std="std" dom="dom"

obj "box" {
  in { cf&:cell }
  imixin { tree_node }
  output := dom.element "div" style="display: flex; flex-direction: column; border: 1px solid;" cf=@cf
}

obj "main" {
  output: cell

  root: box {
    dom.element "h3" "Input:"
    input_space: dom.element "textarea" style="height: 300px;"
    btn: dom.element "button" "Visualize!"
    
    dom.element "h3" "Output:"

    output_space: dom.element "div" style="border: 1px solid grey" 

    //reaction (dom.event @btn.output "click") {:  :}

    react (dom.event @btn.output "click") {:
      let odom = output_space.output.get()
      let idom = input_space.output.get()
      odom.textContent = idom.value
    :}
    
    /*
    clicked: dom.event @btn.output "click"

    clickedm: method "() => {
      let odom = output_space.output.get()
      let idom = input_space.output.get()
      odom.textContent = idom.value
      }"

    bind @clicked @clickedm  
    */

  }
  bind @root.output @output
}