import std="std"

obj "element"
{
    in {
        tag: cell "div"
        text: cell false
        style: cell false
        visible: cell true
        //class: cell
        //dom_parent: cell // @self.parent
        // это cl-объект с output в котором dom
        cf&: cell // дети
        // все-бы rest-параметры прокинуть в dom..
        named_rest**: cell
    }

    imixin { tree_node }

    output: cell

    // создаём объекты детей. в слоне теперь это надо делать явно.
    // вот бы эта x возвращала список. жить было бы проще
    apply_children @cf
    // print "x=" @x

    init {:

        //self.is_element = true

        function f() {
            let tagname = tag.get()

            let existing = output.is_set ? output.get() : null
            //if (existing) existing.remove()
            if (existing) throw new Error( 'dom: element already created')
            if (!tag.is_set) {
                if (self.output.is_set)
                    output.set( null )
                return
            }

            let elem = document.createElement(tagname);
            output.set( elem )
        }
        f()
        tag.changed.subscribe( f )

        self.release.subscribe( () => {
            //console.log("EEEEE")
            let existing = output.is_set ? output.get() : null
            if (existing) {
                //console.log("EEEEE2,existing - remove",existing,'self=',self+'')
                existing.remove()
            }
        } )
    :}
/*
    func "append_child_dom" {: ch |
        let parent = self
        let parent_dom = parent.output.get()        
        // потому что там еще и apply ребенок оказывается
        let child_dom = ch.output.get ? ch.output.get() : null
        if (child_dom instanceof Element) {
            console.log('append_child_dom working, parent_dom=',parent_dom,'child_dom=',child_dom)
            parent_dom.appendChild( child_dom ) // todo insert-adfter        
        }
    :}
*/    
/*  первая версия
    func "sync_children" {:
        
        let parent = self
        let parent_dom = parent.output.get()        
        let children = self.children.get()
        console.log("sync_children",self+'',children)
        for (let ch of children) {
            let child_dom = ch.output.get ? ch.output.get() : null
            if (!child_dom) continue;            
            if (!(child_dom instanceof Element)) continue
            parent_dom.appendChild( child_dom )
        }
    :}

    react @self.children @sync_children
*/    

/*  вторая версия - мониторит изменение ячейки .output у детев
*/    

    func "sync_children" {: children |
        
        let parent = self
        let parent_dom = parent.output.get()        

        //console.log("sync_children","parent_dom=",parent_dom,"ch=",children)

        for (let child_dom of children) {
            //console.log('checking ',child_dom)
            if (!(child_dom instanceof Element)) {
                //console.log("not element, skipping")
                continue
            } 
            //console.log("sync_children appends",child_dom)
            parent_dom.appendChild( child_dom )
        }
    :}

    react @xx.output @sync_children
    xx: xtract @child_elem_outputs // этим мы вытащили output-ы

    child_elem_outputs := apply {: children |
        //console.log("apply 1",self+'',children)
        let res = []
        for (let ch of children) {
            // todo вроде как не надо уже
            // if (!ch.is_element) continue
            res.push( ch.output )
        }
        return res
      :} @self.children

/*
    child_elem_outputs := map @self.children {: ch | 
          //console.log("map arg",ch)
          if (!ch.is_element) return false
          return CL2.create_cell( ch.output ) // дорого!
          :} 
          | filter {: elem | return elem ? true : false :}
*/

    func "set_text" {: //t |        
        let t = self.text.get()        
        if (t === false) return;
        // опасная операция - стирает детей
        let self_dom = self.output.get()
        
        if (self.output.is_set && self_dom) {
            //console.log('setting text',t,"to",self_dom)
            self_dom.textContent = t
        } //else console.log('!!!!!!!! SKIP setting text',t,"to",self_dom)
    :}

    //react @self.text @set_text
    //react @self.output @set_text
    react (list @self.text @self.output) @set_text

    func "set_style" {: //t |
        //console.log('setting style',t)
        let t = self.style.get()   
        if (t === false) return;
        let self_dom = self.output.get()

        if (self.visible.is_set && !self.visible.get()) {
            t = t + "; display: none;"
        } 

        self_dom.style = t
    :}

    //react @self.style @set_style 
    // visible бывает еще не рассчиталось и мы тогда считаем что visible чтоб не тормозить
    // хотя быть может стоит и вовсе быть не-visible тогда
    react (list @self.style @visible @output) {: args |
        set_style( args[0] )
    :}    

/*
    func "set_class" {: t | 
        //console.log('setting text',t)
        let self_dom = self.output.get()
        self_dom.className = t
    :}

    react @self.class @set_class
*/

/*
    react (list @self.visible @output) {: args |
        let self_dom = self.output.get()
        let val = args[0] ? 'visible' : 'hidden'
        console.log("vv",args[0],val)
        self_dom.style.visibility = val
    :}
*/    

    // передадим прочие именованные параметры напрямую в дом
    
    //react (list @output @named_rest) {: args |
    react @named_rest {: val |
         //let val = args[1]         
         let dom = self.output.get()
         //console.log("see named-rest",dom,val)
         for (let k in val) {
            //console.log(k,val[k])
            dom[ k ] = val[k]
         }
    :}
}

