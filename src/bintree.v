From Equations Require Import Equations.
From Coq Require Import ssreflect ssrbool ssrfun.
From mathcomp Require Import eqtype ssrnat seq prime.
From favssr Require Import prelude.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Inductive tree A := Leaf | Node of (tree A) & A & (tree A).

Section BasicFunctions.
Context {A B : Type}.

Fixpoint map_tree (f : A -> B) (t : tree A) : tree B :=
  if t is Node l x r
    then Node (map_tree f l) (f x) (map_tree f r)
  else @Leaf B.

Fixpoint inorder (t : tree A) : seq A :=
  if t is Node l x r
    then inorder l ++ [:: x] ++ inorder r
  else [::].

Fixpoint preorder (t : tree A) : seq A :=
  if t is Node l x r
    then x :: preorder l ++ preorder r
  else [::].

Fixpoint postorder (t : tree A) : seq A :=
  if t is Node l x r
    then postorder l ++ postorder r ++ [:: x]
  else [::].

Fixpoint size_tree (t : tree A) : nat :=
  if t is Node l _ r
    then size_tree l + size_tree r + 1
  else 0.

Fixpoint size1_tree (t : tree A) : nat :=
  if t is Node l _ r
    then size1_tree l + size1_tree r
  else 1.

Lemma size1_size t : size1_tree t = size_tree t + 1.
Proof.
elim: t=>//= l -> _ r ->.
by rewrite addnAC addnA.
Qed.

Fixpoint height (t : tree A) : nat :=
  if t is Node l _ r
    then maxn (height l) (height r) + 1
  else 0.

Fixpoint min_height (t : tree A) : nat :=
  if t is Node l _ r
    then minn (min_height l) (min_height r) + 1
  else 0.

Lemma h_leq t : height t <= size_tree t.
Proof.
elim: t=>//= l IHl _ r IHr; rewrite leq_add2r geq_max.
apply/andP; split.
- by apply/(leq_trans IHl)/leq_addr.
by apply/(leq_trans IHr)/leq_addl.
Qed.

Lemma mh_leq t : min_height t <= height t.
Proof.
elim: t=>//= l IHl _ r IHr; rewrite leq_add2r leq_max /minn.
by case: ifP=>H; rewrite ?IHl ?IHr // orbT.
Qed.

Lemma exp_mh_leq t : 2 ^ min_height t <= size1_tree t.
Proof.
elim: t=>//= l IHl _ r IHr.
rewrite expnD expn1 muln2 -addnn.
apply: (leq_trans (n := 2^ min_height l + 2^ min_height r)); last by apply: leq_add.
by apply: leq_add; rewrite leq_exp2l //; [apply: geq_minl | apply: geq_minr].
Qed.

Lemma exp_h_geq t : size1_tree t <= 2 ^ height t.
Proof.
elim: t=>//= l IHl _ r IHr.
rewrite expnD expn1 muln2 -addnn.
apply: (leq_trans (n := 2^ height l + 2^ height r)); first by apply: leq_add.
by apply: leq_add; rewrite leq_exp2l //; [apply: leq_maxl | apply: leq_maxr].
Qed.

Fixpoint subtrees (t : tree A) : seq (tree A) :=
  if t is Node l x r
    then Node l x r :: subtrees l ++ subtrees r
  else [:: @Leaf A].

(* Exercise 4.1 *)

Fixpoint inorder2 (t : tree A) (acc : seq A) : seq A := [::]. (* FIXME *)

Lemma inorder2_correct t xs : inorder2 t xs = inorder t ++ xs.
Proof.
Admitted.

End BasicFunctions.

Section EqTree.
Context {T : eqType}.

Fixpoint eqtree (t1 t2 : tree T) :=
  match t1, t2 with
  | Leaf, Leaf => true
  | Node l1 x1 r1, Node l2 x2 r2 => [&& x1 == x2, eqtree l1 l2 & eqtree r1 r2]
  | _, _ => false
  end.

Lemma eqtreeP : Equality.axiom eqtree.
Proof.
move; elim=> [|l1 IHl x1 r1 IHr] [|l2 x2 r2] /=; try by constructor.
have [<-/=|neqx] := x1 =P x2; last by apply: ReflectF; case.
apply: (iffP andP).
- by case=>/IHl->/IHr->.
by case=><-<-; split; [apply/IHl|apply/IHr].
Qed.

Canonical tree_eqMixin := EqMixin eqtreeP.
Canonical tree_eqType := Eval hnf in EqType (tree T) tree_eqMixin.

