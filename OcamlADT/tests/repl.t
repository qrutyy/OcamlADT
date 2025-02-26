(** Copyright 2024-2025, Rodion Suvorov, Mikhail Gavrilenko *)

(** SPDX-License-Identifier: LGPL-3.0-or-later *)

  $ ../bin/interpret.exe  manytests/typed/001fac.ml
  Running... 
  val fac : int -> int
  val main : int

  $ ../bin/interpret.exe  manytests/typed/002fac.ml
  Running... 
  val fac_cps : int -> (int -> 'a) -> 'a
  val main : int

  $ ../bin/interpret.exe  manytests/typed/003fib.ml
  Running... 
  val fib : int -> int
  val fib_acc : int -> int -> int -> int
  val main : int

  $ ../bin/interpret.exe  manytests/typed/004manyargs.ml
  Running... 
  val main : int
  val test10 : int -> int -> int -> int -> int -> int -> int -> int -> int -> int -> int
  val test3 : int -> int -> int -> int
  val wrap : 'a -> 'a

  $ ../bin/interpret.exe  manytests/typed/005fix.ml
  Running... 
  val fac : (int -> int) -> int -> int
  val fix : (('a -> 'b) -> 'a -> 'b) -> 'a -> 'b
  val main : int

  $ ../bin/interpret.exe  manytests/typed/006partial.ml
  Running... 
  val foo : int -> int
  val main : int

  $ ../bin/interpret.exe  manytests/typed/006partial2.ml
  Running... 
  val foo : int -> int -> int -> int
  val main : int

  $ ../bin/interpret.exe  manytests/typed/006partial3.ml
  Running... 
  val foo : int -> int -> int -> unit
  val main : int

  $ ../bin/interpret.exe  manytests/typed/007order.ml
  Running... 
  val _start : unit -> unit -> int -> unit -> int -> int -> unit -> int -> int -> int
  val main : unit

  $ ../bin/interpret.exe  manytests/typed/008ascription.ml
  Running... 
  val addi : ('a -> bool -> int) -> ('a -> bool) -> 'a -> int
  val main : int

  $ ../bin/interpret.exe  manytests/typed/009let_poly.ml
  Running... 
  val temp : int * bool

  $ ../bin/interpret.exe manytests/typed/010sukharev.ml
  Running... 
  val _1 : int -> int -> int * 'a -> bool
  val _2 : int
  val _3 : (int * string) option
  val _4 : int -> 'a
  val _42 : int -> bool
  val _5 : int
  val _6 : 'a option -> 'a
  val id1 : 'a -> 'a
  val id2 : 'b -> 'b
  val int_of_option : int option -> int

  $ ../bin/interpret.exe  manytests/typed/015tuples.ml
  Running... 
  val feven : 'a * (int -> int) -> int -> int
  val fix : (('a -> 'b) -> 'a -> 'b) -> 'a -> 'b
  val fixpoly : (('a -> 'b) * ('a -> 'b) -> 'a -> 'b) * (('a -> 'b) * ('a -> 'b) -> 'a -> 'b) -> ('a -> 'b) * ('a -> 'b)
  val fodd : (int -> int) * 'a -> int -> int
  val main : int
  val map : ('a -> 'b) -> 'a * 'a -> 'b * 'b
  val meven : int -> int
  val modd : int -> int
  val tie : (int -> int) * (int -> int)

  $ ../bin/interpret.exe manytests/typed/016lists.ml
  Running... 
  val append : 'a list -> 'a list -> 'a list
  val cartesian : 'a list -> 'b list -> ('a * 'b) list
  val concat : 'a list list -> 'a list
  val iter : ('a -> unit) -> 'a list -> unit
  val length : 'a list -> int
  val length_tail : 'a list -> int
  val main : int
  val map : ('a -> 'b) -> 'a list -> 'b list

  $ ../bin/interpret.exe manytests/do_not_type/001.ml
  Running... 
  Unbound_variable: "fac"

  $ ../bin/interpret.exe manytests/do_not_type/002if.ml
  Running... 
  Unification_failed: int # bool
  $ ../bin/interpret.exe manytests/do_not_type/003occurs.ml
  Running... 
  Occurs_check: 'c and 'c -> 'b
  $ ../bin/interpret.exe  manytests/do_not_type/004let_poly.ml
  Running... 
  Unification_failed: int # bool
  $ ../bin/interpret.exe manytests/do_not_type/015tuples.ml
  Running... 
  Not supported syntax
  $ ../bin/interpret.exe  manytests/do_not_type/099.ml    
  Running... 
  Not supported syntax
