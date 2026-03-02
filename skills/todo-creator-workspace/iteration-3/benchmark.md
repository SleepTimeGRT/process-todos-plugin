# Skill Benchmark: todo-creator — iteration-3

**Model**: claude-sonnet
**Date**: 2026-03-03

## Summary

| Metric | with_skill | without_skill | Delta |
|--------|:----------:|:-------------:|:-----:|
| Overall Pass Rate | 84% | 27% | **+0.575** |
| Baseline Pass Rate | 95% | 33% | +0.617 |
| **Discriminating Pass Rate** | **75%** | **20%** | **+0.55** |
| Time (avg) | 67.1s | 49s | +18.1s |

## Per-Case Breakdown

### simple-password-reset

| Assertion | with_skill | without_skill | Discriminates? |
|-----------|:----------:|:-------------:|:--------------:|
| appropriate-file-count | **Fail** | **Fail** | No |
| checklist-has-file-paths | Pass | **Fail** | **Yes** |
| correct-markdown-format | Pass | **Fail** | **Yes** |
| checklist-items-are-concrete | Pass | **Fail** | **Yes** |
| **includes-test-specifications** | Pass | **Fail** | **Yes** |
| **documents-design-assumptions** | Pass | **Fail** | **Yes** |

### medium-profile-page

| Assertion | with_skill | without_skill | Discriminates? |
|-----------|:----------:|:-------------:|:--------------:|
| concern-based-split | Pass | Pass | No |
| dependency-ordering | Pass | Pass | No |
| context-paragraph-present | Pass | Pass | No |
| checklist-items-are-concrete | Pass | Pass | No |
| **separates-data-layer** | **Fail** | Pass | **Reverse** |
| **includes-test-specifications** | Pass | Pass | No |
| **documents-design-assumptions** | Pass | Pass | No |
| **specifies-component-props** | Pass | Pass | No |

### large-chat-system

| Assertion | with_skill | without_skill | Discriminates? |
|-----------|:----------:|:-------------:|:--------------:|
| tech-decision-documented | Pass | **Fail** | **Yes** |
| concern-based-decomposition | Pass | **Fail** | **Yes** |
| allows-large-cohesive-todos | Pass | **Fail** | **Yes** |
| checklist-items-are-concrete | Pass | **Fail** | **Yes** |
| **separates-state-from-ui** | Pass | **Fail** | **Yes** |
| **includes-test-specifications** | Pass | **Fail** | **Yes** |
| **documents-design-assumptions** | Pass | **Fail** | **Yes** |
| **specifies-type-definitions** | Pass | **Fail** | **Yes** |

### trivial-typo-fix

| Assertion | with_skill | without_skill | Discriminates? |
|-----------|:----------:|:-------------:|:--------------:|
| single-file-output | Pass | **Fail** | **Yes** |
| correct-markdown-format | Pass | **Fail** | **Yes** |
| minimal-checklist-items | Pass | **Fail** | **Yes** |
| **no-multi-file-split** | Pass | **Fail** | **Yes** |
| **no-brainstorming-artifacts** | Pass | **Fail** | **Yes** |
| **scope-proportional-to-request** | Pass | **Fail** | **Yes** |

### meta-project-plugin-feature

| Assertion | with_skill | without_skill | Discriminates? |
|-----------|:----------:|:-------------:|:--------------:|
| appropriate-file-count | Pass | **Fail** | **Yes** |
| correct-markdown-format | Pass | Pass | No |
| checklist-items-are-concrete | Pass | Pass | No |
| **references-project-artifacts** | **Fail** | **Fail** | No |
| **adapts-to-non-code-project** | **Fail** | **Fail** | No |
| **includes-validation-approach** | **Fail** | **Fail** | No |
