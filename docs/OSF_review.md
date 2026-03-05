# Constructive Review: Iconic Duration Effect in Sentence Interpretation

## Overall Assessment

This preregistration presents a well-designed follow-up study investigating the iconic duration effect in language comprehension. The research builds logically on an exploratory pilot study and demonstrates strong methodological rigor in addressing a specific research gap. The preregistration is generally thorough and provides sufficient detail for replication.

## Strengths

### 1. **Clear Research Motivation**
- The study has a well-defined research question stemming from pilot data
- The focus on identifying the "cut-off point" where the effect disappears is theoretically motivated and addresses a clear gap
- The binning strategy (0-10, 10-20, 20-60 seconds) is informed by empirical data from the pretest

### 2. **Rigorous Experimental Design**
- The 2×3 Latin square design is appropriate for the research questions
- Counterbalancing through Latin square lists controls for order effects
- Randomization procedures are clearly specified at both trial and participant levels

### 3. **Participant Recruitment**
- Comprehensive prescreening criteria on Prolific ensure a homogeneous linguistic sample
- Exclusion of participants from previous related studies prevents carryover effects
- Sample size of 60 (30 per list) seems reasonable, though justification could be stronger

### 4. **Statistical Analysis Plan**
- Use of linear mixed-effects models with appropriate random effects structure (participant and item) is state-of-the-art
- Log transformation of duration estimates is sensible given the likely positive skew
- Planned simple effects analyses with Holm-Bonferroni correction shows awareness of multiple comparisons issues
- The decision to test simple effects regardless of the omnibus interaction is justified and pre-specified

### 5. **Blinding**
- Appropriate blinding is implemented (participants unaware of conditions)

## Areas for Improvement

### 1. **Sample Size Justification**
**Issue:** The sample size rationale field states "No data" despite specifying 60 participants.

**Recommendation:** Provide a power analysis or justification for the sample size. Consider:
- Effect size estimates from the pilot study
- Power calculations for detecting the main effect and interaction
- Minimum effect size of interest
- If a formal power analysis wasn't conducted, at least provide a comparison to similar studies or acknowledge this as a limitation

### 2. **Random Effects Structure**
**Issue:** The specified model includes "random effects of participant and item" but doesn't specify the structure (random intercepts only, or random slopes as well).

**Recommendation:** 
- Specify the maximal random effects structure justified by the design (e.g., random slopes for sentence length by participant and by item)
- If computational issues arise, specify a principled reduction strategy (e.g., removing random slopes that account for <0.01% of variance)
- Consider citing recent literature on random effects specification (Barr et al., 2013; Matuschek et al., 2017)

### 3. **Missing Data Handling**
**Issue:** Multiple sections state "No data" including data exclusion, missing data, and exploratory analyses.

**Recommendations:**
- **Data Exclusion:** Specify criteria for participant-level exclusion (e.g., <80% completion rate, attention check failures, statistical outliers)
- **Missing Data:** Describe how you'll handle trials with invalid responses (e.g., extreme outliers, impossibly fast responses)
- **Exploratory Analyses:** Even if not confirmatory, mentioning potential exploratory analyses can be valuable (e.g., examining patterns in the continuous measure of geometric mean duration)

### 4. **Dependent Variable Operationalization**
**Issue:** The conversion of participant responses to seconds is mentioned, but potential issues aren't addressed.

**Recommendations:**
- Specify how you'll handle potential outliers (e.g., responses >1000× the expected duration)
- Consider whether you'll exclude or transform extreme values
- Specify whether you'll conduct any data quality checks (e.g., responses that are clearly errors like "1 second" for "reading a book")

### 5. **Event Duration as Continuous vs. Categorical**
**Issue:** The design specifies three discrete bins, but mentions that "actual geometric means can also be used directly as a continuous variable."

**Recommendations:**
- Pre-specify whether you'll use binned categories or continuous values as the primary analysis
- If you plan both, specify which is primary and which is exploratory
- For the continuous analysis, specify whether you'll include polynomial terms to capture non-linear effects

### 6. **Stimulus Materials**
**Issue:** No information is provided about the specific stimulus materials or how they were developed.

**Recommendations:**
- Briefly describe how short and long versions were created (attribute addition/removal)
- Specify any constraints on attribute selection (e.g., semantic relevance, frequency)
- Consider mentioning how many experimental items and fillers will be used
- Upload stimulus materials to OSF for transparency

### 7. **Transparency in H2 Testing**
**Issue:** While the planned approach (simple effects regardless of interaction) is good, the interpretation framework could be clearer.

