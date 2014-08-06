(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2012     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(*i camlp4deps: "grammar/grammar.cma" i*)

open Util
open Locus
open Misctypes

DECLARE PLUGIN "coretactics"

TACTIC EXTEND reflexivity
  [ "reflexivity" ] -> [ Tactics.intros_reflexivity ]
END

TACTIC EXTEND assumption
  [ "assumption" ] -> [ Tactics.assumption ]
END

TACTIC EXTEND etransitivity
  [ "etransitivity" ] -> [ Tactics.intros_transitivity None ]
END

TACTIC EXTEND cut
  [ "cut" constr(c) ] -> [ Tactics.cut c ]
END

TACTIC EXTEND exact_no_check
  [ "exact_no_check" constr(c) ] -> [ Proofview.V82.tactic (Tactics.exact_no_check c) ]
END

TACTIC EXTEND vm_cast_no_check
  [ "vm_cast_no_check" constr(c) ] -> [ Proofview.V82.tactic (Tactics.vm_cast_no_check c) ]
END

TACTIC EXTEND casetype
  [ "casetype" constr(c) ] -> [ Tactics.case_type c ]
END

TACTIC EXTEND elimtype
  [ "elimtype" constr(c) ] -> [ Tactics.elim_type c ]
END

TACTIC EXTEND lapply
  [ "lapply" constr(c) ] -> [ Tactics.cut_and_apply c ]
END

TACTIC EXTEND transitivity
  [ "transitivity" constr(c) ] -> [ Tactics.intros_transitivity (Some c) ]
END

(** Left *)

TACTIC EXTEND left
  [ "left" ] -> [ Tactics.left_with_bindings false NoBindings ]
END

TACTIC EXTEND eleft
  [ "eleft" ] -> [ Tactics.left_with_bindings true NoBindings ]
END

TACTIC EXTEND left_with
  [ "left" "with" bindings(bl) ] -> [
    let { Evd.sigma = sigma ; it = bl } = bl in
    Tacticals.New.tclWITHHOLES false (Tactics.left_with_bindings false) sigma bl
  ]
END

TACTIC EXTEND eleft_with
  [ "eleft" "with" bindings(bl) ] -> [
    let { Evd.sigma = sigma ; it = bl } = bl in
    Tacticals.New.tclWITHHOLES true (Tactics.left_with_bindings true) sigma bl
  ]
END

(** Right *)

TACTIC EXTEND right
  [ "right" ] -> [ Tactics.right_with_bindings false NoBindings ]
END

TACTIC EXTEND eright
  [ "eright" ] -> [ Tactics.right_with_bindings true NoBindings ]
END

TACTIC EXTEND right_with
  [ "right" "with" bindings(bl) ] -> [
    let { Evd.sigma = sigma ; it = bl } = bl in
    Tacticals.New.tclWITHHOLES false (Tactics.right_with_bindings false) sigma bl
  ]
END

TACTIC EXTEND eright_with
  [ "eright" "with" bindings(bl) ] -> [
    let { Evd.sigma = sigma ; it = bl } = bl in
    Tacticals.New.tclWITHHOLES true (Tactics.right_with_bindings true) sigma bl
  ]
END

(** Constructor *)

TACTIC EXTEND constructor
  [ "constructor" ] -> [ Tactics.any_constructor false None ]
END

TACTIC EXTEND econstructor
  [ "econstructor" ] -> [ Tactics.any_constructor true None ]
END

(** Specialize *)

TACTIC EXTEND specialize
  [ "specialize" constr_with_bindings(c) ] -> [
    let { Evd.sigma = sigma; it = c } = c in
    let specialize c = Proofview.V82.tactic (Tactics.specialize c) in
    Tacticals.New.tclWITHHOLES false specialize sigma c
  ]
END

TACTIC EXTEND symmetry
  [ "symmetry" ] -> [ Tactics.intros_symmetry {onhyps=Some[];concl_occs=AllOccurrences} ]
END

(** Split *)

TACTIC EXTEND split
  [ "split" ] -> [ Tactics.split_with_bindings false [NoBindings] ]
END

TACTIC EXTEND esplit
  [ "esplit" ] -> [ Tactics.split_with_bindings true [NoBindings] ]
END

TACTIC EXTEND split_with
  [ "split" "with" bindings(bl) ] -> [
    let { Evd.sigma = sigma ; it = bl } = bl in
    Tacticals.New.tclWITHHOLES false (Tactics.split_with_bindings false) sigma [bl]
  ]
END

TACTIC EXTEND esplit_with
  [ "esplit" "with" bindings(bl) ] -> [
    let { Evd.sigma = sigma ; it = bl } = bl in
    Tacticals.New.tclWITHHOLES true (Tactics.split_with_bindings true) sigma [bl]
  ]
END

(** Intro *)

TACTIC EXTEND intros_until
  [ "intros" "until" quantified_hypothesis(h) ] -> [ Tactics.intros_until h ]
END