// создаёт канал из канала дом-события
// react (event @btn "click") { print "clicked!" }
obj "event"
{
    in {
        src: cell  // dom-элемент события
        name: cell // имя события    
    }
    output: channel

    init {: 
        let forget = () => {}

        function handler(arg) 
        {
            self.output.submit( arg )
        }

        function setup() {
            forget()
            //console.log(333)

            if (!(src.is_set && name.is_set)) return
            let dom = src.get()
            let n = name.get()
            //console.log('dom-event setup. dom=',dom,"n=",n)
            dom.addEventListener( n, handler )            
            forget = () => {
                dom.removeEventListener( n, handler )
                forget = () => {}
            }
        }
        self.src.changed.subscribe( setup )
        self.name.changed.subscribe( setup )
        setup()

        self.release.subscribe( () => forget() )
    :}
}

obj "input"
{
    in {
        type: cell "range"
        text: cell ""
        style: cell ""
        input_value: cell 1
        //tag: cell "input"
        named_rest**: cell
    }
    // кстати вопрос а зачем нам результат работы дом-элемента держать в output?

    //tree: tree_node // tree_child? неа нода - он же element в поддереве держит
    imixin { tree_node }
    
    output := elem: element "input" @text @style type=@type value=@input_value **named_rest
    // todo value отрабатывать самим, не грузить рест

    value: cell

    bind @input_value @value 
    // не надо биндить входное на выходное
    // выходное у нас это то что пользователь указывает.

    // но тогда надо прорабатывать any для реакта..

    // вот тут противоречие что у нас 2 источника получается для value..
    // init_value и события от дом
    // input это интерактивное
    react (event @output "change") {: evt |
        //console.log("output change",evt.target.value)
        self.value.submit( evt.target.value )
    :}
}

// получается создана только ради value
obj "textarea"
{
    in {
        input_value: cell ""        
        style: cell ""
        named_rest**: cell        
    }
    imixin { tree_node }
    
    output := elem: element "textarea" style=@style value=@input_value **named_rest

    //print "oooo=" @output

    value: cell
    //changing: channel

    //bind @input_value @value // эх

    react (event @output "input") {: evt |
        self.value.submit( evt.target.value )
    :}

   
}

// input_checkbox это тупняк. надо инпут с кустомным полем значения. например
// input "checkbox" field="checked"
obj "input_checkbox" {
    in {
        init_value: cell true
    }
    imixin { tree_node }

    output := input "checkbox" checked=@init_value
    is_element: cell
    value: cell
    bind @init_value @value

    react (event @output "change") {: evt |
        self.value.submit( evt.target.checked ? true : false )
    :}
}

obj "checkbox" {
    in {
        text: cell ""
        init_value: cell true
        cf&: cell
    }

    imixin { tree_node }

    is_element: cell
    value: cell

    output := element "label" { 
      cb: input_checkbox init_value=@init_value //checked=true
      bind @cb.value @value
      element "span" @text
      apply_children @cf
    }
}