**Recommendations:**
- Specify what pattern of results across the three bins would "corroborate" H2
- For example: "H2 would be supported if we observe a significant sentence length effect in the 0-10 sec condition, a reduced effect in the 10-20 sec condition, and no effect in the 20-60 sec condition"
- Consider whether you'll test the linear trend across duration bins

### 8. **Compensation Amount**
**Issue:** Participant compensation is specified as "X GBP for their participation estimated to take X minutes."

**Recommendation:** Fill in these values or note that they'll be determined based on platform guidelines and task duration in the pilot.

### 9. **Stopping Rule**
**Issue:** No stopping rule is specified.

**Recommendation:** Clarify whether:
- You'll collect exactly 60 participants or whether there's any flexibility
- You have a maximum sample size if data quality issues require exclusions
- You'll conduct any interim analyses (if so, specify alpha adjustment)

### 10. **Model Diagnostics**
**Issue:** No mention of how model assumptions will be checked.

**Recommendations:**
- Specify that you'll check residual plots for homoscedasticity and normality
- Mention what you'll do if assumptions are violated (e.g., alternative transformations, robust standard errors)
- Consider whether you'll check for influential observations (e.g., Cook's distance)

## Minor Issues

### 11. **Encoding Issues in PDF**
- Several special characters appear corrupted (e.g., "e´¼Çect" instead of "effect", "´¼ü" instead of special characters)
- This is likely a PDF generation issue and should be corrected for readability

### 12. **Study Type Classification**
- The study is correctly classified as an experiment, which is appropriate

## Recommendations for Enhanced Transparency

1. **Pre-specify Effect Size Interpretation:**
   - Consider pre-specifying what you consider small, medium, and large effect sizes for your context
   - This aids interpretation beyond p-values

2. **Analysis Code:**
   - Consider pre-registering analysis scripts or pseudo-code
   - This could be uploaded to OSF to maximize reproducibility

3. **Pilot Data Availability:**
   - Consider making pilot study data available (if not already)
   - This would allow readers to evaluate the empirical basis for the current design

4. **Time Unit Selection Analysis:**
   - Consider analyzing whether time unit choice (seconds vs. minutes) varies systematically by condition
   - This could be an interesting exploratory analysis

## **ADDENDUM: Bayesian Sequential Design with ROPE** 🔄

### Overview

If you're planning to use a **Bayesian sequential design with ROPE (Region of Practical Equivalence)**, this is **excellent** for your research question! This approach allows you to:
1. ✅ Provide **evidence for absence** of effects (not just "non-significant")
2. ✅ Use **sequential data collection** without frequentist multiple-testing penalties
3. ✅ Make **three-way decisions**: effect present, effect absent (in ROPE), or undecided
4. ✅ **Continue collecting data** only when needed (efficient resource use)

This is particularly valuable for H2, where you need to demonstrate the effect **disappears** in longer duration events—you need evidence of absence, not just absence of evidence.

---

### **Critical Elements to Add to Preregistration**

#### **1. ROPE Definition** ⚠️ ESSENTIAL

You **must** pre-specify what constitutes a "practically zero" effect on the log scale:

**Recommended:**
```
ROPE = [-0.10, +0.10] on log scale
Rationale: This corresponds to ≈±10% change in perceived duration.
Effects smaller than this are unlikely to be psychologically meaningful
given the inherent variability in duration estimation tasks.
```

**Alternative approaches:**
- Use pilot effect size: ROPE = ±(pilot_effect / 4)
- Use smallest effect size of interest (SESOI) from theory
- Sensitivity analysis: test ROPE widths of 0.05, 0.10, 0.15

#### **2. Decision Rules** ⚠️ ESSENTIAL

For each duration bin (0-10s, 10-20s, 20-60s), specify:

**Effect is PRESENT when:**
- 95% Highest Density Interval (HDI) for sentence length effect is entirely **above** ROPE upper bound (+0.10)
- Example: HDI = [0.15, 0.38] → Effect present

**Effect is ABSENT when:**
- 95% HDI is entirely **within** ROPE boundaries
- Example: HDI = [-0.04, +0.08] → Effect absent (in ROPE)

**Effect is UNDECIDED when:**
- 95% HDI **overlaps** ROPE boundaries (partially inside, partially outside)
- Example: HDI = [-0.05, +0.18] → Undecided, collect more data

**H2 Conclusion:**
- Requires: Effect PRESENT in 0-10s bin **AND** Effect ABSENT in 20-60s bin
- The 10-20s bin can be either (transition zone)

#### **3. Sequential Sampling Plan** ⚠️ ESSENTIAL

