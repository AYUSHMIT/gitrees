(** Logical relation for adequacy for the IO lang *)
From Equations Require Import Equations.
From gitrees Require Import gitree.
From gitrees.input_lang_callcc Require Import lang interp.
Require Import gitrees.lang_generic_sem.
Require Import Binding.Lib Binding.Set Binding.Env.

Section logrel.
  Context {sz : nat}.
  Variable (rs : gReifiers sz).
  Context {subR : subReifier reify_io rs}.
  Notation F := (gReifiers_ops rs).
  Notation IT := (IT F natO).
  Notation ITV := (ITV F natO).
  Context `{!invGS Σ, !stateG rs natO Σ}.
  Notation iProp := (iProp Σ).
  Notation restO := (gState_rest sR_idx rs ♯ IT).

  Canonical Structure exprO S := leibnizO (expr S).
  Canonical Structure valO S := leibnizO (val S).
  Canonical Structure ectxO S := leibnizO (ectx S).

  Notation "'WP' α {{ β , Φ } }" := (wp rs α notStuck ⊤ (λ β, Φ))
    (at level 20, α, Φ at level 200,
     format "'WP'  α  {{  β ,  Φ  } }") : bi_scope.

  Notation "'WP' α {{ Φ } }" := (wp rs α notStuck ⊤ Φ)
    (at level 20, α, Φ at level 200,
     format "'WP'  α  {{  Φ  } }") : bi_scope.

  Definition logrel_nat {S} (βv : ITV) (v : val S) : iProp :=
    (∃ n, βv ≡ RetV n ∧ ⌜v = LitV n⌝)%I.

  Definition obs_ref {S} (α : IT) (e : expr S) : iProp :=
    (∀ (σ : stateO),
        has_substate σ -∗
        WP α {{ βv, ∃ m v σ', ⌜prim_steps e σ (Val v) σ' m⌝
                              ∗ logrel_nat βv v ∗ has_substate σ' }})%I.

  Definition HOM : ofe := @sigO (IT -n> IT) IT_hom.

  Global Instance HOM_hom (κ : HOM) : IT_hom (`κ).
  Proof.
    apply (proj2_sig κ).
  Qed.

  Definition logrel_ectx {S} V (κ : HOM) (K : ectx S) : iProp :=
    (□ ∀ (βv : ITV) (v : val S), V βv v -∗ obs_ref (`κ (IT_of_V βv)) (fill K (Val v)))%I.

  Definition logrel_expr {S} V (α : IT) (e : expr S) : iProp :=
    (∀ (κ : HOM) (K : ectx S),
       logrel_ectx V κ K -∗ obs_ref (`κ α) (fill K e))%I.

  Definition logrel_arr {S} V1 V2 (βv : ITV) (vf : val S) : iProp :=
    (∃ f, IT_of_V βv ≡ Fun f ∧ □ ∀ αv v, V1 αv v -∗
      logrel_expr V2 (APP' (Fun f) (IT_of_V αv)) (App (Val vf) (Val v)))%I.

  Global Instance denot_cont_ne (κ : IT -n> IT) :
    NonExpansive (λ x : IT, Tau (laterO_map κ (Next x))).
  Proof.
    solve_proper.
  Qed.

  Definition logrel_cont {S} V (βv : ITV) (v : val S) : iProp :=
    (∃ (κ : HOM) K, (IT_of_V βv) ≡ (Fun (Next (λne x, Tau (laterO_map (`κ) (Next x)))))
                            ∧ ⌜v = ContV K⌝
                            ∧ □ logrel_ectx V κ K)%I.

  Fixpoint logrel_val {S} (τ : ty) : ITV → (val S) → iProp
    := match τ with
       | Tnat => logrel_nat
       | Tarr τ1 τ2 => logrel_arr (logrel_val τ1) (logrel_val τ2)
       | Tcont τ => logrel_cont (logrel_val τ)
       end.

  Definition logrel {S} (τ : ty) : IT → (expr S) → iProp
    := logrel_expr (logrel_val τ).

  #[export] Instance obs_ref_ne {S} :
    NonExpansive2 (@obs_ref S).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_expr_ne {S} (V : ITV → val S → iProp) :
    NonExpansive2 V → NonExpansive2 (logrel_expr V).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_nat_ne {S} : NonExpansive2 (@logrel_nat S).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_val_ne {S} (τ : ty) : NonExpansive2 (@logrel_val S τ).
  Proof.
    induction τ; simpl; solve_proper.
  Qed.

  #[export] Instance logrel_ectx_ne {S} (V : ITV → val S → iProp) :
    NonExpansive2 V → NonExpansive2 (logrel_ectx V).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_arr_ne {S} (V1 V2 : ITV → val S → iProp) :
    NonExpansive2 V1 -> NonExpansive2 V2 → NonExpansive2 (logrel_arr V1 V2).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_cont_ne {S} (V : ITV → val S → iProp) :
    NonExpansive2 V -> NonExpansive2 (logrel_cont V).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance obs_ref_proper {S} :
    Proper ((≡) ==> (≡) ==> (≡)) (@obs_ref S).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_expr_proper {S} (V : ITV → val S → iProp) :
    Proper ((≡) ==> (≡) ==> (≡)) V → Proper ((≡) ==> (≡) ==> (≡)) (logrel_expr V).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_nat_proper {S} : Proper ((≡) ==> (≡) ==> (≡)) (@logrel_nat S).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_val_proper {S} (τ : ty) : Proper ((≡) ==> (≡) ==> (≡)) (@logrel_val S τ).
  Proof.
    induction τ; simpl; solve_proper.
  Qed.

  #[export] Instance logrel_ectx_proper {S} (V : ITV → val S → iProp) :
    Proper ((≡) ==> (≡) ==> (≡)) V → Proper ((≡) ==> (≡) ==> (≡)) (logrel_ectx V).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_arr_proper {S} (V1 V2 : ITV → val S → iProp) :
    Proper ((≡) ==> (≡) ==> (≡)) V1 -> Proper ((≡) ==> (≡) ==> (≡)) V2 → Proper ((≡) ==> (≡) ==> (≡)) (logrel_arr V1 V2).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_cont_proper {S} (V : ITV → val S → iProp) :
    Proper ((≡) ==> (≡) ==> (≡)) V -> Proper ((≡) ==> (≡) ==> (≡)) (logrel_cont V).
  Proof.
    solve_proper.
  Qed.

  #[export] Instance logrel_val_persistent {S} (τ : ty) α v :
    Persistent (@logrel_val S τ α v).
  Proof.
    revert α v. induction τ=> α v; simpl.
    - unfold logrel_nat. apply _.
    - unfold logrel_arr. apply _.
    - unfold logrel_cont. apply _.
  Qed.

  #[export] Instance logrel_ectx_persistent {S} V κ K :
    Persistent (@logrel_ectx S V κ K).
  Proof.
    apply _.
  Qed.

  Lemma logrel_of_val {S} τ αv (v : val S) :
    logrel_val τ αv v -∗ logrel τ (IT_of_V αv) (Val v).
  Proof.
    iIntros "H1". iIntros (κ K) "HK".
    iIntros (σ) "Hs".
    by iApply ("HK" $! αv v with "[$H1] [$Hs]").
  Qed.

  Lemma HOM_ccompose (f g : HOM)
    : ∀ α, `f (`g α) = (`f ◎ `g) α.
  Proof.
    intro; reflexivity.
  Qed.

  Lemma logrel_bind {S} (f : HOM) (K : ectx S)
    e α τ1 :
    ⊢ logrel τ1 α e -∗
      logrel_ectx (logrel_val τ1) f K -∗
      obs_ref (`f α) (fill K e).
  Proof.
    iIntros "H1 #H2".
    iLöb as "IH" forall (α e).
    iIntros (σ) "Hs".
    iApply (wp_wand with "[H1 H2 Hs] []"); first iApply ("H1" with "[H2] [$Hs]").
    - iIntros (βv v). iModIntro.
      iIntros "#Hv".
      by iApply "H2".
    - iIntros (βv).
      iIntros "?".
      iModIntro.
      iFrame.
  Qed.

  Definition ssubst2_valid {S : Set}
    (Γ : S -> ty)
    (ss : @interp_scope F natO _ S)
    (γ : S [⇒] ∅)
    : iProp :=
    (∀ x, □ logrel (Γ x) (ss x) (γ x))%I.

  Definition logrel_valid {S : Set}
    (Γ : S -> ty)
    (e : expr S)
    (α : @interp_scope F natO _ S -n> IT)
    (τ : ty) : iProp :=
    (□ ∀ (ss : @interp_scope F natO _ S)
       (γ : S [⇒] ∅),
       ssubst2_valid Γ ss γ → logrel τ (α ss) (bind γ e))%I.

  Lemma compat_var {S : Set} (Γ : S -> ty) (x : S) :
    ⊢ logrel_valid Γ (Var x) (interp_var x) (Γ x).
  Proof.
    iModIntro.
    iIntros (ss γ) "Hss".
    iApply "Hss".
  Qed.

  Lemma logrel_head_step_pure_ectx {S} n K (κ : HOM) (e' e : expr S) α V :
    (∀ σ K, head_step e σ e' σ K (n, 0)) →
    ⊢ logrel_expr V (`κ α) (fill K e') -∗ logrel_expr V (`κ α) (fill K e).
  Proof.
    intros Hpure.
    iIntros "H".
    iIntros (κ' K') "#HK'".
    iIntros (σ) "Hs".
    iSpecialize ("H" with "HK'").
    iSpecialize ("H" with "Hs").
    iApply (wp_wand with "H").
    iIntros (βv). iDestruct 1 as ([m m'] v σ' Hsteps) "[H2 Hs]".
    iExists ((Nat.add n m),m'),v,σ'. iFrame "H2 Hs".
    iPureIntro.
    eapply (prim_steps_app (n, 0) (m, m')); eauto.
    eapply prim_step_steps.
    rewrite !fill_comp.
    eapply Ectx_step; last apply Hpure; done.
  Qed.

  Lemma compat_recV {S : Set} (Γ : S -> ty) (e : expr (inc (inc S))) τ1 τ2 α :
    ⊢ □ logrel_valid ((Γ ▹ (Tarr τ1 τ2) ▹ τ1)) e α τ2 -∗
      logrel_valid Γ (Val $ RecV e) (interp_rec rs α) (Tarr τ1 τ2).
  Proof.
    iIntros "#H".
    iModIntro.
    iIntros (ss γ) "#Hss".
    pose (env := ss). fold env.
    pose (f := (ir_unf rs α env)).
    iAssert (interp_rec rs α env ≡ IT_of_V $ FunV (Next f))%I as "Hf".
    { iPureIntro. apply interp_rec_unfold. }
    iRewrite "Hf".
    Opaque IT_of_V.
    iApply logrel_of_val; term_simpl.
    iExists _. simpl.
    iSplit.
    { Transparent IT_of_V. done. }
    iModIntro.
    iLöb as "IH". iSimpl.
    iIntros (αv v) "#Hw".
    rewrite APP_APP'_ITV.
    rewrite APP_Fun.
    rewrite laterO_map_Next.
    rewrite -Tick_eq.
    iIntros (κ K) "#HK".
    iIntros (σ) "Hs".
    rewrite hom_tick.
    iApply wp_tick.
    iNext.
    unfold f.
    Opaque extend_scope.
    Opaque IT_of_V.
    simpl.
    pose (ss' := (extend_scope (extend_scope env (interp_rec rs α env)) (IT_of_V αv))).
    pose (γ' := ((mk_subst (Val (rec bind ((γ ↑) ↑)%bind e)%syn)) ∘ ((mk_subst (shift (Val v))) ∘ ((γ ↑) ↑)%bind))%bind : inc (inc S) [⇒] ∅).
    iSpecialize ("H" $! ss' γ' with "[]"); last first.
    - iSpecialize ("H" $! κ K with "HK").
      unfold ss'.
      iSpecialize ("H" $! σ with "Hs").
      iApply (wp_wand with "[$H] []").
      iIntros (v') "(%m & %v'' & %σ'' & %Hstep & H)".
      destruct m as [m m'].
      iModIntro.
      iExists ((Nat.add 1 m), m'), v'', σ''. iFrame "H".
      iPureIntro.
      eapply (prim_steps_app (1, 0) (m, m')); eauto.
      term_simpl.
      eapply prim_step_steps.
      eapply Ectx_step; [reflexivity | reflexivity |].
      subst γ'.
      rewrite -!bind_bind_comp'.
      econstructor.
    - Transparent extend_scope.
      iIntros (x'); destruct x' as [| [| x']].
      + term_simpl.
        iModIntro.
        by iApply logrel_of_val.
      + term_simpl.
        iModIntro.
        iRewrite "Hf".
        iIntros (κ' K') "#HK'".
        iApply "HK'".
        simpl.
        unfold logrel_arr.
        _iExists (Next (ir_unf rs α env)).
        iSplit; first done.
        iModIntro.
        iApply "IH".
      + iModIntro.
        subst γ'.
        term_simpl.
        iApply "Hss".
  Qed.

  Program Definition IFSCtx_HOM α β : HOM := exist _ (λne x, IFSCtx α β x) _.
  Next Obligation.
    intros; simpl.
    apply _.
  Qed.

  Program Definition HOM_compose (f g : HOM) : HOM := exist _ (`f ◎ `g) _.
  Next Obligation.
    intros f g; simpl.
    apply _.
  Qed.

  Lemma compat_if {S : Set} (Γ : S -> ty) (e0 e1 e2 : expr S) α0 α1 α2 τ :
    ⊢ logrel_valid Γ e0 α0  Tnat -∗
      logrel_valid Γ e1 α1 τ -∗
      logrel_valid Γ e2 α2 τ -∗
      logrel_valid Γ (If e0 e1 e2) (interp_if rs α0 α1 α2) τ.
  Proof.
    iIntros "#H0 #H1 #H2".
    iModIntro.
    iIntros (ss γ) "#Hss".
    simpl.
    pose (κ' := (IFSCtx_HOM (α1 ss) (α2 ss))).
    assert ((IF (α0 ss) (α1 ss) (α2 ss)) = ((`κ') (α0 ss))) as ->.
    { reflexivity. }
    term_simpl.
    iIntros (κ K) "#HK".
    assert ((`κ) ((IFSCtx (α1 ss) (α2 ss)) (α0 ss)) = ((`κ) ◎ (`κ')) (α0 ss)) as ->.
    { reflexivity. }
    pose (sss := (HOM_compose κ κ')).
    assert ((`κ ◎ `κ') = (`sss)) as ->.
    { reflexivity. }
    assert (fill K (if bind γ e0 then bind γ e1 else bind γ e2)%syn = fill (ectx_compose K (IfK EmptyK (bind γ e1) (bind γ e2))) (bind γ e0)) as ->.
    { rewrite -fill_comp.
      reflexivity.
    }
    iApply (logrel_bind with "[H0] [H1 H2]").
    - by iApply "H0".
    - iIntros (βv v). iModIntro. iIntros "#HV".
      term_simpl.
      unfold logrel_nat.
      iDestruct "HV" as "(%n & #Hn & ->)".
      iRewrite "Hn".
      destruct (decide (0 < n)).
      + rewrite -fill_comp.
        simpl.
        unfold IFSCtx.
        rewrite IF_True//.
        iSpecialize ("H1" with "Hss").
        term_simpl.
        iSpecialize ("H1" $! κ K with "HK").
        iIntros (σ) "Hσ".
        iSpecialize ("H1" $! σ with "Hσ").
        iApply (wp_wand with "[$H1] []").
        iIntros (v) "(%m & %w & %σ' & %Hstep & H & G)".
        iModIntro.
        destruct m as [m m'].
        iExists (m, m'), w, σ'. iFrame "H G".
        iPureIntro.
        eapply (prim_steps_app (0, 0) (m, m')); eauto.
        eapply prim_step_steps.
        eapply Ectx_step; [reflexivity | reflexivity |].
        apply IfTrueS; done.
      + rewrite -fill_comp.
        simpl.
        unfold IFSCtx.
        rewrite IF_False//; last lia.
        iSpecialize ("H2" with "Hss").
        term_simpl.
        iSpecialize ("H2" $! κ K with "HK").
        iIntros (σ) "Hσ".
        iSpecialize ("H2" $! σ with "Hσ").
        iApply (wp_wand with "[$H2] []").
        iIntros (v) "(%m & %w & %σ' & %Hstep & H & G)".
        iModIntro.
        destruct m as [m m'].
        iExists (m, m'), w, σ'. iFrame "H G".
        iPureIntro.
        eapply (prim_steps_app (0, 0) (m, m')); eauto.
        eapply prim_step_steps.
        eapply Ectx_step; [reflexivity | reflexivity |].
        apply IfFalseS.
        lia.
  Qed.

  (* Lemma compat_app {S} Γ (e1 e2 : expr S) τ1 τ2 α1 α2 : *)
  (* ⊢ logrel_valid Γ e1 α1 (Tarr τ1 τ2) -∗ *)
  (*   logrel_valid Γ e2 α2 τ1 -∗ *)
  (*   logrel_valid Γ (App e1 e2) (interp_app rs α1 α2) τ2. *)
  (* Proof. *)
  (*   iIntros "H1 H2".  iIntros (ss) "#Hss". *)
  (*   iSpecialize ("H1" with "Hss"). *)
  (*   iSpecialize ("H2" with "Hss"). *)
  (*   pose (s := (subs_of_subs2 ss)). fold s. *)
  (*   pose (env := its_of_subs2 ss). fold env. *)
  (*   simp subst_expr. simpl. *)
  (*   iApply (logrel_bind (AppRSCtx (α1 env)) [AppRCtx (subst_expr e1 s)] with "H2"). *)
  (*   iIntros (v2 β2) "H2". iSimpl. *)
  (*   iApply (logrel_bind (AppLSCtx (IT_of_V β2)) [AppLCtx v2] with "H1"). *)
  (*   iIntros (v1 β1) "H1". simpl. *)
  (*   iDestruct "H1" as (f) "[Hα H1]". *)
  (*   simpl. *)
  (*   unfold AppLSCtx. iRewrite "Hα". (** XXX why doesn't simpl work here? *) *)
  (*   iApply ("H1" with "H2"). *)
  (* Qed. *)

  (* Lemma compat_input {S} Γ : *)
  (*   ⊢ logrel_valid Γ (Input : expr S) (interp_input rs) Tnat. *)
  (* Proof. *)
  (*   iIntros (ss) "Hss". *)
  (*   iIntros (σ) "Hs". *)
  (*   destruct (update_input σ) as [n σ'] eqn:Hinp. *)
  (*   iApply (wp_input with "Hs []"); first eauto. *)
  (*   iNext. iIntros "Hlc Hs". *)
  (*   iApply wp_val. *)
  (*   iExists (1,1),(Lit n),σ'. *)
  (*   iFrame "Hs". iModIntro. iSplit. *)
  (*   { iPureIntro. *)
  (*     simp subst_expr. *)
  (*     apply prim_step_steps. *)
  (*     apply (Ectx_step' []). *)
  (*     by constructor. } *)
  (*   iExists n. eauto. *)
  (* Qed. *)
  (* Lemma compat_output {S} Γ (e: expr S) α : *)
  (*   ⊢ logrel_valid Γ e α Tnat -∗ *)
  (*     logrel_valid Γ (Output e) (interp_output rs α) Tnat. *)
  (* Proof. *)
  (*   iIntros "H1". *)
  (*   iIntros (ss) "Hss". *)
  (*   iSpecialize ("H1" with "Hss"). *)
  (*   pose (s := (subs_of_subs2 ss)). fold s. *)
  (*   pose (env := its_of_subs2 ss). fold env. *)
  (*   simp subst_expr. simpl. *)
  (*   iApply (logrel_bind (get_ret _) [OutputCtx] with "H1"). *)
  (*   iIntros (v βv). *)
  (*   iDestruct 1 as (m) "[Hb ->]". *)
  (*   iRewrite "Hb". simpl. *)
  (*   iIntros (σ) "Hs". *)
  (*   rewrite get_ret_ret. *)
  (*   iApply (wp_output with "Hs []"); first done. *)
  (*   iNext. iIntros "Hlc Hs". *)
  (*   iExists (1,1),(Lit 0),_. *)
  (*   iFrame "Hs". iSplit. *)
  (*   { iPureIntro. *)
  (*     apply prim_step_steps. *)
  (*     apply (Ectx_step' []). *)
  (*     by constructor. } *)
  (*   iExists 0. eauto. *)
  (* Qed. *)

  (* Lemma compat_natop {S} (Γ : tyctx S) e1 e2 α1 α2 op : *)
  (*   ⊢ logrel_valid Γ e1 α1 Tnat -∗ *)
  (*     logrel_valid Γ e2 α2 Tnat -∗ *)
  (*     logrel_valid Γ (NatOp op e1 e2) (interp_natop rs op α1 α2) Tnat. *)
  (* Proof. *)
  (*   iIntros "H1 H2".  iIntros (ss) "#Hss". *)
  (*   iSpecialize ("H1" with "Hss"). *)
  (*   iSpecialize ("H2" with "Hss"). *)
  (*   pose (s := (subs_of_subs2 ss)). fold s. *)
  (*   pose (env := its_of_subs2 ss). fold env. *)
  (*   simp subst_expr. simpl. *)
  (*   iApply (logrel_bind (NatOpRSCtx (do_natop op) (α1 env)) [NatOpRCtx op (subst_expr e1 s)] with "H2"). *)
  (*   iIntros (v2 β2) "H2". iSimpl. *)
  (*   iApply (logrel_bind (NatOpLSCtx (do_natop op) (IT_of_V β2)) [NatOpLCtx op v2] with "H1"). *)
  (*   iIntros (v1 β1) "H1". simpl. *)
  (*   iDestruct "H1" as (n1) "[Hn1 ->]". *)
  (*   iDestruct "H2" as (n2) "[Hn2 ->]". *)
  (*   unfold NatOpLSCtx. *)
  (*   iAssert ((NATOP (do_natop op) (IT_of_V β1) (IT_of_V β2)) ≡ Ret (do_natop op n1 n2))%I with "[Hn1 Hn2]" as "Hr". *)
  (*   { iRewrite "Hn1". simpl. *)
  (*     iRewrite "Hn2". simpl. *)
  (*     iPureIntro. *)
  (*     by rewrite NATOP_Ret. } *)
  (*   iApply (logrel_step_pure (Val (Lit (do_natop op n1 n2)))). *)
  (*   { intro. apply (Ectx_step' []). constructor. *)
  (*     destruct op; simpl; eauto. } *)
  (*   iRewrite "Hr". *)
  (*   iApply (logrel_of_val (RetV $ do_natop op n1 n2)). *)
  (*   iExists _. iSplit; eauto. *)
  (* Qed. *)

  (* TODO: boring cases + callcc + throw *)
  Lemma fundamental {S : Set} (Γ : S -> ty) τ e :
    typed Γ e τ → ⊢ logrel_valid Γ e (interp_expr rs e) τ
  with fundamental_val {S : Set} (Γ : S -> ty) τ v :
    typed_val Γ v τ → ⊢ logrel_valid Γ (Val v) (interp_val rs v) τ.
  Proof.
  Admitted.
  (* - induction 1; simpl. *)
  (*   + by apply fundamental_val. *)
  (*   + by apply compat_var. *)
  (*   + iApply compat_rec. iApply IHtyped. *)
  (*   + iApply compat_app. *)
  (*     ++ iApply IHtyped1. *)
  (*     ++ iApply IHtyped2. *)
  (*   + iApply compat_natop. *)
  (*     ++ iApply IHtyped1. *)
  (*     ++ iApply IHtyped2. *)
  (*   + iApply compat_if. *)
  (*     ++ iApply IHtyped1. *)
  (*     ++ iApply IHtyped2. *)
  (*     ++ iApply IHtyped3. *)
  (*   + iApply compat_input. *)
  (*   + iApply compat_output. *)
  (*     iApply IHtyped. *)
  (* - induction 1; simpl. *)
  (*   + iIntros (ss) "Hss". simp subst_expr. simpl. *)
  (*     iApply (logrel_of_val (RetV n)). iExists n. eauto. *)
  (*   + iApply compat_recV. by iApply fundamental. *)
  (* Qed. *)

End logrel.

Definition κ {S} {E} : ITV E natO → val S :=  λ x,
    match x with
    | core.RetV n => LitV n
    | _ => LitV 0
    end.
Lemma κ_Ret {S} {E} n : κ ((RetV n) : ITV E natO) = (LitV n : val S).
Proof.
  Transparent RetV. unfold RetV. simpl. done. Opaque RetV.
Qed.
Definition rs : gReifiers 1 := gReifiers_cons reify_io gReifiers_nil.

Require Import gitrees.gitree.greifiers.

Lemma logrel_nat_adequacy  Σ `{!invGpreS Σ}`{!statePreG rs natO Σ} {S} (α : IT (gReifiers_ops rs) natO) (e : expr S) n σ σ' k :
  (∀ `{H1 : !invGS Σ} `{H2: !stateG rs natO Σ},
      (True ⊢ logrel rs Tnat α e)%I) →
  ssteps (gReifiers_sReifier rs) α (σ,()) (Ret n) σ' k → ∃ m σ', prim_steps e σ (Val $ LitV n) σ' m.
Proof.
  intros Hlog Hst.
  pose (ϕ := λ (βv : ITV (gReifiers_ops rs) natO),
          ∃ m σ', prim_steps e σ (Val $ κ βv) σ' m).
  cut (ϕ (RetV n)).
  { destruct 1 as ( m' & σ2 & Hm).
    exists m', σ2. revert Hm. by rewrite κ_Ret. }
  eapply (wp_adequacy 0); eauto.
  intros Hinv1 Hst1.
  pose (Φ := (λ (βv : ITV (gReifiers_ops rs) natO), ∃ n, logrel_val rs Tnat (Σ:=Σ) (S:=S) βv (LitV n)
          ∗ ⌜∃ m σ', prim_steps e σ (Val $ LitV n) σ' m⌝)%I).
  assert (NonExpansive Φ).
  { unfold Φ.
    intros l a1 a2 Ha. repeat f_equiv. done. }
  exists Φ. split; first assumption. split.
  { iIntros (βv). iDestruct 1 as (n'') "[H %]".
    iDestruct "H" as (n') "[#H %]". simplify_eq/=.
    iAssert (IT_of_V βv ≡ Ret n')%I as "#Hb".
    { iRewrite "H". iPureIntro. by rewrite IT_of_V_Ret. }
    iAssert (⌜βv = RetV n'⌝)%I with "[-]" as %Hfoo.
    { destruct βv as [r|f]; simpl.
      - iPoseProof (Ret_inj' with "Hb") as "%Hr".
        fold_leibniz. eauto.
      - iExFalso. iApply (IT_ret_fun_ne).
        iApply internal_eq_sym. iExact "Hb". }
    iPureIntro. rewrite Hfoo. unfold ϕ.
    eauto. }
  iIntros "[_ Hs]".
  iPoseProof (Hlog with "[//]") as "Hlog".
  iAssert (has_substate σ) with "[Hs]" as "Hs".
  { unfold has_substate, has_full_state.
    assert ((of_state rs (IT (sReifier_ops (gReifiers_sReifier rs)) natO) (σ, ())) ≡
            (of_idx rs (IT (sReifier_ops (gReifiers_sReifier rs)) natO) sR_idx (sR_state σ))) as -> ; last done.
    intros j. unfold sR_idx. simpl.
    unfold of_state, of_idx.
    destruct decide as [Heq|]; last first.
    { inv_fin j; first done.
      intros i. inversion i. }
    inv_fin j; last done.
    intros Heq.
    rewrite (eq_pi _ _ Heq eq_refl)//.
  }
  unshelve epose (idHOM := _ : (HOM rs)).
  { exists idfun. apply IT_hom_idfun. }
  iSpecialize ("Hlog" $! idHOM EmptyK with "[]").
  { iIntros (βv v); iModIntro. iIntros "Hv". iIntros (σ'') "HS".
    iApply wp_val.
    iModIntro.
    iExists (0, 0), v, σ''.
    iSplit; first iPureIntro.
    - apply prim_steps_zero.
    - by iFrame.
  }
  simpl.
  iSpecialize ("Hlog" $! σ with "Hs").
  iApply (wp_wand with"Hlog").
  iIntros ( βv). iIntros "H".
  iDestruct "H" as (m' v σ1' Hsts) "[Hi Hsts]".
  unfold Φ. iDestruct "Hi" as (l) "[Hβ %]". simplify_eq/=.
  iExists l. iModIntro. iSplit; eauto.
  iExists l. iSplit; eauto.
Qed.

Program Definition ı_scope : @interp_scope (gReifiers_ops rs) natO _ Empty_set := λne (x : ∅), match x with end.

Theorem adequacy (e : expr ∅) (k : nat) σ σ' n :
  typed □ e Tnat →
  ssteps (gReifiers_sReifier rs) (interp_expr rs e ı_scope) (σ,()) (Ret k : IT _ natO) σ' n →
  ∃ mm σ', prim_steps e σ (Val $ LitV k) σ' mm.
Proof.
  intros Hty Hst.
  pose (Σ:=#[invΣ;stateΣ rs natO]).
  eapply (logrel_nat_adequacy Σ (interp_expr rs e ı_scope)); last eassumption.
  intros ? ?.
  iPoseProof (fundamental rs) as "H".
  { apply Hty. }
  unfold logrel_valid.
  iIntros "_".
  unshelve iSpecialize ("H" $! ı_scope _ with "[]").
  { apply ı%bind. }
  { iIntros (x); destruct x. }
  rewrite ebind_id; first last.
  { intros ?; reflexivity. }
  iApply "H".
Qed.
