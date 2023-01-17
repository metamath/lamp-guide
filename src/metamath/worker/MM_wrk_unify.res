open MM_context
open Expln_utils_promise
open MM_wrk_ctx
open MM_proof_tree
open MM_provers

let procName = "MM_wrk_unify"

type exprSourceDto =
    | VarType
    | Hypothesis({label:string})
    | Assertion({args:array<expr>, label:string})

type proofNodeDto = {
    expr:expr,
    exprStr:option<string>, //for debug purposes
    parents: array<exprSourceDto>,
    proof: option<exprSourceDto>,
}

type proofTreeDto = {
    newVars: array<expr>,
    disj: disjMutable,
    nodes: array<proofNodeDto>,
}

type request = 
    | Unify({stmts: array<rootStmt>, bottomUp:bool})

type response =
    | OnProgress(float)
    | Result(proofTreeDto)

let unify = (
    ~preCtxVer: int,
    ~preCtx: mmContext,
    ~parenStr: string,
    ~varsText: string,
    ~disjText: string,
    ~hyps: array<wrkCtxHyp>,
    ~stmts: array<rootStmt>,
    ~bottomUp: bool,
    ~onProgress:float=>unit,
): promise<proofTreeDto> => {
    promise(resolve => {
        beginWorkerInteractionUsingCtx(
            ~preCtxVer,
            ~preCtx,
            ~parenStr,
            ~varsText,
            ~disjText,
            ~hyps,
            ~procName,
            ~initialRequest = Unify({stmts:stmts, bottomUp}),
            ~onResponse = (~resp, ~sendToWorker, ~endWorkerInteraction) => {
                switch resp {
                    | OnProgress(pct) => onProgress(pct)
                    | Result(proofTree) => {
                        endWorkerInteraction()
                        Js.Console.log2("proofTree", proofTree)
                        resolve(proofTree)
                    }
                }
            },
            ~enableTrace=false,
            ()
        )
    })
}

let rec exprSourceToDto = (src:exprSource):exprSourceDto => {
    switch src {
        | VarType => VarType
        | Hypothesis({label}) => Hypothesis({label:label})
        | Assertion({args, label}) => Assertion({args:args->Js_array2.map(pnGetExpr), label})
    }
}

and let proofNodeToDto = (node:proofNode):proofNodeDto => {
    {
        expr:node->pnGetExpr,
        exprStr:node->pnGetExprStr,
        parents: switch node->pnGetParents {
            | None => []
            | Some(parents) => parents->Js_array2.map(exprSourceToDto)
        },
        proof: node->pnGetProof->Belt.Option.map(exprSourceToDto),
    }
}

let proofTreeToDto = (tree:proofTree, stmts:array<expr>):proofTreeDto => {
    {
        newVars: tree->ptGetCopyOfNewVars,
        disj: tree->ptGetCopyOfDisj,
        nodes: stmts->Js.Array2.map(stmt => tree->ptGetOrCreateNode(stmt)->proofNodeToDto)
    }
}

let processOnWorkerSide = (~req: request, ~sendToClient: response => unit): unit => {
    switch req {
        | Unify({stmts, bottomUp}) => {
            let proofTree = unifyAll(
                ~parenCnt = getWrkParenCntExn(),
                ~frms = getWrkFrmsExn(),
                ~ctx = getWrkCtxExn(),
                ~stmts,
                ~bottomUp,
                ~maxSearchDepth = 5,
                ~onProgress = pct => sendToClient(OnProgress(pct)),
                ~debug=true,
                ()
            )
            sendToClient(Result(proofTree->proofTreeToDto(stmts->Js_array2.map(stmt=>stmt.expr))))
        }
    }
}