```
Stage 1: N₁ = 60 participants (30 per list) - initial sample
  → Fit Bayesian model, check ROPE decisions
  
Stage 2: If any critical bin undecided, collect N₂ = 90 total (add 30 more)
  → Refit model with full data, check ROPE decisions
  
Stage 3: If still undecided, collect N₃ = 120 total (add 30 more)
  → Refit model, make final decisions
  
Maximum: N_max = 120 participants
  → If still undecided, report as inconclusive
```

**When to stop early:**
- If ROPE decisions are clear for **both** 0-10s and 20-60s bins at any stage
- Maximizes efficiency while ensuring adequate evidence

**What counts as "undecided":**
- Either the 0-10s bin OR 20-60s bin has HDI overlapping ROPE boundaries
- Don't need decision on 10-20s bin to stop (it's the transition zone)

#### **4. Prior Specification** ⚠️ ESSENTIAL

Specify priors for all model parameters:

**Fixed effects (recommended weakly informative priors):**
```r
Intercept: Normal(log(15), 1.5)  # Median event ~15 seconds
Sentence Length: Normal(0, 0.5)  # Could be positive or negative
Event Duration: Normal(0, 0.5)
Interaction: Normal(0, 0.5)
```

**Random effects:**
```r
SD(participant|intercept): Exponential(1)  # Half-Cauchy(0, 1) also common
SD(item|intercept): Exponential(1)
SD(participant|sentence_length): Exponential(1)  # If included
Correlation: LKJ(2)  # Weakly regularizing
```

**If using pilot data for informative priors:**
- Report pilot sample size and effect estimates
- Widen pilot SDs (multiply by 2) to avoid overconfidence
- Example: `Sentence_Length ~ Normal(0.18, 0.24)` if pilot showed d=0.18, SD=0.12

**Sensitivity analysis:**
- Test priors at 0.5× and 2× width to ensure conclusions are robust

#### **5. Bayesian Model Specification**

```r
brm(
  log_duration ~ sentence_length * event_duration_bin + 
                 (1 + sentence_length | participant) + 
                 (1 + sentence_length | item),
  data = data,
  prior = c(
    prior(normal(0, 0.5), class = b),
    prior(exponential(1), class = sd),
    prior(lkj(2), class = cor)
  ),
  chains = 4,
  iter = 4000,  # 2000 warmup + 2000 sampling
  cores = 4,
  seed = 2026
)
```

**Convergence criteria:**
- R̂ < 1.01 for all parameters
- Effective Sample Size (ESS) > 400 for all parameters
- Visual inspection of trace plots (no divergences)
- If not converged: increase iterations to 8000, or simplify random effects structure

#### **6. Handling Multiple Bins**

With ROPE approach, you're making 3 separate inferences. Options:

**Option A: Use 95% HDI, no adjustment**
- ROPE framework inherently conservative (requires strong evidence)
- Three tests are conceptually independent
- Report all three with full posteriors

**Option B: Use 98.3% HDI (Bonferroni-equivalent)**
- More conservative, parallel to frequentist correction
- Reduces chance of false ROPE decisions

**Recommendation:** Option A (95% HDI) with clear reporting that you're testing 3 bins. The ROPE requirement for evidence already provides protection against spurious findings.

#### **7. Reporting Plan**

Pre-specify that you'll report for each duration bin:

- **Posterior mean and 95% HDI** for sentence length effect (log scale)
- **ROPE decision**: Present / Absent / Undecided
- **Probability in ROPE**: P(effect ∈ ROPE | data)
- **Probability of direction**: P(effect > 0 | data)
- **Visual**: Posterior distribution with ROPE region shaded
- **Model diagnostics**: R̂, ESS, posterior predictive checks

Optional but valuable:
- Bayes factors (BF₁₀) for effect vs. null
- Effect sizes in original scale (% duration change)
- Posterior predictive distributions

---

### **Advantages Over Frequentist Approach**

| Aspect | Frequentist | Bayesian ROPE |
|--------|-------------|---------------|
| Evidence for null | ❌ Cannot provide | ✅ Can prove absence |
| Sequential sampling | ❌ Inflates Type I error | ✅ Valid & efficient |
| Stopping rule | ❌ Must be rigid | ✅ Can adapt to data |
| Interpretation | p < .05 or not | Present/Absent/Undecided |
| Sample flexibility | Fixed N=60 | Adaptive 60-120 |
| Research question fit | ⚠️ Moderate | ✅ Excellent |

**For finding where an effect disappears, Bayesian ROPE is the superior choice.**

---

### **Sample Size Considerations**

**Is N=60 adequate as starting point?**