Lemma subtree_self (t : tree T) : t \in subtrees t.
Proof. by case: t=>//=l x r; rewrite inE eq_refl. Qed.

End EqTree.

Section CompleteTrees.
Context {A : Type}.

(* aka perfect *)

Fixpoint complete (t : tree A) : bool :=
  if t is Node l x r
    then [&& height l == height r, complete l & complete r]
  else true.

Lemma complete_mh_h t : complete t <-> min_height t == height t.
Proof.
elim: t=>//= l IHl _ r IHr; split.
- by case/and3P=>/eqP H /IHl /eqP -> /IHr /eqP ->; rewrite H minnn maxnn.
rewrite eqn_add2r /minn /maxn; case: ltnP=>H1; case: ltnP=>H2 /eqP H.
- by rewrite H ltnNge mh_leq in H1.
- rewrite H in H1; move: (leq_ltn_trans H2 H1).
  by rewrite ltnNge mh_leq.
- rewrite -H in H2; move: (leq_trans H2 H1).
  by rewrite ltnNge mh_leq.
rewrite H in H1; rewrite -H in H2.
have /IHl->: min_height l == height l by rewrite eq_sym eqn_leq H1 mh_leq.
have /[dup]: min_height r == height r by rewrite eq_sym eqn_leq H2 mh_leq.
by rewrite {1}H=>/eqP->/IHr->; rewrite eq_refl.
Qed.

Lemma complete_size1 t : complete t -> size1_tree t = 2^height t.
Proof.
elim: t=>//= l IHl _ r IHr /and3P [/eqP H /IHl -> /IHr ->].
by rewrite H maxnn addnn expnD expn1 muln2.
Qed.

Lemma ncomplete_size1 t : ~~ complete t -> size1_tree t < 2^height t.
Proof.
elim: t=>//= l IHl _ r IHr; rewrite !negb_and.
rewrite expnD expn1 muln2 -addnn.
case H: (_ == _)=>/=.
- case/orP=>//; move/eqP: H=>H.
  - move/IHl=>H2; rewrite -H maxnn.
    apply: (leq_trans (n:=2 ^ height l + size1_tree r)); first by rewrite ltn_add2r.
    by rewrite leq_add2l H exp_h_geq.
  move/IHr=>H2; rewrite H maxnn.
  apply: (leq_trans (n:=size1_tree l + 2 ^ height r)); first by rewrite ltn_add2l.
  by rewrite leq_add2r -H exp_h_geq.
move=>_; move/negbT: H; rewrite neq_ltn.
case/orP=>H; rewrite /maxn.
- rewrite H.
  apply: (leq_ltn_trans (n:=2 ^ height l + 2 ^ height r)).
  - by apply: leq_add; rewrite exp_h_geq.
  by rewrite ltn_add2r ltn_exp2l.
move: (H); rewrite ltnNge leq_eqVlt negb_or =>/andP [_ /negbTE ->].
apply: (leq_ltn_trans (n:=2 ^ height l + 2 ^ height r)).
- by apply: leq_add; rewrite exp_h_geq.
by rewrite ltn_add2l ltn_exp2l.
Qed.

Lemma ncomplete_mh_size1 t : ~~ complete t -> 2^min_height t < size1_tree t.
Proof.
elim: t=>//= l IHl _ r IHr; rewrite negb_and.
rewrite expnD expn1 muln2 -addnn.
case H: (_ && _)=>/=.
- rewrite orbF; case/andP: H=>/complete_mh_h/eqP H1 /complete_mh_h/eqP H2.
  rewrite neq_ltn; case/orP=>H; rewrite /minn.
  - rewrite H1 H2 H.
    apply: (leq_trans (n:=2 ^ height l + 2 ^ height r)).
    - by rewrite ltn_add2l ltn_exp2l.
    by apply: leq_add; rewrite -?H1 -?H2 exp_mh_leq.
  move: (H); rewrite ltnNge leq_eqVlt negb_or H1 H2 =>/andP [_ /negbTE ->].
  apply: (leq_trans (n:=2 ^ height l + 2 ^ height r)).
  - by rewrite ltn_add2r ltn_exp2l.
  by apply: leq_add; rewrite -?H1 -?H2 exp_mh_leq.
move=>_; move/negbT: H; rewrite negb_and; case/orP.
- move/IHl=>H.
  apply: (leq_ltn_trans (n:=2 ^ min_height l + size1_tree r)).
  - apply: leq_add; first by rewrite leq_exp2l // geq_minl.
    apply: (leq_trans _ (exp_mh_leq r)).
    by rewrite leq_exp2l // geq_minr.
  by rewrite ltn_add2r.
