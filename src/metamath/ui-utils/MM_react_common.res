open Expln_React_Mui
open Expln_React_Modal
open Expln_utils_promise

let rndProgress = (~text:string, ~pct:option<float>=?, ~onTerminate:option<unit=>unit>=?, ()) => {
    <Paper style=ReactDOM.Style.make(~padding=onTerminate->Belt.Option.map(_=>"5px")->Belt.Option.getWithDefault("10px"), ())>
        <Row alignItems=#center spacing=1.>
            <span style=ReactDOM.Style.make(~paddingLeft="10px", ())>
                {
                    switch pct {
                        | Some(pct) => `${text}: ${(pct *. 100.)->Js.Math.round->Belt.Float.toInt->Belt_Int.toString}%`
                        | None => text
                    }->React.string
                }
            </span>
            {
                switch onTerminate {
                    | None => React.null
                    | Some(onTerminate) => {
                        <IconButton onClick={_ => onTerminate()}>
                            <MM_Icons.CancelOutlined/>
                        </IconButton>
                    }
                }
            }
        </Row>
    </Paper>
}

let rndInfoDialog = (~text:string, ~onOk:unit=>unit) => {
    <Paper style=ReactDOM.Style.make(~padding="10px", ())>
        <Col spacing=1.>
            <span>
                {text->React.string}
            </span>
            <Button onClick={_=>onOk()} variant=#contained >
                {React.string("Ok")}
            </Button>
        </Col>
    </Paper>
}

let openInfoDialog = (~modalRef:modalRef, ~text:string, ~onOk:option<unit=>unit>=?, ()) => {
    openModal(modalRef, _ => React.null)->promiseMap(modalId => {
        updateModal(modalRef, modalId, () => {
            rndInfoDialog(~text, ~onOk = () => {
                closeModal(modalRef, modalId)
                onOk->Belt_Option.forEach(clbk => clbk())
            })
        })
    })->ignore
}

let kbrdHnd = (
    ~onCtrlEnter: option<() => unit>=?,
    ~onEsc: option<() => unit>=?,
    ()
):(ReactEvent.Keyboard.t => unit) => {
    (kbrdEvt:ReactEvent.Keyboard.t) => {
        if (onCtrlEnter->Belt.Option.isSome
                && kbrdEvt->ReactEvent.Keyboard.ctrlKey && kbrdEvt->ReactEvent.Keyboard.keyCode == 13) {
            onCtrlEnter->Belt.Option.getExn()
        } else if (onEsc->Belt.Option.isSome
                && kbrdEvt->ReactEvent.Keyboard.keyCode == 27) {
            onEsc->Belt.Option.getExn()
        }
    }
}