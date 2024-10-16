open Ast
open Angstrom
open Base
open Char

(*                   Auxiliary parsers                     *)

let is_whitespace = function
| ' ' | '\t' | '\n' | '\r' -> true
| _ -> false
let pass_ws = skip_while is_whitespace

(** Parser that matches string literals an 's' skipping all whitespaces before *)
let token s = pass_ws *> string s
let pparens stmt = token "(" *> stmt <* token ")"
let pdsemicolon = 
  let* str_part = take_while (function ';' -> false | _ -> true) in  
  let* semi_part = peek_char in  (* Peek to see if we have encountered `;` *)
  match semi_part with
  | Some ';' ->
    let* _ = string ";;" in  (* Ensure we consume both semicolons *)
    return str_part
  | _ -> fail "Expected ;;"
let pletters = satisfy (function 'a'..'z' | 'A'..'Z' | '_' -> true | _ -> false)
let ptowhitespace = function 'a'..'z' | 'A'..'Z' | '0'..'9' | '_' -> true | _ -> false


let pident =
  lift2 (fun first rest -> (String.make 1 first) ^ rest)
    pletters
    (take_while ptowhitespace)


(*                   Constant expressions                         *)
let pconstintexpr =
  let parse_sign = choice [ token "+"; token "-"; token " "] in
  let parse_number = take_while1 (function '0' .. '9' -> true | _ -> false) in
  lift2 (fun sign n -> Exp_constant (Const_integer (int_of_string (sign ^ n))))
    parse_sign
    parse_number


let pconstcharexpr =   
  let* _ = token "'" in 
  let* c = satisfy (fun code -> code >= ' ' && code <= '~') in 
  let* _ = token "'" in 
  return (Exp_constant(Const_char c))

let pconststringexpr = 
  token "\"" *> lift 
    (fun str -> Exp_constant(Const_string str)) 
    (take_while1 (function '"' -> false | _ -> true))

(*                   Arithm utils + ident parser                         *)
let lchain p op =
  let rec loop acc =
    (let* f = op in
     let* y = p in
     loop (f acc y))
    <|> return acc
  in
  let* x = p in
  loop x

  let rchain p op =
    let rec loop acc =
      (let* f = op in
       let* y = p in
       let new_acc = f acc y in
       loop new_acc)
      <|> return acc
    in
    let* x = p in
    loop x

let pidentexpr = lift (fun ident -> Exp_ident ident) pident

(*                   Patterns                         *)
let pany = token "_" *> return Pat_any
let pvar = lift (fun ident -> Pat_var ident) pident
let ppattern =
  pany <|> pvar (* <|> pconstant <|> ptuple <|> pconstruct, will be added in future, not necessary for fact *)

(*                   Exptessions                         *)

let pvalue_binding pexpr =
  let parse_pattern_and_expr =
    lift2 (fun pat expr -> { pat; expr }) ppattern (token "=" *> pexpr)
  in
  parse_pattern_and_expr
;;
let prec_flag = token "rec" *> return Recursive <|> return Nonrecursive
;;
let pletexpr pexpr =
  token "let" *> lift3 (fun rec_flag value_binding expr -> Exp_let(rec_flag, value_binding, expr))
  prec_flag (many1 (pvalue_binding pexpr)) pexpr
;;

let ptupleexpr =
  let* _ = token "(" in
  let* expression1 = pidentexpr in
  let* _ = token ";" in
  let* expression2 = pidentexpr in
  let* _ = token ";" in
  let* expressiontl = sep_by (char ';') pidentexpr in
  let* _ = token ")" in
  return (Exp_tuple(expression1, expression2, expressiontl))

let pifexpr pexpr =
  let* _ = token "if" in
  let* condition = pexpr in
  let* _ = token "then" in
  let* expr = pexpr in
  let* alternative = option None (
    let* _ = token "else" in
    let* expr = pexpr in
    return (Some expr)
  ) in
  return (Exp_if(condition, expr, alternative))

let papplyexpr pexpr =
  lift2 (fun fexpr sexpr -> Exp_apply(fexpr, sexpr)) pexpr pexpr
;;

let pfunexpr pexpr = 
  lift3 
    (fun first_pattern rest_patterns body_expr -> 
      Exp_fun (first_pattern, rest_patterns, body_expr))
    (token "fun" *> ppattern)
    (many ppattern)
    (token "->" *> pexpr)
;;

let parsebinop binoptoken =
  let parse_operator = pass_ws *> token binoptoken in
  lift (fun op e1 e2 -> Exp_apply (Exp_ident op, Exp_tuple (e1, e2, []))) parse_operator
;;


let padd = parsebinop "+"
let psub = parsebinop "-"
let pdiv = parsebinop "/"
let pmul = parsebinop "*"
let pcompops = 
  choice 
    [
      parsebinop ">";
      parsebinop "<";
      parsebinop ">=";
      parsebinop "<=";
      parsebinop "<>";
      parsebinop "=";
    ]

let plogops = 
  choice 
  [
    parsebinop "||";
    parsebinop "&&";
  ]

let pexpr = fix (fun expr ->
  let expr = choice [pparens expr; pconstintexpr; pconstcharexpr; pconststringexpr; ] in 
  let expr = papplyexpr expr <|> expr in 
  let expr = lchain expr (pmul <|> pdiv) in
  let expr = lchain expr (padd <|> psub) in
  let expr = lchain expr pcompops in
  let expr = rchain expr plogops in 
  let expr = pifexpr expr <|> expr in
  let expr = ptupleexpr <|> expr in 
  let expr = pletexpr expr <|> expr in
  let expr = pfunexpr expr <|> expr in 
  expr)