**Yes, likely sufficient because:**
- Within-subjects design provides high power per participant
- Multiple items per condition increase total observations
- Bayesian framework allows adding data if needed
- 60 is above typical minimums (40-50) for psycholinguistics

**Sequential design benefits:**
- If effects are clear: Stop at N=60, save resources ✓
- If effects are moderate: Need N=90 (still reasonable)
- If effects are small: Go to N=120 (maximum commitment)
- Expected N ≈ 70-80 if 70% decide at first stage

**Strongly recommended before data collection:**

Run **prior predictive simulations** to estimate decision rates:

```r
# Simulate 1000 datasets under H2 scenario:
#   - Strong effect (d≈0.3) in 0-10s bin
#   - Null effect (d≈0) in 20-60s bin
# For each simulated dataset:
#   - Fit Bayesian model
#   - Check if ROPE decision clear at N=60, N=90, N=120
# Report: % clear at each stage, % undecided at N_max
```

This tells you if your sampling plan is realistic.

---

### **What to Add to Each Preregistration Section**

**Study Design:**
```
"We will use Bayesian sequential sampling with ROPE to allow efficient
data collection while maintaining the ability to provide evidence for
the absence of effects in longer-duration events."
```

**Sample Size:**
```
"Initial sample: N₁=60 participants. Sequential decision points at
N₂=90 and N₃=120. Data collection continues only if ROPE decision is
undecided. Maximum sample: N_max=120."

Rationale: Prior predictive simulations (see OSF materials) indicate
60 participants provides 95% HDI precision of ±0.15 log-units, sufficient
for ROPE=±0.10 decisions when effects are moderate-to-large. Sequential
design allows adaptation if effects are smaller than anticipated."
```

**Statistical Models:**
```
"Bayesian hierarchical model fit using brms (Bürkner, 2017):

log(duration) ~ sentence_length * event_duration_bin +
                (1 + sentence_length | participant) +
                (1 + sentence_length | item)

Priors: [specify as above]

ROPE: [-0.10, +0.10] on log scale (±10% duration change)

Decision rules:
- Effect PRESENT: 95% HDI entirely above +0.10
- Effect ABSENT: 95% HDI entirely within [-0.10, +0.10]  
- Effect UNDECIDED: 95% HDI overlaps ROPE boundaries

H1 supported: Effect PRESENT in at least one duration bin
H2 supported: Effect PRESENT in 0-10s AND ABSENT in 20-60s"
```

**Stopping Rule:**
```
"Sequential analysis after N=60, 90, and 120 participants.
Stop when ROPE decisions are clear for both 0-10s and 20-60s bins.
If undecided at N=120, report as inconclusive."
```

**Inference Criteria:**
```
"Bayesian ROPE procedure with 95% HDI. No adjustment for multiple
comparisons as ROPE decisions are made independently per bin with
full posterior uncertainty reported."
```

---

### **Final Recommendations**

1. ✅ **Bayesian ROPE is excellent for this study** - much better than frequentist for your research question
2. ⚠️ **Preregistration needs substantial additions** - ROPE, priors, decision rules, sequential plan
3. 📊 **Run prior predictive simulations** - confirm 60/90/120 sampling plan is realistic
4. 📝 **Upload analysis scripts** - include commented R/brms code on OSF
5. 🔄 **Sensitivity analyses** - test different ROPE widths and prior specifications

**Timeline estimate:**
- Prior predictive simulations: 2-3 days
- Finalize ROPE and priors: 1 day  
- Update preregistration: 1 day
- **Total: ~1 week of additional preparation**

This investment will result in a **gold-standard Bayesian preregistration** that provides clear, interpretable evidence about where the iconic duration effect disappears.

---

## Conclusion

This is a strong preregistration that demonstrates careful consideration of methodology and analysis. **The proposed shift to Bayesian sequential analysis with ROPE is highly appropriate** for the research questions, particularly for demonstrating where the effect disappears. 

The main areas requiring specification:
- ⚠️ ROPE definition and justification
- ⚠️ Sequential sampling plan with decision points  
- ⚠️ Prior specifications for all model parameters
- ⚠️ ROPE decision rules (Present/Absent/Undecided)
- Recommended: Prior predictive simulations for sample size validation

With these additions, this would be an **exemplary Bayesian preregistration** that meets the highest standards of open science and provides clear, interpretable evidence about the iconic duration effect.

---

**Review Date:** February 4, 2026  
**Reviewer Recommendation:** Major revisions to add Bayesian sequential specifications (ROPE, priors, stopping rules)  
**Methodological Approach:** Strongly endorsed - Bayesian ROPE is superior to frequentist testing for this research question
