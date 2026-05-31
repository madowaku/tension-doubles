# v0.6 Rally Feel Quality Pass

Date: 2026-05-31

## Goal

Raise mobile play quality after the second landscape video by making rallies easier to sustain and making the ball/HARE moment easier to read.

## Changes

- Added early-rally assist for the first two returns of each rally.
- The assist trims forward speed and keeps a minimum lift floor for non-HARE returns.
- HARE now uses a lower lift (`ReturnLiftHare = 0.24`) so it reads more like a fast smash than a long lob.
- Added `TD_BallReadabilityHalo` as a visual-only ball halo.
- Increased baseline ball glow/trail readability without changing the hitbox.

## Recheck Focus

- First two returns should be less likely to instantly DROP or fly OUT.
- HARE should still feel fast, but land more often.
- Ball should be easier to track on phone video without becoming physically larger.