// чтобы не росла flex-колонка от контента ставить стиль min-width:0;
obj "column" {
  in { 
     style: cell ""
     cf&:cell 
  }
  imixin { tree_node }
  is_element: cell
  output := element "div" style=( + "display: flex; flex-direction: column; " @style) cf=@cf
}

obj "row" {
  in { 
     style: cell ""
     cf&:cell 
  }
  imixin { tree_node }
  is_element: cell
  output := element "div" style=( + "display: flex; flex-direction: row; " @style) cf=@cf
}

// https://css-tricks.com/snippets/css/complete-guide-grid/#prop-grid-column-row
// https://markheath.net/post/simple-tables-with-css-grid-layout !!!!
obj "grid" {
  in { 
     tag: cell "div"
     style: cell ""
     visible: cell true
     cf&:cell     
     //named_rest**: cell
  }
  imixin { tree_node }
  
  output := element @tag style=( + "display: grid; " @style) cf=@cf visible=@visible
  //**named_rest 
}

// https://stackoverflow.com/a/30832210
func "download" {: data filename type | 
// Function to download data to a file
    var file = new Blob([data], {type: type || "application/octet-binary"});
    if (window.navigator.msSaveOrOpenBlob) // IE10+
        window.navigator.msSaveOrOpenBlob(file, filename);
    else { // Others
        var a = document.createElement("a"),
                url = URL.createObjectURL(file);
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        setTimeout(function() {
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);  
        }, 0);
    }
:}

// возвращает параметры из текущего урля в форме объекта
// url_query_params => { "a": 5", "b": 17}
func "url_query_params" {:
  const queryString = window.location.search;
  const urlParams = new URLSearchParams(queryString);
  return Object.fromEntries( urlParams )  
:}

/* устанавливает свойство "стиля" всем элементам (на глубину 1)
  set_style "color: white;" "tag_type" {
    dom.element "...."
    dom.element "...."
  }
  напрашивается обощение:
  set style="color: white;" { ... }
  set style="color: white;" @target_list
*/

// но вообще мб его сделать формой
mixin "tree_lift"
obj "set_style" {
    in {
        style: cell
        filter: cell false
        ch&: cell
    }
    apply_children @ch

    react (list @self.children @style @filter) {: args |
        let c = args[0]
        let s = args[1]
        let f = args[2]
        if (typeof(f) == "string")
            f = ( elem ) => elem.tag && elem.tag.get() == args[2];

        for (let k of c) {
            if (f(k)) {
                k.style.submit(s)
            }
        }
    :}
}

mixin "tree_lift"
process "generate_tabs" {
    in {
        input: cell [] // имена
        input_index: cell 0 
    }
    output: cell 0 // что кликнули

    repeater @input { name index |
       e: element "button" @name
       react (event @e.output "click") {:
         //console.log("clicked",index)
         output.submit( index )
       :}
    }
}

process "novalue" 
{
    output: cell
}

// select [ ["title","value"],["title","value"] ] input_index=1
mixin "tree_lift"
process "select" {
    in {
        input: cell []
        input_index: cell novalue=true
        input_value: cell novalue=true
    }
    ds: element "select" // этого мало - после изменения списка детей надо обновлять. selectedIndex=@input_index
    {
        repeater @input { rec |
            element "option" (get @rec 0) value=(get @rec 1)
        }
    }

    react (list @ds.children @input_value) {: args |
        let dom = ds.output.get()
        //console.log("setting to dom",dom,"value",input_value.get())
        //let v = input_value.get()
        let v = args[1]
        dom.value = v
    :}

    react (list @ds.children @input_index) {: args |
        let dom = ds.output.get()
        //console.log("setting to dom",dom,"value",input_value.get())
        //let v = input_value.get()
        let v = args[1]
        dom.selectedIndex = v
    :}    

    //react @input_index { v | print "vvvv=" @v }

    output: cell
    index: cell
    //value: cell
    //bind @output @value

    react (event @ds.output "change") {: evt |
        //console.log("sel output change",evt)
        self.output.submit( evt.target.value )
    :}
    //react (list @output @input_value {: val | output.set( )}
}