move/IHr=>H.
apply: (leq_ltn_trans (n:=size1_tree l + 2 ^ min_height r)).
- apply: leq_add; last by rewrite leq_exp2l // geq_minr.
  apply: (leq_trans _ (exp_mh_leq l)).
  by rewrite leq_exp2l // geq_minl.
by rewrite ltn_add2l.
Qed.

Corollary completeE t : complete t <-> size1_tree t = 2^height t.
Proof.
split; first by exact: complete_size1.
move=>E; move/contraR: (@ncomplete_size1 t); apply.
by rewrite E ltnn.
Qed.

(* Exercise 4.2 *)

Fixpoint mcs (t : tree A) : tree A := t. (* FIXME *)

Lemma complete_mcs t : complete (mcs t).
Proof.
Admitted.

End CompleteTrees.

Section CompleteTreesEq.
Context {T : eqType}.

Lemma subtree_mcs (t : tree T) : mcs t \in subtrees t.
Proof.
Admitted.

Lemma mcs_maximal (t u : tree T) :
  u \in subtrees t -> complete u ->
  height u <= height (mcs t).
Proof.
Admitted.

End CompleteTreesEq.

Section AlmostCompleteTrees.
Context {A : Type}.

Definition acomplete (t : tree A) : bool :=
  height t - min_height t <= 1.

Lemma acomplete_h1 t :
  acomplete t -> ~~ complete t ->
  height t = (min_height t).+1.
Proof.
rewrite /acomplete leq_eqVlt; case/orP.
- rewrite -(eqn_add2r (min_height t)) addnBAC; last by exact: mh_leq.
  by rewrite addnK add1n=>/eqP ->.
rewrite ltnS leqn0 subn_eq0=>E.
suff : min_height t == height t by move/complete_mh_h=>->.
by rewrite eqn_leq E mh_leq.
Qed.

Lemma acomplete_minimal (s t : tree A) :
  acomplete s -> size_tree s <= size_tree t ->
  height s <= height t.
Proof.
case/boolP: (complete s).
- move/completeE=>H _ S; rewrite -(leq_exp2l (m:=2)) // -H.
  apply/leq_trans/(exp_h_geq t).
  by rewrite !size1_size leq_add2r.
move=>/[dup] H /[swap] /acomplete_h1 /[apply] -> S.
rewrite -(ltn_exp2l (m:=2)) //.
apply: (leq_trans (ncomplete_mh_size1 H)).
apply/leq_trans/(exp_h_geq t).
by rewrite !size1_size leq_add2r.
Qed.

Lemma acomplete_h t : acomplete t -> height t = log2n (size1_tree t).
Proof.
case/boolP: (complete t).
- by move/completeE=>->_; rewrite exp2nK.
move=>/[dup] H /[swap] /acomplete_h1 /[apply] E; rewrite E; symmetry.
apply: log2n_eq; rewrite (ncomplete_mh_size1 H) /= -E.
by exact: exp_h_geq.
Qed.

Lemma acomplete_mh t : acomplete t -> min_height t = trunc_log 2 (size1_tree t).
Proof.
case/boolP: (complete t).
- move/[dup]/complete_mh_h/eqP=>->.
  by move/completeE =>->_; rewrite trunc_expnK.
move=>/[dup] H /[swap] /acomplete_h1 /[apply] E; symmetry.
apply: trunc_log_eq=>//; rewrite exp_mh_leq /=.
by apply: (leq_trans (ncomplete_size1 H)); rewrite E.
Qed.

Variable x0 : A.

Equations? bal (n : nat) (xs : seq A) : tree A * seq A by wf n lt :=
bal n xs with inspect (n == 0) := {
  | true eqn: Hn => (@Leaf A, xs)
  | false eqn: Hn with inspect (n./2) := {
    | m eqn: Hm => let '(l, ys) := bal m xs in
                   let '(r, zs) := bal (n-1-m) (behead ys) in
                   (Node l (head x0 ys) r, zs)
  }
}.
Proof.
all: apply: ssrnat.ltP; move/negbT: Hn; rewrite -lt0n=>Hn.
- by apply: half_lt.
rewrite subnAC half_subn.
apply/leq_trans/uphalf_le.
by rewrite subn1 ltn_predL uphalf_gt0.
Defined.

Definition bal_list n xs := (bal n xs).1.

Definition balance_list xs := bal_list (size xs) xs.

Definition bal_tree n t := bal_list n (inorder t).

Definition balance_tree t := bal_tree (size_tree t) t.

End AlmostCompleteTrees.