(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(* Created by Benjamin Grégoire out of environ.ml for better
   modularity in the design of the bytecode virtual evaluation
   machine, Dec 2005 *)
(* Bug fix by Jean-Marc Notin *)

(* This file defines the type of kernel environments *)

open Util
open Names
open Term
open Declarations
open Context.Named.Declaration

(* The type of environments. *)

(* The key attached to each constant is used by the VM to retrieve previous *)
(* evaluations of the constant. It is essentially an index in the symbols table *)
(* used by the VM. *)
type key = int CEphemeron.key option ref 

(** Linking information for the native compiler. *)

type link_info =
  | Linked of string
  | LinkedInteractive of string
  | NotLinked

type constant_key = constant_body * (link_info ref * key)

type mind_key = mutual_inductive_body * link_info ref

type globals = {
  env_constants : constant_key Cmap_env.t;
  env_inductives : mind_key Mindmap_env.t;
  env_modules : module_body MPmap.t;
  env_modtypes : module_type_body MPmap.t}

type stratification = {
  env_universes : UGraph.t;
  env_engagement : engagement
}

type val_kind =
    | VKvalue of (values * Id.Set.t) CEphemeron.key
    | VKnone

type lazy_val = val_kind ref

let force_lazy_val vk = match !vk with
| VKnone -> None
| VKvalue v -> try Some (CEphemeron.get v) with CEphemeron.InvalidKey -> None

let dummy_lazy_val () = ref VKnone
let build_lazy_val vk key = vk := VKvalue (CEphemeron.create key)

type named_vals = (Id.t * lazy_val) list

type named_context_val = {
  env_named_ctx : Context.Named.t;
  env_named_val : named_vals;
}

type env = {
  env_globals       : globals;
  env_named_context : named_context_val;
  env_rel_context   : Context.Rel.t;
  env_rel_val       : lazy_val list;
  env_nb_rel        : int;
  env_stratification : stratification;
  env_typing_flags  : typing_flags;
  env_conv_oracle   : Conv_oracle.oracle;
  retroknowledge : Retroknowledge.retroknowledge;
  indirect_pterms : Opaqueproof.opaquetab;
}

let empty_named_context_val = {
  env_named_ctx = [];
  env_named_val = [];
}

let empty_env = {
  env_globals = {
    env_constants = Cmap_env.empty;
    env_inductives = Mindmap_env.empty;
    env_modules = MPmap.empty;
    env_modtypes = MPmap.empty};
  env_named_context = empty_named_context_val;
  env_rel_context = Context.Rel.empty;
  env_rel_val = [];
  env_nb_rel = 0;
  env_stratification = {
    env_universes = UGraph.initial_universes;
    env_engagement = PredicativeSet };
  env_typing_flags = Declareops.safe_flags;
  env_conv_oracle = Conv_oracle.empty;
  retroknowledge = Retroknowledge.initial_retroknowledge;
  indirect_pterms = Opaqueproof.empty_opaquetab }


(* Rel context *)

let nb_rel env = env.env_nb_rel

let push_rel d env =
  let rval = ref VKnone in
    { env with
      env_rel_context = Context.Rel.add d env.env_rel_context;
      env_rel_val = rval :: env.env_rel_val;
      env_nb_rel = env.env_nb_rel + 1 }

let lookup_rel_val n env =
  try List.nth env.env_rel_val (n - 1)
  with Failure _ -> raise Not_found

let env_of_rel n env =
  { env with
    env_rel_context = Util.List.skipn n env.env_rel_context;
    env_rel_val = Util.List.skipn n env.env_rel_val;
    env_nb_rel = env.env_nb_rel - n
  }

(* Named context *)

let push_named_context_val_val d rval ctxt =
  {
    env_named_ctx = Context.Named.add d ctxt.env_named_ctx;
    env_named_val = (get_id d, rval) :: ctxt.env_named_val;
  }

let push_named_context_val d ctxt =
  push_named_context_val_val d (ref VKnone) ctxt

let match_named_context_val c = match c.env_named_ctx, c.env_named_val with
| [], [] -> None
| decl :: ctx, (_, v) :: vls ->
  let cval = { env_named_ctx = ctx; env_named_val = vls } in
  Some (decl, v, cval)
| _ -> assert false

let push_named d env =
(*  if not (env.env_rel_context = []) then raise (ASSERT env.env_rel_context);
  assert (env.env_rel_context = []); *)
  { env_globals = env.env_globals;
    env_named_context = push_named_context_val d env.env_named_context;
    env_rel_context = env.env_rel_context;
    env_rel_val = env.env_rel_val;
    env_nb_rel = env.env_nb_rel;
    env_stratification = env.env_stratification;
    env_typing_flags = env.env_typing_flags;
    env_conv_oracle = env.env_conv_oracle;
    retroknowledge = env.retroknowledge;
    indirect_pterms = env.indirect_pterms;
  }

let lookup_named_val id env =
  snd(List.find (fun (id',_) -> Id.equal id id') env.env_named_context.env_named_val)

(* Warning all the names should be different *)
let env_of_named id env = env

(* Global constants *)

let lookup_constant_key kn env =
  Cmap_env.find kn env.env_globals.env_constants

let lookup_constant kn env =
  fst (Cmap_env.find kn env.env_globals.env_constants)

(* Mutual Inductives *)
let lookup_mind kn env =
  fst (Mindmap_env.find kn env.env_globals.env_inductives)

let lookup_mind_key kn env =
  Mindmap_env.find kn env.env_globals.env_inductives
