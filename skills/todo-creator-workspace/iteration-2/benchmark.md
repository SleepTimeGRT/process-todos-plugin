# Skill Benchmark: todo-creator — Iteration 2

**Model**: claude-sonnet-4-6
**Date**: 2026-03-03
**Changes**: Added discriminating assertions + improved SKILL.md guidance

## Summary

| Metric | with_skill | without_skill | Delta |
|--------|:----------:|:-------------:|:-----:|
| Overall Pass Rate | 100% | 81.9% | **+18.1%** |
| Baseline Pass Rate | 100% | 100% | +0% |
| **Discriminating Pass Rate** | **100%** | **58.3%** | **+41.7%** |
| Time (avg) | 106.8s | 64.6s | +42.2s |
| Tokens (avg) | 20,696 | 15,598 | +5,098 |

## Per-Case Breakdown

### Simple: Password Reset

| Assertion | with_skill | without_skill | Discriminates? |
|-----------|:----------:|:-------------:|:--------------:|
| appropriate-file-count | Pass | Pass | No |
| checklist-has-file-paths | Pass | Pass | No |
| correct-markdown-format | Pass | Pass | No |
| checklist-items-are-concrete | Pass | Pass | No |
| **includes-test-specifications** | **Pass** | **Fail** | **Yes** |
| documents-design-assumptions | Pass | Pass (borderline) | Weak |

### Medium: Profile Page

| Assertion | with_skill | without_skill | Discriminates? |
|-----------|:----------:|:-------------:|:--------------:|
| concern-based-split | Pass | Pass | No |
| dependency-ordering | Pass | Pass | No |
| context-paragraph-present | Pass | Pass | No |
| checklist-items-are-concrete | Pass | Pass | No |
| separates-data-layer | Pass | Pass | No |
| **includes-test-specifications** | **Pass** | **Fail** | **Yes** |
| **documents-design-assumptions** | **Pass** | **Fail** | **Yes** |
| **specifies-component-props** | **Pass** | **Fail** | **Yes** |

### Large: Chat System

| Assertion | with_skill | without_skill | Discriminates? |
|-----------|:----------:|:-------------:|:--------------:|
| tech-decision-documented | Pass | Pass | No |
| concern-based-decomposition | Pass | Pass | No |
| allows-large-cohesive-todos | Pass | Pass | No |
| checklist-items-are-concrete | Pass | Pass | No |
| separates-state-from-ui | Pass | Pass | No |
| includes-test-specifications | Pass | Pass (borderline) | Weak |
| documents-design-assumptions | Pass | Pass | No |
| specifies-type-definitions | Pass | Pass | No |

## Key Findings

1. **Discriminating assertions work.** with-skill: 10/10 discriminating pass vs without-skill: 7/10. The gap is concentrated in simple/medium features.

2. **`includes-test-specifications` is the strongest discriminator.** without-skill consistently omits test file paths and scenarios for simple/medium features.

3. **The skill raises the floor, not the ceiling.** For complex features (large), Sonnet already produces high-quality output without the skill. The skill's value is ensuring this quality level for all feature sizes.

4. **`separates-data-layer` is no longer discriminating.** In iteration 1, without-skill bundled schema with API. In iteration 2, without-skill also separates them. This may be natural variance or Sonnet improvement.

5. **Cost-quality trade-off.** The skill adds ~42s and ~5k tokens, but guarantees consistent test specs, documented assumptions, and typed component interfaces.

## Comparison with Iteration 1

| Metric | Iter 1 | Iter 2 |
|--------|:------:|:------:|
| with_skill overall | 100% (12/12) | 100% (22/22) |
| without_skill overall | 100% (12/12) | 81.9% (18/22) |
| Discriminating assertions | 0 (none existed) | 10 total, 3 discriminate |
| Can detect skill value? | **No** | **Yes** |
