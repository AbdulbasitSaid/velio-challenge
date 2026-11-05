# OWNERSHIP: invites open, but guests don't claim

**30 days after launch:**

- Oversell is zero and the booking SLOs are green.
- 34% of bookers invite, against a 30% target.
- **11% of opened invites end in a claim, against 25%.** The trigger has fired.
- Most opens are on mobile. Vouch invites convert better than public links.

Tunde is doing his part. Somewhere between Zainab's tap and her claim, we lose her.

## 1. Diagnose

**First, check the number itself.** The 25% target applies to the vouch rail (PLANS 1a, D1). If public opens dominate, a blended 11% can hide a healthy vouch rate. I'd read these splits from `v_open_to_claim_by_rail`, `invite_opens` and the claim events:

1. **Per rail:** what vouch open-to-claim is on its own, and what share of opens are public.
2. **What the page showed at open:** claimable, sold out, started or already claimed. A guest who arrives to a full activity isn't friction; that's sell-out loss.
3. **Per platform:** app or mobile web, and iOS or Android. iOS has no Universal Links, so iOS guests land on the web page or must type a code.
4. **By whether the guest was new to Velio or recognised on the device,** and by the time from invite to open.
5. **Claim attempts by outcome:** `sold_out`, `rate_limited`, a paused link, server errors.

**Hypotheses, most likely first:**

| # | Hypothesis | Signal that confirms it |
| --- | --- | --- |
| H1 | **Sell-out loss.** Invites don't hold spots, so popular activities fill before friends tap. | A large share of opens rendered the sold-out page |
| H2 | **Mix.** Public links collect most opens with low intent. Vouch is near target; the blend isn't. | Vouch ≥ 20% while public opens are over 60% of all opens |
| H3 | **First-time mobile friction.** The claim form (name plus contact), a slow first paint on 3G, or an iOS guest dropped on the web. | New-user and iOS conversion well below returning and Android; poor invite-page FCP |
| H4 | **Inflated opens.** Something runs the beacon without a human. In S6 testing, headless Chrome counted as an open. | Opens with no further interaction, clustered by user agent or ASN |

## 2. Improve (ranked by expected impact ÷ effort)

| Rank | Change | Type | Effort | Expected impact |
| --- | --- | --- | --- | --- |
| 1 | Add `claim_started`, `claim_submitted` and `claim_failed{reason}`. Record the page state on `invite_opened`. Filter headless agents. | Tracking | S (1–2 days) | Turns 11% into a funnel we can act on. Nothing below is credible without it. |
| 2 | **Vouch: prefill the name the inviter typed** ("Claiming as Zainab — add your phone"). Recognised devices claim in one tap. | Product | S | Removes most of the form for H3 |
| 3 | **Sold out → "Join the waitlist" or "Ask Tunde for another date"** on the invite page, with the waitlist planned for P1 | Product | M | Rescues H1's loss and gives Kofi a next step |
| 4 | **Vouch spot hold** (1 spot, 2 h, at most 2 per booker; D2), only if H1 exceeds 10% of vouch opens | Product + tech | M | Keeps Tunde's promise to Zainab |
| 5 | Invite-page speed on 3G, and Universal Links on iOS (needs an Apple Developer account) | Tech | M | Recovers H3 on iOS and slow networks |
| 6 | Public link previews: more social proof (who's going, the community) | Product | S | Small gain for H2; a weak rail stays weak |

## 3. Prove it

- **Measure first.** Ship rank 1 and measure for one week before changing the product; that week is the baseline.
- **Test against a control.** Ship ranks 2 and 3 behind a sub-flag inside the exposed arm, split 50/50 by the **inviter's** user hash. This keeps a Plan's invites in one variant and limits contamination.
  - **Primary metric:** vouch open-to-claim on opens where the activity was claimable.
  - **Guardrails:** invited no-show and removal rates vs. organic, Plans that happen, and the booking SLOs.
  - **Sample size:** detecting 11% → 14% needs about 1,900 claimable vouch opens per variant (80% power, α 0.05).
- **Keep the feature holdout.** The 10% invite holdout stays in place throughout, so we still measure whether invites cause **more new users per booker and more Plans that happen**. That is the outcome Velio cares about, not the conversion ratio.

## 4. Decide

**Recommendation: keep the feature, iterate on the claim step, and change the goal definition, not the product's purpose.**

- **The goal should change.** A blended 25% was the wrong trigger (D1). The target should be **vouch open-to-claim on claimable opens**; public links get their own baseline.
- **Then a two-cycle deadline.** If vouch conversion stays under 20% after two iterations (about six weeks):
  - **If the holdout shows a lift** in new users per booker and Plans that happen, keep the feature as it is. People are still being brought in and showing up; we just set the target too high.
  - **If there's no lift,** remove the public rail first (low trust, low intent, spam risk) and keep the vouch.
  - **Only if vouches show no lift either,** remove the feature. A third of bookers inviting is a signal that won't come easily from anything else.

What would make me cut it early: invited guests no-showing at more than 1.5× the rate of organic guests. That would mean we're filling Amara's activities with people who don't come, which is worse than not filling them.