;;

(*                   Structure items                         *)

let pseval = lift (fun expr -> Str_eval(expr)) pexpr

let psvalue = 
  lift2 (fun rec_flag value_binding -> Str_value (rec_flag, value_binding)) prec_flag (many (pvalue_binding pexpr))
;;

(** It applies Str_eval to output of expression parser *)
let pstr_item =
  pseval <|> psvalue (*<|> psadt (* god bless us *)*)

(** It applies Str_eval to output of expression parser *)

let pstructure =
  let psemicolon = token ";;" in
  many (pstr_item <* psemicolon)

let parse str = parse_string ~consume:All pstructure str

let parse_fact str = 
  match parse str with
  | Ok str -> str
  | Error msg -> failwith msg

(* 

(* Example test cases for the parser *)
let test_cases = [
  ("1 + 2;;", 
   [Exp_apply (Exp_ident "+", Exp_tuple (Exp_constant (Const_integer 1), Exp_constant (Const_integer 2), []))]);
  
  ("'hello';;", 
   [Exp_constant (Const_string "hello")]);
  
  ("(1, 2, 3);;", 
   [Exp_tuple (Exp_constant (Const_integer 1), Exp_constant (Const_integer 2), [Exp_constant (Const_integer 3)])]);
  
  ("4 * (2 + 3);;", 
   [Exp_apply (Exp_ident "*", Exp_tuple 
                (Exp_constant (Const_integer 4), 
                 Exp_apply (Exp_ident "+", Exp_tuple 
                              (Exp_constant (Const_integer 2), 
                               Exp_constant (Const_integer 3), [])), []))]);
  
  ("8 / 2;;", 
   [Exp_apply (Exp_ident "/", Exp_tuple (Exp_constant (Const_integer 8), Exp_constant (Const_integer 2), []))]);
  
  ("3 - 4 + 5;;", 
   [Exp_apply (Exp_ident "+", Exp_tuple 
                (Exp_apply (Exp_ident "-", 
                            Exp_tuple (Exp_constant (Const_integer 3), 
                                       Exp_constant (Const_integer 4), [])), 
                 Exp_constant (Const_integer 5), []))]);
  
  ("x + y;;", 
   [Exp_apply (Exp_ident "+", Exp_tuple 
                (Exp_ident "x", Exp_ident "y", []))]);

]
let const_to_string n = 
  match n with 
  (* | Const_char (n) -> return n *)
  | Const_integer (n) -> string_of_int n
  | Const_string (n) -> n

let rec string_of_expr expr =
  match expr with
  | Exp_ident id -> id  (* Just return the identifier *)
  | Exp_constant n -> Printf.sprintf "%s" (const_to_string n)  (* Convert integer constants to strings *)
  | Exp_apply (exp1, exp2) ->
      Printf.sprintf "(%s %s)" (string_of_expr exp1) (string_of_expr exp2)
  | Exp_tuple (exp1, exp2 , exp_list) ->
      let tuple_list = [exp1 ; exp2] @ exp_list in 
      let exprs = List.map string_of_expr tuple_list in
      Printf.sprintf "(%s)" (String.concat ", " exprs)

let run_tests test_cases =
  for i = 0 to List.length test_cases - 1 do
    let (input, expected) = List.nth test_cases i in
    match parse input with
    | Ok result when result = expected ->
        Printf.printf "Passed: %s\n" input
    | Ok result ->
        Printf.printf "Failed: %s\nExpected: %s, Got: %s\n"
          input (string_of_expr expected) (string_of_expr result)
    | Error msg ->
        Printf.printf "Error parsing: %s -> %s\n" input msg
  done
;;

let () =
  run_tests test_cases *)



(* let parse str = 
  match parse_string ~consume:All pstructure str with
  | Ok result -> result  (* Assuming result is of type expression list *)
  | Error msg -> failwith msg *)

(* Example test cases for the parser *)
(* let () =
  let test_cases = [
    ("1 + 2;;", [Exp_apply (Exp_ident "+", Exp_tuple (Exp_constant (Const_integer 1), Exp_constant (Const_integer 2), []))]);
    ("'hello';;", [Exp_constant (Const_string "hello")]);
    ("(1, 2, 3);;", [Exp_tuple (Exp_constant (Const_integer 1), Exp_constant (Const_integer 2), [Exp_constant (Const_integer 3)])]);
    ("4 * (2 + 3);;", [Exp_apply (Exp_ident "*", Exp_tuple (Exp_constant (Const_integer 4), Exp_apply (Exp_ident "+", Exp_tuple (Exp_constant (Const_integer 2), Exp_constant (Const_integer 3), [])), []))]);
    ("8 / 2;;", [Exp_apply (Exp_ident "/", Exp_tuple (Exp_constant (Const_integer 8), Exp_constant (Const_integer 2), []))]);
    ("3 - 4 + 5;;", [Exp_apply (Exp_ident "+", Exp_tuple (Exp_apply (Exp_ident "-", Exp_tuple (Exp_constant (Const_integer 3), Exp_constant (Const_integer 4), [])), Exp_constant (Const_integer 5), []))]);
  ] in
  List.iter (fun (input, expected) ->
    let result = parse input in  (* Get the result from the parse function *)
    if result = expected then
      Printf.printf "Passed: %s\n" input
    else
      Printf.printf "Failed: %s (expected: %s, got: %s)\n" 
                    input 
                    ?? expected) 
                    (?? result)
  ) test_cases *)